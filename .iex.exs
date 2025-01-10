alias FixApi.Messages.{
  Logon,
  Logout,
  Heartbeat,
  NewOrderSingle
}

start_client = fn ->
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
  {:ok, pid} = FixApi.Client.start_link(opts)
  FixApi.Client.connect(pid)
  FixApi.Client.send_message(pid, Logon.request())
  {:ok, pid}
end
