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

  test "parses resources" do
    parsed = Parser.parse(fixture("hello_world.raml"))
    assert parsed.resources |> hd |> Map.fetch!(:path) == "/hello"
  end

  defp fixture(file_name) do
    Path.expand("support/fixtures/#{file_name}", __DIR__)
  end
end
