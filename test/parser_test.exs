defmodule RAMLParserTest do
  use ExUnit.Case
  alias RAML.Parser

  test "validates RAML comment and version" do
    assert_raise RuntimeError, fn ->
      Parser.parse(fixture("not_raml.txt"))
    end
    assert not is_nil(Parser.parse(fixture("hello_world.raml")))
  end

  test "parses root fields" do
    parsed = Parser.parse(fixture("hello_world.raml"))
    assert parsed.title == "Hello World"
  end

  test "parses version" do
    parsed_without_version = Parser.parse(fixture("hello_world.raml"))
    parsed_with_version    = Parser.parse(fixture("one_type.raml"))

    assert parsed_with_version.version == "V1"
    assert parsed_without_version.version == nil
  end

  test "parses description" do
    parsed_without_description = Parser.parse(fixture("hello_world.raml"))
    parsed_with_description    = Parser.parse(fixture("one_type.raml"))

    assert parsed_with_description.description == "API with Types description"
    assert parsed_without_description.description == nil
  end

  test "parses base_uri" do
    parsed_without_base_uri = Parser.parse(fixture("hello_world.raml"))
    parsed_with_base_uri    = Parser.parse(fixture("one_type.raml"))

    assert parsed_with_base_uri.base_uri == "http://example.com"
    assert parsed_without_base_uri.base_uri == nil
  end

  test "parses resources" do
    parsed = Parser.parse(fixture("hello_world.raml"))
    assert parsed.resources |> hd |> Map.fetch!(:path) == "/hello"
  end

  defp fixture(file_name) do
    Path.expand("support/fixtures/#{file_name}", __DIR__)
  end
end
