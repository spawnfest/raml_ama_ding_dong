defmodule RAML.Validator do
  def validate(fields, declaration, types) do
    type = types
    |> Enum.filter(fn type -> type.name == declaration end)
    |> List.first

    with :ok <- validate_max_properties(fields, Map.get(type, :max_properties)),
         :ok <- validate_min_properties(fields, Map.get(type, :min_properties)),
         :ok <- validate_additional_properties(
           fields,
           Map.get(type, :properties),
           Map.get(type, :additional_properties)) do
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
end
