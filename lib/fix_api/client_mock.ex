defmodule FixApi.ClientMock do
  use GenServer
  @behaviour FixApi.FixApiBehaviour

  require Logger

  defmodule State do
    defstruct [
      :msg_seq_num,
      :name,
      :pubsub,
      :sender_comp_id
    ]
  end

  alias FixApi.Descriptor
  alias FixApi.Helper
  alias FixApi.Messages.ExecutionReport
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
  def init(opts) do
    name = Keyword.get(opts, :name) || @default_name
    pubsub = Keyword.get(opts, :pubsub)

    state = %State{
      name: name,
      msg_seq_num: 0,
      sender_comp_id: Helper.generate_comp_id(),
      pubsub: pubsub
    }

    {:ok, state}
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
  def handle_call(:connect, _from, state) do
    Logger.info("Connected to Binance FIX API over TLS.")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:disconnect, _from, state) do
    Logger.info("Connection closed.")

    {
      :reply,
      :ok,
      %State{state | msg_seq_num: 0, sender_comp_id: Helper.generate_comp_id()}
    }
  end

  @impl true
  def handle_call(:get_sender_comp_id, _from, %State{sender_comp_id: sender_comp_id} = state) do
    {:reply, sender_comp_id, state}
  end

  @impl true
  def handle_info(
        {:send, message},
        %State{msg_seq_num: msg_seq_num, sender_comp_id: sender_comp_id} = state
      ) do
    prepared_message =
      message
      |> Descriptor.set(
        msg_seq_num: msg_seq_num + 1,
        sender_comp_id: sender_comp_id
      )
      |> Descriptor.calculate()

    Logger.info(
      "Message sent: #{String.replace(Descriptor.encode(prepared_message), <<1>>, "|")}"
    )

    maybe_reply_with_mock(prepared_message, msg_seq_num + 1)

    {:noreply, %State{state | msg_seq_num: msg_seq_num + 1}}
  end

  @impl true
  def handle_info({:ssl, message}, %State{} = state) do
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
    |> Enum.map(&maybe_publish(&1, state))

    {:noreply, state}
  end

  defp maybe_publish(%Message{name: :execution_report = name, data: data} = message, %State{
         name: client_name,
         pubsub: pubsub
       })
       when not is_nil(pubsub) do
    cl_ord_id = Keyword.get(data.fields, :cl_ord_id)
    Phoenix.PubSub.broadcast(pubsub, "#{client_name}:message:#{name}", {name, cl_ord_id, data})
    message
  end

  defp maybe_publish(%Message{} = message, %State{}) do
    message
  end

  defp maybe_reply_with_mock(%Message{name: :new_order_single} = message, msg_seq_num) do
    # Execution Report NEW
    :timer.sleep(500)

    first_mock_message =
      message
      |> ExecutionReport.mock_from()
      |> Descriptor.set(msg_seq_num: msg_seq_num + 1)
      |> Descriptor.calculate()
      |> Descriptor.validate()

    send(self(), {:ssl, Descriptor.encode(first_mock_message)})

    # Execution Report FILLED
    :timer.sleep(500)

    second_mock_message =
      first_mock_message
      |> ExecutionReport.mock_from()
      |> Descriptor.set(msg_seq_num: msg_seq_num + 1)
      |> Descriptor.calculate()
      |> Descriptor.validate()

    send(self(), {:ssl, Descriptor.encode(second_mock_message)})
  end

  defp maybe_reply_with_mock(%Message{}, _msg_seq_num), do: :ok
end
