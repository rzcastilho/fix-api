defmodule FixApi.Messages.Logon do
  alias FixApi.Descriptor

  def request() do
    [{_, _, private, _, _, _}] =
      :fix_api
      |> Application.get_env(:private_key)
      |> Base.decode64!()
      |> :public_key.pem_decode()
      |> Enum.map(&:public_key.pem_entry_decode(&1, ""))

    message =
      :logon
      |> Descriptor.new()
      |> Descriptor.set(
        msg_seq_num: 1,
        sender_comp_id: :crypto.strong_rand_bytes(4) |> Base.encode16(),
        encrypt_method: 0,
        reset_seq_num_flag: "Y",
        message_handling: 1
      )

    signature =
      [:msg_type, :sender_comp_id, :target_comp_id, :msg_seq_num, :sending_time]
      |> Enum.map(&message.data.fields[&1])
      |> Enum.join(<<1>>)
      |> Ed25519.signature(private)
      |> Base.encode64()

    message
    |> Descriptor.set(
      raw_data: signature,
      raw_data_length: String.length(signature),
      username: Application.get_env(:fix_api, :api_key)
    )
  end
end
