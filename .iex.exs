alias FixApi.Messages.{
  Logon,
  Logout,
  Heartbeat,
  NewOrderSingle
}

alias Phoenix.PubSub

children = [{PubSub, name: :my_pubsub}]
{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
PubSub.subscribe(:my_pubsub, "FixUser1:message:execution_report")

start_client = fn ->
  opts = [
      name: :"FixUser1",
      host: String.to_charlist(Application.get_env(:fix_api, :hostname)),
      port: Application.get_env(:fix_api, :port),
      sni: String.to_charlist(Application.get_env(:fix_api, :sni)),
      pubsub: :my_pubsub
    ]
  {:ok, pid} = FixApi.Client.start_link(opts)
  FixApi.Client.connect(pid)
  sender_comp_id = FixApi.Client.get_sender_comp_id(pid)
  FixApi.Client.send_message(pid, Logon.request(sender_comp_id))
  {:ok, pid}
end
