defmodule FixApi.Helper do
  def generate_comp_id() do
    generate_id(4)
  end

  def generate_ord_id() do
    generate_id(16)
  end

  defp generate_id(bytes) do
    bytes
    |> :crypto.strong_rand_bytes()
    |> Base.encode16()
  end

  def format_price(number) when is_integer(number) do
    format_price(number / 1)
  end

  def format_price(number) do
    string_float = Float.to_string(number)

    case Regex.named_captures(~r/(?<numbers>[0-9]+)e-(?<decimals>[0-9]+)$/, string_float) do
      %{"decimals" => decimals, "numbers" => numbers} ->
        :erlang.float_to_binary(number,
          decimals: String.to_integer(decimals) + String.length(numbers)
        )

      _ ->
        string_float
    end
  end

  def format_qty(number, decimals \\ 0)

  def format_qty(number, decimals) when is_integer(number) do
    format_qty(number / 1, decimals)
  end

  def format_qty(number, decimals) do
    :erlang.float_to_binary(number, decimals: decimals)
  end

  def to_float(number) when is_float(number), do: number
  
  def to_float(number) when is_integer(number), do: number * 1.0

  def to_float(number) when is_bitstring(number) do
    case Float.parse(number) do
      {float, ""} ->
        float
      _ ->
        raise "Error parsing #{number} to float"
    end
  end

end
