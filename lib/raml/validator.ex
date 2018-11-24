defmodule RAML.Validator do
  def validate(fields, declaration, types) when
  is_map(fields) and
  is_bitstring(declaration) do
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

  def validate(fields, declaration, types) when
  is_list(fields) and
  is_bitstring(declaration) do

    type = get_type(types, declaration)

    with :ok <- validate_unique_items(fields, Map.get(type, :unique_items)),
         :ok <- validate_min_items(fields, Map.get(type, :min_items)) do
      {:ok, fields}
    end
  end

  def validate_max_properties(fields, max) when is_integer(max) do
    actual = fields
    |> Map.keys
    |> length

    case actual <= max do
      true  -> :ok
      false -> {:error, :max_properties}
    end
  end

  def validate_max_properties(_, _) do
    :ok
  end

  def validate_min_properties(fields, min) when is_integer(min) do
    actual = fields
    |> Map.keys
    |> length

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
    case length(fields) >= 0 do
      true ->
        :ok
      false ->
        {:error, :min_items}
    end
  end

  def validate_min_items(fields, min) do
    case length(fields) >= min do
      true  ->
        :ok
      false ->
        {:error, :min_items}
    end
  end

  defp get_type(types, declaration) do
    types
    |> Enum.filter(fn type -> type.name == declaration end)
    |> List.first
  end
end
