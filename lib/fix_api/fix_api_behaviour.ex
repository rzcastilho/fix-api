defmodule FixApi.FixApiBehaviour do
  @callback start_link(process_id :: pid() | atom()) ::
              {:ok, pid} | :ignore | {:error, {:already_started, pid} | term}
  @callback connect(process_id :: pid() | atom()) :: term()
  @callback disconnect(process_id :: pid() | atom()) :: term()
  @callback get_sender_comp_id(process_id :: pid() | atom()) :: term()
  @callback send_message(process_id :: pid() | atom(), message :: any()) :: message :: any()
end
