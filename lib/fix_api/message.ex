defmodule FixApi.Message do
  alias FixApi.Messages.Schemas.Field

  defmacro __using__(opts) do
    quote do
      Module.put_attribute(__MODULE__, :soh, <<1>>)

      case List.keyfind(unquote(opts), :description, 0) do
        {:description, description} ->
          Module.put_attribute(__MODULE__, :description, description)

        _ ->
          Module.put_attribute(__MODULE__, :description, "")
      end

      case List.keyfind(unquote(opts), :msg_type, 0) do
        {:msg_type, type} ->
          Module.put_attribute(__MODULE__, :msg_type, type)

        _ ->
          raise "type is required for message definition"
      end

      Module.register_attribute(__MODULE__, :header_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :body_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :trailer_fields, accumulate: true)

      import unquote(__MODULE__)
      alias FixApi.Messages.Schemas.Field

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      [
        {:begin_string, 8, :string, true, "FIX.4.4"},
        {:body_length, 9, :string, true, nil},
        {:msg_type, 35, :string, true, @msg_type},
        {:sender_comp_id, 49, :string, true, nil},
        {:target_comp_id, 56, :string, true, "SPOT"},
        {:msg_seq_num, 34, :string, true, nil},
        {:sending_time, 52, :string, true, nil},
        {:recv_window, 25000, :string, false, nil}
      ]
      |> Enum.map(fn {name, tag, type, required, value} ->
        {
          tag,
          %Field{
            tag: tag,
            name: name,
            type: type,
            required: required,
            value: value
          }
        }
      end)
      |> Enum.each(&Module.put_attribute(__MODULE__, :header_fields, &1))

      [
        {:check_sum, 10, :string, true, nil}
      ]
      |> Enum.map(fn {name, tag, type, required, value} ->
        {
          tag,
          %Field{
            tag: tag,
            name: name,
            type: type,
            required: required,
            value: value
          }
        }
      end)
      |> Enum.each(&Module.put_attribute(__MODULE__, :trailer_fields, &1))

      all_fields =
        @trailer_fields ++ @body_fields ++ @header_fields

      Module.put_attribute(__MODULE__, :all_fields, all_fields)

      header_field_names =
        @header_fields
        |> Enum.map(&{elem(&1, 1).name, elem(&1, 0)})

      body_field_names =
        @body_fields
        |> Enum.map(&{elem(&1, 1).name, elem(&1, 0)})

      trailer_field_names =
        @trailer_fields
        |> Enum.map(&{elem(&1, 1).name, elem(&1, 0)})

      all_field_names =
        trailer_field_names ++ body_field_names ++ header_field_names

      Module.put_attribute(__MODULE__, :header_field_names, header_field_names)
      Module.put_attribute(__MODULE__, :body_field_names, body_field_names)
      Module.put_attribute(__MODULE__, :trailer_field_names, trailer_field_names)
      Module.put_attribute(__MODULE__, :all_field_names, all_field_names)

      def field_names(kind \\ :all) do
        case kind do
          :all -> @all_field_names
          :header -> @header_field_names
          :body -> @body_field_names
          :trailer -> @trailer_field_names
        end
        |> Enum.reverse()
      end

      def fields(kind \\ :all) do
        case kind do
          :all -> @all_fields
          :header -> @header_fields
          :body -> @body_fields
          :trailer -> @trailer_fields
        end
        |> Enum.reverse()
      end

      def init() do
        fields()
        |> Enum.map(&init/1)
      end

      def init({49, field}) do
        hash =
          6
          |> :crypto.strong_rand_bytes()
          |> Base.url_encode64(padding: false)

        {49, %Field{field | value: hash}}
      end

      def init({52, field}) do
        datetime =
          DateTime.utc_now()
          |> Calendar.strftime("%Y%m%d-%H:%M:%S.%f")

        {52, %Field{field | value: datetime}}
      end

      def init(field), do: field

      def set(fields, values) do
        Enum.reduce(
          values,
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

      def calculated_fields(fields) when is_list(fields) do
        Enum.reduce(fields, fields, &calculated_fields/2)
      end

      def calculated_fields({9, field}, fields) do
        body_field_ids =
          @body_field_names
          |> Enum.map(&elem(&1, 1))

        header_field_ids =
          @header_field_names
          |> Enum.filter(&(elem(&1, 0) not in [:begin_string, :body_length]))
          |> Enum.map(&elem(&1, 1))

        message_string =
          (header_field_ids ++ body_field_ids)
          |> Enum.map(&List.keyfind(fields, &1, 0))
          |> Enum.filter(&(elem(&1, 1).value != nil))
          |> Enum.map(&"#{elem(&1, 1).tag}=#{elem(&1, 1).value}")
          |> Enum.join(@soh)
          |> Kernel.<>(@soh)

        List.keyreplace(fields, 9, 0, {9, %Field{field | value: String.length(message_string)}})
      end

      def calculated_fields({10, field}, fields) do
        checksum =
          fields
          |> Enum.filter(&(elem(&1, 1).value != nil))
          |> Enum.map(&"#{elem(&1, 1).tag}=#{elem(&1, 1).value}")
          |> Enum.join(@soh)
          |> Kernel.<>(@soh)
          |> String.to_charlist()
          |> Enum.sum()
          |> rem(256)

        List.keyreplace(
          fields,
          10,
          0,
          {10, %Field{field | value: "#{String.pad_leading("#{checksum}", 3, "0")}"}}
        )
      end

      def calculated_fields(_field, fields), do: fields
    end
  end

  defmacro field(name, tag, type, required, value \\ nil) do
    quote do
      field =
        {
          unquote(tag),
          %Field{
            tag: unquote(tag),
            name: unquote(name),
            type: unquote(type),
            required: unquote(required),
            value: unquote(value)
          }
        }

      Module.put_attribute(__MODULE__, :body_fields, field)
    end
  end
end
