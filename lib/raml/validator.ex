defmodule RAML.Validator do
  alias RAML.Nodes.TypeDeclaration

  def validate(fields, declaration, types)
  when is_map(fields) do
    type = get_type(types, declaration)

    with :ok <- validate_type(Map.get(type, :type), :object),
         {:ok, property_fields} <- validate_properties(
           fields,
           Map.get(type, :properties) || Map.new,
           types
         ),
         :ok <- validate_max_properties(fields, Map.get(type, :max_properties)),
         :ok <- validate_min_properties(fields, Map.get(type, :min_properties)),
           :ok <- validate_additional_properties(
             fields,
             Map.get(type, :properties),
             Map.get(type, :additional_properties)) do
      {:ok, Map.merge(fields, property_fields)}
    end
  end

  def validate(fields, declaration, types)
  when is_list(fields) do
    type = get_type(types, declaration)

    with :ok <- validate_type(Map.get(type, :type), :array),
         :ok <- validate_unique_items(fields, Map.get(type, :unique_items)),
         :ok <- validate_min_items(fields, Map.get(type, :min_items)),
         :ok <- validate_max_items(fields, Map.get(type, :max_items)) do
      {:ok, fields}
    end
  end

  def validate(value, declaration, types)
  when is_binary(value) do
    type = get_type(types, declaration)
    string_type = type.type

    case string_type do
      "string" ->
        with :ok <- validate_pattern(value, Map.get(type, :pattern)),
             :ok <- validate_min_length(value, Map.get(type, :min_length)),
             :ok <- validate_max_length(value, Map.get(type, :max_length)) do
          {:ok, value}
        end
      "date-only" ->
        with :ok <- validate_date_only(value) do
          {:ok, value}
        end
      _ ->
        {:error, "Expected #{string_type}"}
    end
  end

  def validate(number, declaration, types)
  when is_number(number) do
    type = get_type(types, declaration)
    number_type = type.type

    case number_type do
      "number" ->
        with :ok <- validate_minimum_number(number, Map.get(type, :minimum)),
             :ok <- validate_maximum_number(number, Map.get(type, :maximum)) do
          {:ok, number}
        end
      "integer" ->
        with :ok <- validate_minimum_number(number, Map.get(type, :minimum)),
             :ok <- validate_maximum_number(number, Map.get(type, :maximum)),
             :ok <- validate_multiple_of(number, Map.get(type, :multiple_of)) do
          {:ok, number}
        end
      _ ->
        {:error, "Expected #{number_type}"}
    end
  end

  def validate_type("array", :array) do
    :ok
  end

  def validate_type(type, :array) do
    {:error, "Expected #{type}"}
  end

  def validate_type("object", :object) do
    :ok
  end

  def validate_type(type, :object) do
    {:error, "Expected #{type}"}
  end

  def validate_properties(fields, properties, types) do
    properties
    |> Enum.reduce_while(Map.new, fn {name, declaration}, combined ->
      case validate(Map.get(fields, name), declaration, types) do
        {:ok, property_fields} ->
          {:cont, Map.put(combined, name, property_fields)}
        error ->
          {:halt, error}
      end
    end)
    |> case do
         property_fields when is_map(property_fields) ->
           {:ok, property_fields}
         error ->
           error
       end
  end

  def validate_max_properties(fields, max) when is_integer(max) do
    actual = Map.size(fields)

    case actual <= max do
      true  -> :ok
      false -> {:error, :max_properties}
    end
  end

  def validate_max_properties(_, _) do
    :ok
  end

  def validate_min_properties(fields, min) when is_integer(min) do
    actual = Map.size(fields)

    case actual >= min do
      true  -> :ok
      false -> {:error, :min_properties}
    end
  end

  def validate_min_properties(_, _) do
    :ok
  end

  def validate_additional_properties(_, _, true) do
    :ok
  end

  def validate_additional_properties(fields, properties, false) do
    case Map.keys(properties) == Map.keys(fields) do
      true  -> :ok
      false -> {:error, :additional_properties}
    end
  end

  def validate_additional_properties(_, _, nil) do
    :ok
  end

  def validate_unique_items(fields, true) do
    case Enum.uniq(fields) == fields do
      true  -> :ok
      false -> {:error, :unique_items}
    end
  end

  def validate_unique_items(_, false) do
    :ok
  end

  def validate_unique_items(_, nil) do
    :ok
  end

  def validate_min_items(fields, nil) do
    validate_min_items(fields, 0)
  end

  def validate_min_items(fields, min) do
    case length(fields) >= min do
      true  ->
        :ok
      false ->
        {:error, :min_items}
    end
  end

  def validate_max_items(fields, nil) do
    validate_max_items(fields, 2147483647)
  end

  def validate_max_items(fields, max) do
    case length(fields) <= max do
      true ->
        :ok
      false ->
        {:error, :max_items}
    end
  end

  def validate_pattern(_, nil) do
    :ok
  end

  def validate_pattern(value, pattern) do
    matches? = Regex.compile!(pattern) |> Regex.match?(value)

    case matches? do
      true ->
        :ok
      false ->
        {:error, :pattern}
    end

  end

  def validate_min_length(value, nil) do
    validate_min_length(value, 0)
  end

  def validate_min_length(value, l) do
    size = String.length(value)
    case size >= l do
      true ->
        :ok
      false ->
        {:error, :min_length}
    end
  end

  def validate_max_length(value, nil) do
    validate_max_length(value, 2147483647)
  end

  def validate_max_length(value, l) do
    size = String.length(value)
    case size <= l do
      true ->
        :ok
      false ->
        {:error, :max_length}
    end
  end

  def validate_minimum_number(number, nil) do
    validate_minimum_number(number, 0)
  end

  def validate_minimum_number(number, min) do
    case number >= min do
      true ->
        :ok
      false ->
        {:error, :minimum}
    end
  end

  def validate_maximum_number(_, nil) do
    :ok
  end

  def validate_maximum_number(number, max) do
    case number <= max do
      true ->
        :ok
      false ->
        {:error, :maximum}
    end
  end

  def validate_multiple_of(_, nil) do
    :ok
  end

  def validate_multiple_of(dividend, divisor) do
    remainder = rem(dividend, divisor)
    case remainder == 0 do
      true ->
        :ok
      false ->
        {:error, :multiple_of}
    end
  end

  def validate_date_only(date) do
    result = Date.from_iso8601(date)

    case result do
      {:ok, _} ->
        :ok
      {:error, _} ->
        {:error, :date_only}
    end
  end

  defp get_type(_types, %TypeDeclaration{type: type} = declaration) when type == "object" or type == "string" or type == "array" or type == "date-only" or type == "integer" or type == "number" do
    declaration
  end
  defp get_type(types, %TypeDeclaration{type: type} = declaration) do
    found_type = types |> Enum.find(&(&1.name == type))

    if !found_type.type do
      %TypeDeclaration{declaration | type: "object"}
    else
      found_type
    end
  end
  defp get_type(types, declaration) do
    types
    |> Enum.filter(fn type -> type.name == declaration end)
    |> hd
  end

end
