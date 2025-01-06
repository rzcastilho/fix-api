defmodule FixApi.Grouper do
  alias FixApi.Schemas.Group

  def group({field_name, %{ref: :field}}, {field_definitions, field_values, grouped} = acc) do
    case Keyword.pop_first(field_values, field_name) do
      {nil, _field_values} ->
        acc

      {value, field_values_rest} ->
        {field_definitions, field_values_rest, grouped ++ [{field_name, value}]}
    end
  end

  def group(
        {group_name, %Group{} = field_group},
        {field_definitions, field_values, grouped} = acc
      ) do
    case Keyword.pop_first(field_values, group_name) do
      {nil, _field_values} ->
        acc

      {value, field_values_rest} ->
        {count, ""} = Integer.parse(value)

        {items, field_values_group_rest} =
          group(field_group, field_definitions, field_values_rest, count)

        {field_definitions, field_values_group_rest, grouped ++ [{group_name, items}]}
    end
  end

  def group(
        {field_name, %{ref: :field}},
        {field_definitions, [{next_field_name, _next_field_value} | _] = field_values,
         group_fields, grouped} = acc
      ) do
    with true <- Enum.member?(group_fields, next_field_name),
         index <- Enum.find_index(group_fields, &(&1 == field_name)),
         true <- index != nil,
         {_field_name, group_fields_rest} <- List.pop_at(group_fields, index) do
      case Keyword.pop_first(field_values, field_name) do
        {nil, field_values_rest} ->
          {:cont, {field_definitions, field_values_rest, group_fields_rest, grouped}}

        {value, field_values_rest} ->
          {:cont,
           {field_definitions, field_values_rest, group_fields_rest,
            grouped ++ [{field_name, value}]}}
      end
    else
      _ ->
        {:halt, acc}
    end
  end

  def group(
        {group_name, %Group{} = field_group},
        {field_definitions, [{next_field_name, _next_field_value} | _] = field_values,
         group_fields, grouped} = acc
      ) do
    with true <- Enum.member?(group_fields, next_field_name),
         {value, field_values_rest} <- Keyword.pop_first(field_values, group_name),
         index <- Enum.find_index(group_fields, &(&1 == group_name)),
         true <- index != nil,
         {_group_name, group_fields_rest} <- List.pop_at(group_fields, index) do
      {count, ""} = Integer.parse(value)

      {items, field_values_group_rest} =
        group(field_group, field_definitions, field_values_rest, count)

      {:cont,
       {field_definitions, field_values_group_rest, group_fields_rest,
        grouped ++ [{group_name, items}]}}
    else
      _ ->
        {:halt, acc}
    end
  end

  def group(field_group, field_definitions, field_values, count, items \\ [])

  def group(
        %Group{children: metadata, field_list: group_fields} = field_group,
        field_definitions,
        field_values,
        count,
        items
      )
      when count > 0 do
    {_, field_values_rest, _, grouped} =
      Enum.reduce_while(
        metadata,
        {field_definitions, field_values, group_fields, []},
        &group/2
      )

    group(field_group, field_definitions, field_values_rest, count - 1, items ++ [grouped])
  end

  def group(%Group{}, _field_definitions, field_values, _count, items) do
    {items, field_values}
  end
end
