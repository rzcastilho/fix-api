defmodule FixApi.MessageParser do
  alias FixApi.Messages.Schemas.Field
  alias FixApi.Messages.{Heartbeat, TestRequest, Reject, Logon, Logout}

  @soh <<1>>
  @msg_type_tag 35

  def decode(message) when is_binary(message) do
    tag_values =
      message
      |> String.split(@soh)
      |> Enum.map(&Regex.named_captures(~r/^(?<tag>[0-9]+)=(?<value>.+)/, &1))
      |> Enum.filter(fn
        %{"tag" => _, "value" => _} -> true
        _ -> false
      end)
      |> Enum.map(fn %{"tag" => tag, "value" => value} -> {String.to_integer(tag), value} end)

    fields = fields_by_tag(tag_values)

    tag_values
    |> Enum.reduce(
      fields,
      fn {tag, value}, acc ->
        case List.keyfind(acc, tag, 0) do
          {^tag, field} ->
            List.keyreplace(acc, tag, 0, {tag, %Field{field | value: value}})

          _ ->
            acc
        end
      end
    )
  end

  def encode(fields) do
    fields
    |> Enum.filter(fn
      {_tag, %Field{value: nil}} -> false
      _ -> true
    end)
    |> Enum.map(fn {_tag, %Field{tag: tag, value: value}} -> "#{tag}=#{value}" end)
    |> Enum.join(@soh)
    |> Kernel.<>(@soh)
  end

  def fields_by_tag(tag_values) do
    case List.keyfind(tag_values, @msg_type_tag, 0) do
      {_tag, "0"} ->
        Heartbeat.fields()

      {_tag, "1"} ->
        TestRequest.fields()

      {_tag, "3"} ->
        Reject.fields()

      {_tag, "5"} ->
        Logout.fields()

      {_tag, "A"} ->
        Logon.fields()
    end
  end
end
