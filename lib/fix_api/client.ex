defmodule FixApi.Client do
  use GenServer
  @behaviour FixApi.FixApiBehaviour

  require Logger

  defmodule State do
    defstruct [
      :hostname,
      :msg_seq_num,
      :name,
      :port,
      :pubsub,
      :sender_comp_id,
      :socket,
      :ssl_options
    ]
  end

  alias FixApi.Descriptor
  alias FixApi.Helper
  alias FixApi.Messages.Heartbeat
  alias FixApi.Schemas.Message

  @default_name "fix-client"

  @impl true
  def start_link(opts) do
    case Keyword.get(opts, :name) do
      nil -> GenServer.start_link(__MODULE__, opts)
      name -> GenServer.start_link(__MODULE__, opts, name: name)
    end
  end

  @impl true
  def connect(pid) do
    GenServer.call(pid, :connect)
  end

  @impl true
  def disconnect(pid) do
    GenServer.call(pid, :disconnect)
  end

  @impl true
  def get_sender_comp_id(pid) do
    GenServer.call(pid, :get_sender_comp_id)
  end

  @impl true
  def send_message(pid, message) do
    send(pid, {:send, message})
  end

  @impl true
  def init(opts) do
    name = Keyword.get(opts, :name) || @default_name
    host = Keyword.get(opts, :host)
    port = Keyword.get(opts, :port)
    sni = Keyword.get(opts, :sni)
    pubsub = Keyword.get(opts, :pubsub)

    ssl_options = [
      :binary,
      verify: :verify_peer,
      cacertfile: :certifi.cacertfile(),
      server_name_indication: sni
    ]

    state = %State{
      name: name,
      hostname: host,
      port: port,
      ssl_options: ssl_options,
      msg_seq_num: 0,
      sender_comp_id: Helper.generate_comp_id(),
      pubsub: pubsub
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:connect, _from, %State{ssl_options: opts, hostname: host, port: port} = state) do
    case :ssl.connect(host, port, opts) do
      {:ok, socket} ->
        Logger.info("Connected to Binance FIX API over TLS.")
        {:reply, :ok, %State{state | socket: socket}}

      {:error, reason} ->
        Logger.error("Failed to connect: #{inspect(reason)}")
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call(:disconnect, _from, %State{socket: socket} = state) do
    :ssl.close(socket)
    Logger.info("Connection closed.")

    {
      :reply,
      :ok,
      %State{state | socket: nil, msg_seq_num: 0, sender_comp_id: Helper.generate_comp_id()}
    }
  end

  @impl true
  def handle_call(:get_sender_comp_id, _from, %State{sender_comp_id: sender_comp_id} = state) do
    {:reply, sender_comp_id, state}
  end

  @impl true
  def handle_info(
        {:send, message},
        %State{socket: socket, msg_seq_num: msg_seq_num, sender_comp_id: sender_comp_id} = state
      ) do
    encoded_message =
      message
      |> Descriptor.set(
        msg_seq_num: msg_seq_num + 1,
        sender_comp_id: sender_comp_id
      )
      |> Descriptor.calculate()
      |> Descriptor.encode()

    dispatch(socket, encoded_message)
    {:noreply, %State{state | msg_seq_num: msg_seq_num + 1}}
  end

  @impl true
  def handle_info({:ssl_closed, _info}, %State{} = state) do
    Logger.info("Connection closed by server.")

    {
      :noreply,
      %State{state | socket: nil, msg_seq_num: nil, sender_comp_id: nil}
    }
  end

  @impl true
  def handle_info({:ssl, _socket, message}, %State{} = state) do
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
    |> Enum.map(&maybe_reply/1)
    |> Enum.map(&maybe_publish(&1, state))

    {:noreply, state}
  end

  defp dispatch(socket, message) do
    case :ssl.send(socket, message) do
      :ok ->
        Logger.info("Message sent: #{String.replace(message, <<1>>, "|")}")

      {:error, reason} ->
        Logger.error("Failed to send message: #{inspect(reason)}")
    end
  end

  defp maybe_reply(%Message{type: "1"} = message) do
    heartbeat = Heartbeat.request(message.data.fields[:test_req_id])
    send(self(), {:send, heartbeat})
    message
  end

  defp maybe_reply(message) do
    message
  end

  defp maybe_publish(message, %State{pubsub: nil}) do
    message
  end

  defp maybe_publish(%Message{name: :execution_report = name, data: data} = message, %State{
         name: client_name,
         pubsub: pubsub
       }) do
    cl_ord_id = Keyword.get(data.fields, :cl_ord_id)
    Phoenix.PubSub.broadcast(pubsub, "#{client_name}:message:#{name}", {name, cl_ord_id, data})
    message
  end

  defp maybe_publish(%Message{} = message, %State{}) do
    message
  end
end
