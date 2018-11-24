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
    parsed_hello_world = Parser.parse(fixture("hello_world.raml"))
    parsed_one_type    = Parser.parse(fixture("one_type.raml"))

    assert parsed_hello_world.title == "Hello World"
    assert parsed_one_type.title == "API with Types"

    assert parsed_hello_world.version == nil
    assert parsed_one_type.version == "V1"

    assert parsed_hello_world.description == nil
    assert parsed_one_type.description == "API with Types description"

    assert parsed_hello_world.base_uri == nil
    assert parsed_one_type.base_uri == "http://example.com/api"

    assert parsed_hello_world.media_type == nil
    assert parsed_one_type.media_type == "application/json"
  end

  test "parses resources" do
    parsed = Parser.parse(fixture("hello_world.raml"))
    assert parsed.resources |> hd |> Map.fetch!(:path) == "/hello"
  end

  defp fixture(file_name) do
    Path.expand("support/fixtures/#{file_name}", __DIR__)
  end
end
