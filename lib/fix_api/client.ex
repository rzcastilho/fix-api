defmodule FixApi.Client do
  use GenServer

  require Logger

  alias FixApi.Descriptor

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
      msg_seq_num: 1,
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

  def new_order_single(cl_ord_id, order_type, side, qty, price, symbol, time_in_force) do
    GenServer.cast(
      __MODULE__,
      {:new_order_single, cl_ord_id, order_type, side, qty, price, symbol, time_in_force}
    )
  end

  def send(message) do
    GenServer.cast(__MODULE__, {:send, message})
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
    {:reply, :ok, Map.delete(state, :socket)}
  end

  def handle_cast(
        {:new_order_single, cl_ord_id, order_type, side, qty, price, symbol, time_in_force},
        %{socket: socket, msg_seq_num: msg_seq_num, sender_comp_id: sender_comp_id} = state
      ) do
    message =
      Descriptor.new(:new_order_single)
      |> Descriptor.set(
        msg_seq_num: msg_seq_num + 1,
        sender_comp_id: sender_comp_id,
        cl_ord_id: cl_ord_id,
        ord_type: order_type,
        side: side,
        order_qty: qty,
        price: price,
        symbol: symbol,
        time_in_force: time_in_force
      )
      |> IO.inspect()
      |> Descriptor.calculate()
      |> Descriptor.encode()

    send_message(socket, message)
    {:noreply, %{state | msg_seq_num: msg_seq_num + 1}}
  end

  def handle_cast({:send, message}, %{socket: socket} = state) do
    send_message(socket, message)
    {:noreply, state}
  end

  def handle_info({:ssl_closed, _info}, state) do
    Logger.info("Connection closed by server.")
    {:noreply, Map.delete(state, :socket)}
  end

  def handle_info({:ssl, _socket, message}, state) do
    Logger.info("Message received: #{String.replace(message, <<1>>, "|")}")

    decoded_message =
      message
      |> Descriptor.decode()
      |> Descriptor.validate()
      |> IO.inspect()

    Logger.debug("Message received: #{decoded_message}")

    if decoded_message.type == "1" do
      send(self(), {:heartbeat, Keyword.get(decoded_message.data.fields, :test_req_id)})
    end

    {:noreply,
     %{
       state
       | sender_comp_id: Keyword.get(decoded_message.data.fields, :target_comp_id)
     }}
  end

  def handle_info(
        {:heartbeat, test_req_id},
        %{socket: socket, msg_seq_num: msg_seq_num, sender_comp_id: sender_comp_id} = state
      ) do
    message =
      Descriptor.new(:heartbeat)
      |> Descriptor.set(
        test_req_id: test_req_id,
        msg_seq_num: msg_seq_num + 1,
        sender_comp_id: sender_comp_id
      )
      |> Descriptor.calculate()
      |> Descriptor.encode()

    send_message(socket, message)
    {:noreply, %{state | msg_seq_num: msg_seq_num + 1}}
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
