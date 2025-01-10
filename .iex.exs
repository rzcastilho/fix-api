alias FixApi.Messages.{
  Logon,
  Logout,
  Heartbeat,
  NewOrderSingle
}

start_client = fn ->
  FixApi.Client.start_link()
  FixApi.Client.connect()
  FixApi.Client.send(Logon.request())
end
