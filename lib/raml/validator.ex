defmodule RAML.Validator do
  def validate(fields, declaration, types)
  when is_map(fields) and is_binary(declaration) do
    type = get_type(types, declaration)

    with :ok <- validate_max_properties(fields, Map.get(type, :max_properties)),
         :ok <- validate_min_properties(fields, Map.get(type, :min_properties)),
           :ok <- validate_additional_properties(
             fields,
             Map.get(type, :properties),
             Map.get(type, :additional_properties)) do
      {:ok, fields}
    end
  end

  def validate(fields, declaration, types)
  when is_list(fields) and is_binary(declaration) do
    type = get_type(types, declaration)

    with :ok <- validate_unique_items(fields, Map.get(type, :unique_items)),
         :ok <- validate_min_items(fields, Map.get(type, :min_items)),
           :ok <- validate_max_items(fields, Map.get(type, :max_items)) do
      {:ok, fields}
    end
  end

  def validate(value, declaration, types)
  when is_binary(value) and is_binary(declaration) do
    type = get_type(types, declaration)

    with :ok <- validate_pattern(value, Map.get(type, :pattern)),
         :ok <- validate_min_length(value, Map.get(type, :min_length)),
         :ok <- validate_max_length(value, Map.get(type, :max_length)) do
      {:ok, value}
    end
  end

  def validate(number, declaration, types)
  when is_number(number) and is_binary(declaration) do
    type = get_type(types, declaration)

    with :ok <- validate_minimum_number(number, Map.get(type, :minimum)),
         :ok <- validate_maximum_number(number, Map.get(type, :maximum)) do
      {:ok, number}
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

  defp get_type(types, declaration) do
    types
    |> Enum.filter(fn type -> type.name == declaration end)
    |> hd
  end

end
