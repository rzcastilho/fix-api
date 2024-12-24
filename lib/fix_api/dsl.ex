defmodule FixApi.DSL do
  alias FixApi.Schemas.{
    Data,
    Component,
    ComponentRef,
    Field,
    FieldRef,
    Group,
    Metadata,
    Message
  }

  defmacro __using__(_opts) do
    quote do
      Module.put_attribute(__MODULE__, :soh, <<1>>)
      Module.put_attribute(__MODULE__, :message_type_tag, 35)
      Module.register_attribute(__MODULE__, :fields, accumulate: true)
      Module.register_attribute(__MODULE__, :components, accumulate: true)
      Module.register_attribute(__MODULE__, :messages, accumulate: true)

      import unquote(__MODULE__)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def fields(), do: Enum.into(@fields, %{})

      def set_field({name, value}) when is_atom(name) do
        props = @fields[name]

        props
        |> Map.put(:name, name)
        |> Map.put(:value, value)
      end

      def set_field({tag, value}) when is_integer(tag) do
        {name, field} =
          @fields
          |> Enum.find(fn
            {name, %{tag: ^tag}} -> true
            _ -> false
          end)

        {name, value}
      end

      def components(), do: Enum.into(@components, %{})
      def messages(), do: Enum.into(@messages, %{})
      def hd(), do: @hd
      def tl(), do: @tl

      def message_name_by_type(type) when is_bitstring(type) do
        {name, _message} =
          Enum.find(
            @messages,
            fn
              {_, %{type: ^type}} -> true
              _ -> false
            end
          )

        name
      end

      def new(name) when is_atom(name) do
        case Keyword.get(@messages, name) do
          nil ->
            {:error, "invalid message name"}

          message ->
            message
        end
      end

      def new(type) when is_bitstring(type) do
        type
        |> message_name_by_type()
        |> new()
      end

      def validate(
            %Message{
              metadata: %Metadata{fields: meta_fields},
              data: %Data{fields: data_fields} = data
            } = message
          ) do
        case Enum.reduce(meta_fields, {[], data_fields, []}, &validate/2) do
          {_, _, []} ->
            %Message{message | data: %Data{data | valid?: true, errors: []}}

          {_, _, errors} ->
            %Message{message | data: %Data{data | valid?: false, errors: errors}}
        end
      end

      def validate(
            {name, %Group{children: children, required: required, field_list: _group_fields}},
            {meta_fields, data_fields, errors} = acc
          ) do
        case Keyword.pop_first(data_fields, name) do
          {nil, rest} ->
            if required == true do
              {meta_fields, data_fields, errors ++ [{name, "group is required"}]}
            else
              acc
            end

          {value, rest_data_fields} ->
            case Integer.parse(value) do
              {number, ""} ->
                validate_group(children, {meta_fields, rest_data_fields, errors}, number)

              _ ->
                acc
            end
        end
      end

      def validate(
            {name, %{ref: :field, required: required} = opts},
            {meta_fields, data_fields, errors}
          ) do
        options =
          opts
          |> Map.delete(:ref)
          |> Map.put(:field, @fields[name])

        field =
          %FieldRef{name: name}
          |> Map.merge(options)

        {value, rest_data_fields} = Keyword.pop_first(data_fields, name)

        new_errors =
          case validate_field(field, value) do
            :valid ->
              errors

            error ->
              errors ++ [error]
          end

        {meta_fields ++ [field], rest_data_fields, new_errors}
      end

      def validate(item, acc) do
        acc
      end

      def validate_group(children, {_, data, _} = acc, index) when index > 0 do
        acc_new = Enum.reduce_while(children, acc, &validate_group/2)
        validate_group(children, acc_new, index - 1)
      end

      def validate_group(_children, acc, _index) do
        acc
      end

      def validate_group(
            {name, %Group{children: children, required: required, field_list: field_list}},
            {meta_fields, data_fields, group_fields, errors} = acc
          ) do
        case Keyword.pop_first(data_fields, name) do
          {nil, rest} ->
            if required == true do
              {:halt, {meta_fields, data_fields, errors ++ [{name, "group is required"}]}}
            else
              {:halt, acc}
            end

          {value, rest_data_fields} ->
            case Integer.parse(value) do
              {number, ""} ->
                {:cont,
                 validate_group(
                   children,
                   {meta_fields, rest_data_fields, field_list, errors},
                   number
                 )}

              _ ->
                {:halt, acc}
            end
        end
      end

      def validate_group(
            {name, %{ref: :field, required: required} = opts},
            {meta_fields, data_fields, group_fields, errors}
          ) do
        options =
          opts
          |> Map.delete(:ref)
          |> Map.put(:field, @fields[name])

        field =
          %FieldRef{name: name}
          |> Map.merge(options)

        {value, rest_data_fields} = Keyword.pop_first(data_fields, name)

        new_errors =
          case validate_field(field, value) do
            :valid ->
              errors

            error ->
              errors ++ [error]
          end

        {:cont, {meta_fields ++ [field], rest_data_fields, group_fields, new_errors}}
      end

      def validate_group(item, acc) do
        {:halt, acc}
      end

      def validate_field(%FieldRef{name: name, required: true}, nil) do
        {name, "is required"}
      end

      def validate_field(%FieldRef{name: name, required: false}, nil) do
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

      def validate_field(%FieldRef{name: name, field: %Field{allowed_values: nil}}, _value) do
        :valid
      end

      def validate_field(
            %FieldRef{name: name, field: %Field{allowed_values: allowed_values} = field},
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

      def validate_field(_, _) do
        :not_handled
      end

      def decode(message) when is_bitstring(message) do
        data_fields =
          message
          |> String.split(@soh)
          |> Enum.map(&Regex.named_captures(~r/^(?<tag>[0-9]+)=(?<value>.+)/, &1))
          |> Enum.filter(fn
            %{"tag" => _, "value" => _} -> true
            _ -> false
          end)
          |> Enum.map(fn %{"tag" => tag, "value" => value} -> {String.to_integer(tag), value} end)
          |> Enum.map(&set_field/1)

        message =
          data_fields
          |> Keyword.get(:msg_type)
          |> new()

        %Message{message | data: %Data{message.data | fields: data_fields}}
      end

      def encode(%Message{data: %Data{fields: fields}} = message) do
        fields
        |> Enum.map(fn {name, value} -> "#{@fields[name].tag}=#{value}" end)
        |> Enum.join(@soh)
        |> Kernel.<>(@soh)
      end
    end
  end

  defmacro field(name, opts, do: body) do
    block = extract_block(body)

    quote do
      enums =
        unquote(block)
        |> to_list()

      options =
        unquote(opts)
        |> Enum.into(%{})
        |> Map.put(:allowed_values, enums)

      field = {
        unquote(name),
        %Field{name: unquote(name)}
        |> Map.merge(options)
      }

      Module.put_attribute(__MODULE__, :fields, field)
    end
  end

  defmacro field(name, opts) do
    quote do
      field = {
        unquote(name),
        %Field{name: unquote(name)}
        |> Map.merge(Enum.into(unquote(opts), %{}))
      }

      Module.put_attribute(__MODULE__, :fields, field)
    end
  end

  defmacro value(enum, opts) do
    quote do
      {unquote(enum), Keyword.get(unquote(opts), :description)}
    end
  end

  defmacro component(name, do: body) do
    block = extract_block(body)

    quote do
      children =
        unquote(block)
        |> to_list()

      component =
        {
          unquote(name),
          %Component{name: unquote(name), children: children}
        }

      Module.put_attribute(__MODULE__, :components, component)
    end
  end

  defmacro group(name, opts, do: body) do
    block = extract_block(body)

    quote do
      children =
        unquote(block)
        |> to_list()
        |> Enum.map(&expand(&1, @components))
        |> List.flatten()

      field_list = Keyword.keys(children)

      group =
        unquote(opts)
        |> Enum.into(%{})
        |> Map.merge(%Group{name: unquote(name)})
        |> Map.put(:children, children)
        |> Map.put(:field_list, field_list)

      {unquote(name), group}
    end
  end

  defmacro message(name, opts, do: body) do
    block = extract_block(body)

    quote do
      children =
        unquote(block)
        |> to_list()

      metadata =
        %Metadata{
          fields: @hd ++ children ++ @tl
        }

      options =
        unquote(opts)
        |> Enum.into(%{})
        |> Map.put(:metadata, metadata)

      message =
        {
          unquote(name),
          %Message{name: unquote(name)}
          |> Map.merge(options)
        }

      Module.put_attribute(__MODULE__, :messages, message)
    end
  end

  defmacro field_ref(name, opts) do
    quote do
      {unquote(name), Enum.into(unquote(opts), %{}) |> Map.put(:ref, :field)}
    end
  end

  defmacro component_ref(name, opts) do
    quote do
      {
        unquote(name),
        Enum.into(unquote(opts), %{})
        |> Map.put(:ref, :component)
        # |> Map.put(:component, @components[unquote(name)])
      }
    end
  end

  defmacro header(do: body) do
    block = extract_block(body)

    quote do
      hd =
        unquote(block)
        |> to_list()

      Module.put_attribute(__MODULE__, :hd, hd)
    end
  end

  defmacro trailer(do: body) do
    block = extract_block(body)

    quote do
      tl =
        unquote(block)
        |> to_list()

      Module.put_attribute(__MODULE__, :tl, tl)
    end
  end

  defp extract_block({:__block__, _, block}), do: block
  defp extract_block({_, _, _} = block), do: block

  def to_list(values) when is_list(values), do: values
  def to_list(values), do: [values]

  def expand({name, %{ref: :component}}, reference) do
    reference
    |> Keyword.get(name)
    |> Map.get(:children)
    |> Enum.map(&expand(&1, reference))
  end

  def expand(field, _ref) do
    field
  end
end
