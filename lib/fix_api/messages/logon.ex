defmodule FixApi.Messages.Logon do
  use FixApi.Message,
    msg_type: "A"

  field(:encrypt_method, 98, :int, true, 0)
  field(:heart_bt_int, 108, :int, true, 30)
  field(:raw_data_length, 95, :length, true)
  field(:raw_data, 96, :data, true)
  field(:reset_seq_num_flag, 141, :boolean, true, "Y")
  field(:username, 553, :string, true)
  field(:message_handling, 25035, :int, true, 1)
  field(:response_mode, 25036, :int, false)
  field(:uuid, 25037, :string, true)
  field(:drop_copy_flag, 9406, :boolean, false)

  def build() do
    [{_, _, private, _, _, _}] =
      :fix_api
      |> Application.get_env(:private_key)
      |> Base.decode64!()
      |> :public_key.pem_decode()
      |> Enum.map(&:public_key.pem_entry_decode(&1, ""))

    fields =
      init()
      |> set([{34, 1}])

    signature =
      [35, 49, 56, 34, 52]
      |> Enum.map(&List.keyfind(fields, &1, 0))
      |> Enum.map(&elem(&1, 1).value)
      |> Enum.join(<<1>>)
      |> Ed25519.signature(private)
      |> Base.encode64()

    fields
    |> set([
      {96, signature},
      {95, String.length(signature)},
      {553, Application.get_env(:fix_api, :api_key)}
    ])
    |> calculated_fields()
  end
end
