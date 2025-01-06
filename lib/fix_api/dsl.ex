defmodule FixApi.DSL do
  alias FixApi.Schemas.{
    Data,
    Component,
    Field,
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
      import FixApi.Grouper
      import FixApi.Validator

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

          %Message{type: type} = message ->
            message
            |> init()
            |> set(msg_type: type)
        end
      end

      def new(type) when is_bitstring(type) do
        type
        |> message_name_by_type()
        |> new()
      end

      def group(
            %Message{
              metadata: %Metadata{fields: meta_fields},
              data: %Data{fields: data_fields} = data
            } = message
          ) do
        {_fields, _field_values, grouped_field_values} =
          Enum.reduce(meta_fields, {@fields, data_fields, []}, &group/2)

        %Message{message | data: %Data{data | fields: grouped_field_values}}
      end

      def validate(
            %Message{
              metadata: %Metadata{fields: meta_fields},
              data: %Data{fields: data_fields} = data
            } = message
          ) do
        errors =
          meta_fields
          |> Enum.map(&validate(&1, @fields, data_fields))
          |> List.flatten()
          |> Enum.filter(&(&1 != :valid))

        %Message{message | data: %Data{data | valid?: errors == [], errors: errors}}
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
        |> Enum.filter(fn
          {_name, nil} -> false
          _ -> true
        end)
        |> Enum.map(fn {name, value} -> "#{@fields[name].tag}=#{value}" end)
        |> Enum.join(@soh)
        |> Kernel.<>(@soh)
      end

      def init(%Message{metadata: %Metadata{fields: meta_fields}, data: %Data{} = data} = message) do
        data_fields =
          meta_fields
          |> Enum.map(&init/1)

        %Message{message | data: %Data{data | fields: data_fields}}
      end

      def init({:begin_string, %{ref: :field}}) do
        %Field{allowed_values: [{value, _description} | _]} = @fields[:begin_string]
        {:begin_string, value}
      end

      def init({:sending_time, %{ref: :field}}) do
        value =
          DateTime.utc_now()
          |> Calendar.strftime("%Y%m%d-%H:%M:%S.%f")

        {:sending_time, value}
      end

      def init({:target_comp_id, %{ref: :field}}) do
        {:target_comp_id, "SPOT"}
      end

      def init({name, %{ref: :field}}) do
        {name, nil}
      end

      def init({name, %Group{}}) do
        {name, []}
      end

      def set(%Message{data: %Data{fields: data_fields} = data} = message, field_values)
          when is_list(field_values) do
        new_field_values =
          Enum.reduce(field_values, data_fields, fn {field, value}, acc ->
            Keyword.replace(acc, field, value)
          end)

        %Message{message | data: %Data{data | fields: new_field_values}}
      end

      def calculate(%Message{data: %Data{fields: data_fields} = data} = message) do
        Enum.reduce(data_fields, message, &calculate/2)
      end

      def calculate(
            {:body_length, _value},
            %Message{data: %Data{fields: data_fields} = data} = message
          ) do
        message_string =
          data_fields
          |> Enum.filter(fn {key, _value} ->
            key not in [:begin_string, :body_length, :check_sum]
          end)
          |> Enum.filter(fn
            {_key, nil} -> false
            _ -> true
          end)
          |> Enum.map(fn {key, value} -> "#{@fields[key].tag}=#{value}" end)
          |> Enum.join(@soh)
          |> Kernel.<>(@soh)

        set(message, body_length: String.length(message_string))
      end

      def calculate({:check_sum, _}, %Message{data: %Data{fields: data_fields} = data} = message) do
        check_sum =
          data_fields
          |> Enum.filter(fn {key, _value} ->
            key not in [:check_sum]
          end)
          |> Enum.filter(fn
            {_key, nil} -> false
            _ -> true
          end)
          |> Enum.map(fn {key, value} -> "#{@fields[key].tag}=#{value}" end)
          |> Enum.join(@soh)
          |> Kernel.<>(@soh)
          |> String.to_charlist()
          |> Enum.sum()
          |> rem(256)

        set(message, check_sum: "#{String.pad_leading("#{check_sum}", 3, "0")}")
      end

      def calculate(_field, %Message{} = message) do
        message
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
        |> Enum.map(&expand(&1, @components))
        |> List.flatten()

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
