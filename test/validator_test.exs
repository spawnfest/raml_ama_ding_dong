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

  test "validates_min_items_array" do
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

  test "validates_max_items_array" do
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

  test "validates_pattern_string" do
    pattern      = "\\A[-a-zA-Z0-9_]+\\z"
    good_string  = "hello-world_"
    bad_string   = "$@@#$^(&)"

    assert {:ok, good_string} == Validator.validate(
      good_string,
      "HappyStringPattern",
      [%TypeDeclaration{
          name: "HappyStringPattern",
          type: "string",
          pattern: pattern
       }]
    )

    assert {:error, :pattern} == Validator.validate(
      bad_string,
      "BadStringPattern",
      [%TypeDeclaration{
          name: "BadStringPattern",
          type: "string",
          pattern: pattern
       }]
    )

    assert {:ok, good_string} == Validator.validate(
      good_string,
      "NilPattern",
      [%TypeDeclaration{
          name: "NilPattern",
          type: "string"
       }]
    )



  end

  test "validate_min_length_string" do
    value = "hello"

    assert {:ok, value} == Validator.validate(
      value,
      "NoLessThanFive",
      [%TypeDeclaration{
          name: "NoLessThanFive",
          type: "string",
          min_length: 5
       }]
    )

    assert {:error, :min_length} == Validator.validate(
      value,
      "NoLessThanEleven",
      [%TypeDeclaration{
          name: "NoLessThanEleven",
          type: "string",
          min_length: 11
       }]
    )

    assert {:ok, ""} == Validator.validate(
      "",
      "NilMinLength",
      [%TypeDeclaration{
          name: "NilMinLength",
          type: "string"
       }]
    )
  end

  test "validate_max_length_string" do
    value = "hello"

    assert {:ok, value} == Validator.validate(
      value,
      "NoMoreThanFive",
      [%TypeDeclaration{
          name: "NoMoreThanFive",
          type: "string",
          max_length: 5
       }]
    )

    assert {:error, :max_length} == Validator.validate(
      value,
      "NoMoreThanTwo",
      [%TypeDeclaration{
          name: "NoMoreThanTwo",
          type: "string",
          max_length: 2
       }]
    )

    crazy_long_string = Enum.to_list(1..10000) |> Enum.join

    assert {:ok, crazy_long_string} == Validator.validate(
      crazy_long_string,
      "NilMaxLength",
      [%TypeDeclaration{
          name: "NilMaxLength",
          type: "string"
       }]
    )
  end

  test "validate_minimum_number" do
    value = 5

    assert {:ok, value} == Validator.validate(
      value,
      "NoLessThanFive",
      [%TypeDeclaration{
          name: "NoLessThanFive",
          type: "number",
          minimum: 5
       }]
    )
    assert {:error, :minimum} == Validator.validate(
      value,
      "NoLessThanEleven",
      [%TypeDeclaration{
          name: "NoLessThanEleven",
          type: "number",
          minimum: 11
       }]
    )

    assert {:ok, 0} == Validator.validate(
      0,
      "NilMinimum",
      [%TypeDeclaration{
          name: "NilMinimum",
          type: "number"
       }]
    )
  end

  test "validate_maximum_number" do
    value = 5

    assert {:ok, value} == Validator.validate(
      value,
      "NoMoreThanFive",
      [%TypeDeclaration{
          name: "NoMoreThanFive",
          type: "number",
          maximum: 5
       }]
    )
    assert {:error, :maximum} == Validator.validate(
      value,
      "NoMoreThanTwo",
      [%TypeDeclaration{
          name: "NoMoreThanTwo",
          type: "number",
          maximum: 2
       }]
    )

    assert {:ok, 99999999999999} == Validator.validate(
      99999999999999,
      "NilMaximum",
      [%TypeDeclaration{
          name: "NilMaximum",
          type: "number"
       }]
    )
  end

  test "validate_multiple_of_integer" do
    even     = 1000
    odd      = 1001

    assert {:ok, even} == Validator.validate(
      even,
      "Even",
      [%TypeDeclaration{
          name: "Even",
          type: "integer",
          multiple_of: 2
       }]
    )

    assert {:error, :multiple_of} == Validator.validate(
      odd,
      "Even",
      [%TypeDeclaration{
          name: "Even",
          type: "integer",
          multiple_of: 2
       }]
    )

    assert {:ok, odd} == Validator.validate(
      odd,
      "NilMultipleOf",
      [%TypeDeclaration{
          name: "NilMultipleOf",
          type: "integer"
       }]
    )
  end

  test "validate_date_only" do
    valid_date_only = "2018-11-25"
    invalid_date_only = "2018-11-25T21:00:00"

    assert {:ok, valid_date_only} == Validator.validate(
      valid_date_only,
      "ValidDateOnly",
      [%TypeDeclaration{
          name: "ValidDateOnly",
          type: "date-only"
       }]
    )

    assert {:error, :date_only} == Validator.validate(
      invalid_date_only,
      "InvalidDateOnly",
      [%TypeDeclaration{
          name: "InvalidDateOnly",
          type: "date-only"
       }]
    )
  end
end
