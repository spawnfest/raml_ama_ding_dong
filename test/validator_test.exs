defmodule RAMLValidatorTest do
  use ExUnit.Case
  alias RAML.Validator
  alias RAML.Nodes.TypeDeclaration

  test "validates RAML comment and version" do
    fields = %{"one" => 1, "two" => 2}
    assert {:ok, fields} == Validator.validate(
      fields,
      "NoMoreThanTwo",
      [%TypeDeclaration{name: "NoMoreThanTwo", max_properties: 2}]
    )
    assert {:error, :max_properties} == Validator.validate(
      Map.put(fields, "three", 3),
      "NoMoreThanTwo",
      [%TypeDeclaration{name: "NoMoreThanTwo", max_properties: 2}]
    )
  end
end
