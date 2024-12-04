alias FixApi.Messages.{
  Logon,
  Logout,
  TestRequest,
  Heartbeat,
  Reject
}

api_key = System.fetch_env!("API_KEY")

keys = System.fetch_env!("PRIVATE_KEY")
[{_, _, private, _, _, _}] =
  keys
  |> :public_key.pem_decode()
  |> Enum.map(&:public_key.pem_entry_decode(&1, ""))

message_func = fn ->
  datetime =
    DateTime.utc_now
    |> Calendar.strftime("%Y%m%d-%H:%M:%S.%f")

  fields =
    [
      "A",
      "5QJmUOms",
      "SPOT",
      "1",
      datetime
    ]
    |> Enum.join(<<1>>)

  raw_message = Ed25519.signature(fields, private) |> Base.encode64()

  pre_message =
    "8=FIX.4.4|9=251|35=A|34=1|49=5QJmUOms|52=#{datetime}|56=SPOT|95=88|96=#{raw_message}|98=0|108=30|141=Y|553=#{api_key}|25035=1|"
    |> String.split("|")
    |> Enum.join(<<1>>)

  checksum =
    pre_message
    |> String.to_charlist()
    |> Enum.sum()
    |> rem(256)

  pre_message <> "10=#{String.pad_leading("#{checksum}", 3, "0")}" <> <<1>>
end

test_signature = fn  ->
  keys = System.fetch_env!("PRIVATE_KEY")
  [{_, _, private, _, _, _}] =
    keys
    |> :public_key.pem_decode()
    |> Enum.map(&:public_key.pem_entry_decode(&1, ""))

  fields =
    [
      "A",
      "EXAMPLE",
      "SPOT",
      "1",
      "20240627-11:17:25.223"
    ]
    |> Enum.join(<<1>>)
  signature =
    Ed25519.signature(fields, private) |> Base.encode64()
  {signature == "4MHXelVVcpkdwuLbl6n73HQUXUf1dse2PCgT1DYqW9w8AVZ1RACFGM+5UdlGPrQHrgtS3CvsRURC1oj73j8gCA==", String.length(signature)}
end

build_message = fn message_text ->
  message_text
  |> String.split("|")
  |> Enum.join(<<1>>)
end

logon_request = build_message.("8=FIX.4.4|9=251|35=A|34=1|49=5QJmUOms|52=20241125-21:09:35.974916|56=SPOT|95=88|96=d2wxUu+6CuodCAZmBCPBIEOnK2rwduRCpBHDUmVuPNlxT2H1r3pZ9sYb8mMAxqTfmUVrva8lhO3dXN5XbMD7BA==|98=0|108=30|141=Y|553=aUku5McuKcxGj9YAN2NnWstOt6eGxR25RxhH76tGTh1FuAdPBQjQt8mZZqI3RLA0|25035=1|10=190|")

logon_response = build_message.("8=FIX.4.4|9=0000113|35=A|49=SPOT|56=5QJmUOms|34=1|52=20241125-21:09:36.249799|98=0|108=30|25037=5e5f2e87-49b3-4c59-9734-eddd94a9a691|10=069|")

heartbeat = build_message.("8=FIX.4.4|9=0000058|35=0|49=SPOT|56=5QJmUOms|34=2|52=20241125-21:10:06.883856|10=114|")

test_request = build_message.("8=FIX.4.4|9=0000076|35=1|49=SPOT|56=5QJmUOms|34=3|52=20241125-21:10:12.890508|112=1732569012890|10=224|")

logout = build_message.("8=FIX.4.4|9=0000099|35=5|49=SPOT|56=5QJmUOms|34=4|52=20241125-21:10:42.923592|58=Session unresponsive to TestRequests.|10=163|")

start_client = fn ->
  FixApi.Client.start_link()
  FixApi.Client.connect()
end

logon_request = fn ->
    Logon.build() |> FixApi.MessageParser.encode()
end

heartbeat = fn ->
  Heartbeat.build |> FixApi.MessageParser.encode()
end

"""
8=FIX.4.4|9=251|
35=A|34=1|49=5QJmUOms|52=20241127-20:17:47.568140|56=SPOT|
95=88|96=3Dn2yL2ODsy63O4FnBQ02eiHY4xeq8dmekuUCEIpPVJs9e3cpMkxiSrIXpPSVr8iaGT8zUH4hLmYwNy5mri5Bw==|98=0|108=30|141=Y|553=aUku5McuKcxGj9YAN2NnWstOt6eGxR25RxhH76tGTh1FuAdPBQjQt8mZZqI3RLA0|25035=1|10=233|

8=FIX.4.4|9=215|
35=A|49=FRBcbzBOxK8|56=SPOT|34=1|52=20241127-20:25:22.887635|
98=0|108=60|95=88|96=+7VQaavDnnZRBgI+2o0C+RuyAYEnswH5OBDukV1/j/hRTOb02dRhz5KEiKopCcgHq70gUZWydmfy2ODIXZlCCw==|141=Y|553=aUku5McuKcxGj9YAN2NnWstOt6eGxR25RxhH76tGTh1FuAdPBQjQt8mZZqI3RLA0|25035=1|10=042|
"""
