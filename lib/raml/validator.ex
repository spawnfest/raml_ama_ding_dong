defmodule RAML.Validator do
  def validate(fields, declaration, types) do
    type = types
    |> Enum.filter(fn type -> type.name == declaration end)
    |> List.first

    with :ok <- validate_max_properties(fields, type.max_properties) do
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

  def validate_max_properties(fields, _) do
    {:ok, fields}
  end
 end
