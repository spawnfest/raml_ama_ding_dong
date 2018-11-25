defmodule RAMLValidatorTest do
  use ExUnit.Case
  alias RAML.Validator
  alias RAML.Nodes.TypeDeclaration

  test "validates max_properties" do
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

    assert {:ok, fields} == Validator.validate(
      fields,
      "NoMaxProperties",
      [%TypeDeclaration{name: "NoMaxProperties"}]
    )
  end

  test "validates min_properties" do
    fields = %{"one" => 1, "two" => 2}
    assert {:ok, fields} == Validator.validate(
      fields,
      "NoLessThanTwo",
      [%TypeDeclaration{name: "NoLessThanTwo", min_properties: 2}]
    )
    assert {:error, :min_properties} == Validator.validate(
      Map.delete(fields, "two"),
      "NoLessThanTwo",
      [%TypeDeclaration{name: "NoLessThanTwo", min_properties: 2}]
    )

    lotsa_fields = Map.merge(fields, %{"three" => 3, "four" => 4})
    assert {:ok, lotsa_fields} == Validator.validate(
      lotsa_fields,
      "NoMinProperties",
      [%TypeDeclaration{name: "NoMinProperties"}]
    )
  end

  test "validates additional_properties" do
    fields = %{
      "one" => 1,
      "two" => 2,
      "additional_property" => "Not defined in RAML"
    }
    assert {:ok, fields} == Validator.validate(
      fields,
      "AdditionalPropertiesTrue",
      [%TypeDeclaration{
          name: "AdditionalPropertiesTrue",
          additional_properties: true,
          properties: %{
            "one" => %{type: "string"},
            "two" => %{type: "string"}
         }}]
    )

    assert {:ok, fields} == Validator.validate(
      fields,
      "AdditionalPropertiesNil",
      [%TypeDeclaration{
          name: "AdditionalPropertiesNil",
          properties: %{
            "one" => %{type: "string"},
            "two" => %{type: "string"}
          }}]
    )

    assert {:error, :additional_properties} == Validator.validate(
      fields,
      "AdditionalPropertiesNil",
      [%TypeDeclaration{
          name: "AdditionalPropertiesNil",
          additional_properties: false,
          properties: %{
            "one" => %{type: "string"},
            "two" => %{type: "string"}
          }}]
    )


    valid_fields = Map.delete(fields, "additional_property")

    assert {:ok, valid_fields} == Validator.validate(
      valid_fields,
      "AdditionalPropertiesNil",
      [%TypeDeclaration{
          name: "AdditionalPropertiesNil",
          properties: %{
            "one" => %{type: "string"},
            "two" => %{type: "string"}
          }}]
    )
  end

  test "validates unique_items" do
    fields = [1, 2, 3, 1]

    assert {:ok, fields} == Validator.validate(
      fields,
      "FalseUniqueItems",
      [%TypeDeclaration{
          name: "FalseUniqueItems",
          type: "array",
          unique_items: false
       }]
    )

    assert {:error, :unique_items} == Validator.validate(
      fields,
      "TrueUniqueItems",
      [%TypeDeclaration{
          name: "TrueUniqueItems",
          type: "array",
          unique_items: true
       }]
    )

    assert {:ok, fields} == Validator.validate(
      fields,
      "NilUniqueItems",
      [%TypeDeclaration{
          name: "NilUniqueItems",
          type: "array"
       }]
    )
  end

  test "validates_min_items" do
    fields = Enum.to_list(1..10)

    assert {:ok, fields} == Validator.validate(
      fields,
      "NoLessThanTwo",
      [%TypeDeclaration{
          name: "NoLessThanTwo",
          type: "array",
          min_items: 2
       }]
    )

    assert {:error, :min_items} == Validator.validate(
      fields,
      "NoLessThanEleven",
      [%TypeDeclaration{
          name: "NoLessThanEleven",
          type: "array",
          min_items: 11
       }]
    )

    empty_field = []
    assert {:ok, empty_field} == Validator.validate(
      empty_field,
      "NilMinItems",
      [%TypeDeclaration{
          name: "NilMinItems",
          type: "array"
       }]
    )
  end

  test "validates_max_items" do
    fields = Enum.to_list(1..10)

    assert {:ok, fields} == Validator.validate(
      fields,
      "NoMoreThanEleven",
      [%TypeDeclaration{
          name: "NoMoreThanEleven",
          type: "array",
          max_items: 11
       }]
    )

    assert {:error, :max_items} == Validator.validate(
      fields,
      "NoMoreThanFive",
      [%TypeDeclaration{
          name: "NoMoreThanFive",
          type: "array",
          max_items: 5
       }]
    )

    crazy_huge_fields = Enum.to_list(1..100000)
    assert {:ok, crazy_huge_fields} == Validator.validate(
      crazy_huge_fields,
      "NilNaxItems",
      [%TypeDeclaration{
          name: "NilNaxItems",
          type: "array"
       }]
    )
  end
end
