defmodule FixApi.Validator do
  alias FixApi.Schemas.{
    Field,
    FieldRef,
    Group
  }

  def validate({name, %{ref: :field} = opts}, field_definitions, field_values) do
    options =
      opts
      |> Map.delete(:ref)
      |> Map.put(:field, field_definitions[name])

    field =
      %FieldRef{name: name}
      |> Map.merge(options)

    value = Keyword.get(field_values, name)

    validate_field(field, value)
  end

  def validate(
        {group_name, %Group{children: meta_fields} = group_field},
        field_definitions,
        field_values
      ) do
    case Keyword.get(field_values, group_name) do
      nil ->
        if group_field.required == true do
          {group_name, "is required"}
        else
          :valid
        end

      groups ->
        groups
        |> Enum.map(fn group_field_values ->
          Enum.map(meta_fields, &validate(&1, field_definitions, group_field_values))
        end)
    end
  end

  def validate_field(%FieldRef{name: name, required: true}, nil) do
    {name, "is required"}
  end

  def validate_field(%FieldRef{name: _name, required: false}, nil) do
    :valid
  end

  def validate_field(
        %FieldRef{name: name, field: %Field{type: :boolean, allowed_values: nil}},
        value
      ) do
    if value not in ["Y", "N"] do
      {name, "must be 'Y' or 'N'"}
    else
      :valid
    end
  end

  def validate_field(
        %FieldRef{name: name, field: %Field{type: :char, allowed_values: nil}},
        value
      ) do
    if String.length(value) != 1 do
      {name, "must have a single character"}
    else
      :valid
    end
  end

  def validate_field(
        %FieldRef{name: name, field: %Field{type: :int, allowed_values: nil}},
        value
      ) do
    case Integer.parse(value) do
      {_number, ""} ->
        :valid

      _ ->
        {name, "must be a valid integer"}
    end
  end

  def validate_field(
        %FieldRef{name: name, field: %Field{type: type, allowed_values: nil}},
        value
      )
      when type in [:length, :numingroup, :seqnum] do
    case Integer.parse(value) do
      {number, ""} ->
        if number < 0 do
          {name, "must be a positive integer"}
        else
          :valid
        end

      _ ->
        {name, "must be a valid integer"}
    end
  end

  def validate_field(
        %FieldRef{name: name, field: %Field{type: type, allowed_values: nil}},
        value
      )
      when type in [:qty, :price] do
    case Float.parse(value) do
      {_number, ""} ->
        :valid

      _ ->
        {name, "must be a valid float"}
    end
  end

  def validate_field(
        %FieldRef{name: name, field: %Field{type: :utctimestamp, allowed_values: nil}},
        value
      ) do
    pattern =
      if Regex.match?(~r/\.[0-9]{1,6}$/, value) do
        "%Y%m%d-%H:%M:%S.%f"
      else
        "%Y%m%d-%H:%M:%S"
      end

    case Timex.parse(value, pattern, :strftime) do
      {:ok, _datetime} ->
        :valid

      {:error, _error} ->
        {name, "must be a valid utctimestamp format"}
    end
  end

  def validate_field(%FieldRef{name: _name, field: %Field{allowed_values: nil}}, _value) do
    :valid
  end

  def validate_field(
        %FieldRef{name: name, field: %Field{allowed_values: allowed_values}},
        value
      ) do
    values =
      allowed_values
      |> Enum.map(fn {enum, _description} -> enum end)

    if value in values do
      :valid
    else
      descriptions =
        allowed_values
        |> Enum.map(fn {enum, description} -> "#{enum}: #{description}" end)
        |> Enum.join(", ")

      {name, "must be one of these [#{descriptions}]"}
    end
  end
end
