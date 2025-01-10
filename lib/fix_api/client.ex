defmodule FixApi.Client do
  use GenServer

  require Logger

  alias FixApi.Descriptor
  alias FixApi.Messages.Heartbeat
  alias FixApi.Schemas.Message

  def start_link() do
    opts = %{
      ssl_options: [
        :binary,
        # active: false,
        verify: :verify_peer,
        cacertfile: :certifi.cacertfile(),
        # log_level: :debug,
        server_name_indication: String.to_charlist(Application.get_env(:fix_api, :sni))
      ],
      hostname: String.to_charlist(Application.get_env(:fix_api, :hostname)),
      port: Application.get_env(:fix_api, :port),
      msg_seq_num: nil,
      sender_comp_id: nil
    }

    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def connect() do
    GenServer.call(__MODULE__, :connect)
  end

  def disconnect() do
    GenServer.call(__MODULE__, :disconnect)
  end

  def send(message) do
    send(__MODULE__, {:send, message})
  end

  def init(opts) do
    {:ok, opts}
  end

  def handle_call(:connect, _from, %{ssl_options: opts, hostname: host, port: port} = state) do
    case :ssl.connect(host, port, opts) do
      {:ok, socket} ->
        Logger.info("Connected to Binance FIX API over TLS.")
        {:reply, :ok, Map.put(state, :socket, socket)}

      {:error, reason} ->
        Logger.error("Failed to connect: #{inspect(reason)}")
        {:reply, :error, state}
    end
  end

  def handle_call(:disconnect, _from, %{socket: socket} = state) do
    :ssl.close(socket)
    Logger.info("Connection closed.")

    {
      :reply,
      :ok,
      state
      |> Map.delete(:socket)
      |> Map.put(:msg_seq_num, nil)
      |> Map.put(:sender_comp_id, nil)
    }
  end

  def handle_info(
        {:send, message},
        %{socket: socket, msg_seq_num: nil, sender_comp_id: nil} = state
      ) do
    encoded_message =
      message
      |> Descriptor.calculate()
      |> Descriptor.encode()

    send_message(socket, encoded_message)
    {:noreply, %{state | msg_seq_num: 1, sender_comp_id: message.data.fields[:sender_comp_id]}}
  end

  def handle_info(
        {:send, message},
        %{socket: socket, msg_seq_num: msg_seq_num, sender_comp_id: sender_comp_id} = state
      ) do
    encoded_message =
      message
      |> Descriptor.set(
        msg_seq_num: msg_seq_num + 1,
        sender_comp_id: sender_comp_id
      )
      |> Descriptor.calculate()
      |> Descriptor.encode()

    send_message(socket, encoded_message)
    {:noreply, %{state | msg_seq_num: msg_seq_num + 1}}
  end

  def handle_info({:ssl_closed, _info}, state) do
    Logger.info("Connection closed by server.")

    {
      :noreply,
      state
      |> Map.delete(:socket)
      |> Map.put(:msg_seq_num, nil)
      |> Map.put(:sender_comp_id, nil)
    }
  end

  def handle_info({:ssl, _socket, message}, state) do
    message
    |> String.split("8=FIX.4.4", trim: true)
    |> Enum.map(&Kernel.<>("8=FIX.4.4", &1))
    |> Enum.map(fn
      message_split ->
        Logger.info("Message received: #{String.replace(message_split, <<1>>, "|")}")
        message_split
    end)
    |> Enum.map(&Descriptor.decode/1)
    |> Enum.map(&Descriptor.validate/1)
    |> Enum.each(fn
      %Message{type: "1"} = decoded_message ->
        Logger.debug("Message received: #{decoded_message}")
        heartbeat = Heartbeat.request(decoded_message.data.fields[:test_req_id])
        send(self(), {:send, heartbeat})

      decoded_message ->
        Logger.debug("Message received: #{decoded_message}")
    end)

    {:noreply, state}
  end

  def send_message(socket, message) do
    case :ssl.send(socket, message) do
      :ok ->
        Logger.info("Message sent: #{String.replace(message, <<1>>, "|")}")

      {:error, reason} ->
        Logger.error("Failed to send message: #{inspect(reason)}")
    end
  end
end
