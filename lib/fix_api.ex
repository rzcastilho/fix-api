defmodule FixApi do
  import SweetXml

  def parse_spot_fix_oe() do
    {:ok, {_, _, response}} =
      :httpc.request(
        ~c"https://raw.githubusercontent.com/binance/binance-spot-api-docs/refs/heads/master/fix/schemas/spot-fix-oe.xml"
      )

    fields =
      response
      |> xpath(
        ~x"//fields/field"l,
        name: ~x"./@name" |> transform_by(&to_name/1),
        number: ~x"./@number" |> transform_by(&to_number/1),
        type: ~x"./@type" |> transform_by(&to_type/1),
        valid_values: [
          ~x"./value"l,
          description: ~x"./@description" |> transform_by(&String.Chars.to_string/1),
          enum: ~x"./@enum" |> transform_by(&String.Chars.to_string/1)
        ]
      )

    components =
      response
      |> xpath(
        ~x"//components/component"l,
        name: ~x"./@name" |> transform_by(&to_name/1),
        children: ~x"./*"l |> transform_by(&to_children/1)
      )

    components
  end

  defp to_name(value) do
    value
    |> String.Chars.to_string()
    |> Macro.underscore()
    |> String.to_atom()
  end

  defp to_number(value) do
    value
    |> String.Chars.to_string()
    |> String.to_integer()
  end

  defp to_type(value) do
    value
    |> String.Chars.to_string()
    |> String.downcase()
    |> String.to_atom()
  end

  defp to_boolean(~c"Y"), do: true
  defp to_boolean(~c"N"), do: false

  defp to_children(children) when is_list(children) do
    to_children(children, [])
  end

  defp to_children([], acc) do
    acc
  end

  defp to_children([child | rest], acc) do
    case to_child(child) do
      :ignore ->
        to_children(rest, acc)

      parsed ->
        to_children(rest, acc ++ [parsed])
    end
  end

  defp to_child({:xmlElement, :field, :field, [], _, _, _, attrs, _, _, _, _}) do
    {:field, process_attrs(attrs)}
  end

  defp to_child({:xmlElement, :group, :group, [], _, _, _, attrs, children, _, _, _} = group) do
    {:group, process_attrs(attrs, %{children: to_children(children)})}
  end

  defp to_child({:xmlElement, :component, :component, [], _, _, _, attrs, _, _, _, _}) do
    {:component, process_attrs(attrs)}
  end

  defp to_child(_) do
    :ignore
  end

  defp process_attrs(attrs) do
    process_attrs(attrs, %{})
  end

  defp process_attrs([], map), do: map

  defp process_attrs([{:xmlAttribute, name, _, _, _, _, _, _, value, _} | rest], map) do
    process_attrs(rest, add_attr(map, name, value))
  end

  defp process_attrs([_unknown | rest], map) do
    process_attrs(rest, map)
  end

  defp add_attr(map, :name, value) do
    Map.put(map, :name, to_name(value))
  end

  defp add_attr(map, :required, value) do
    Map.put(map, :required, to_boolean(value))
  end

  defp add_attr(map, name, value) do
    Map.put(map, name, String.Chars.to_string(value))
  end
end
