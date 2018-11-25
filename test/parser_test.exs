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

    assert parsed_hello_world.base_uri == nil
    assert parsed_one_type.base_uri == "http://example.com/api"

    assert parsed_hello_world.media_type == nil
    assert parsed_one_type.media_type == "application/json"
  end

  test "parses resources" do
    parsed = Parser.parse(fixture("hello_world.raml"))
    assert parsed.resources |> hd |> Map.fetch!(:path) == "/hello"
  end

  test "parses method details" do
    parsed = Parser.parse(fixture("hello_world.raml"))
    example_response =
      parsed.resources
      |> hd
      |> Map.fetch!(:methods)
      |> Map.fetch!(:get)
      |> Map.fetch!(:responses)
      |> Map.fetch!("200")
      |> Map.fetch!(:body)
      |> Map.fetch!(:media_types)
      |> Map.fetch!("application/json")
      |> Map.fetch!(:example)
      |> Map.fetch!(:value)
    assert example_response == ~C<{"message": "Hello World"}>
  end

  test "parses types" do
    parsed = Parser.parse(fixture("types.raml"))

    org = Enum.find(parsed.types, fn type -> type.name == "Org" end)
    assert org.properties["Head"] == "Manager"

    manager = Enum.find(parsed.types, fn type -> type.name == "Manager" end)
    assert manager.type == "Person"

    person = Enum.find(parsed.types, fn type -> type.name == "Person" end)
    assert person.type == "object"
  end

  test "parses nested resources" do
    parsed = Parser.parse(fixture("nested_resources.raml"))

    users = Enum.find(parsed.resources, fn r -> r.path == "/users" end)
    assert users.path == "/users"

    [identified_user] = users.resources
    assert identified_user.path == "/{userId}"

    keys = Enum.find(identified_user.resources, fn r -> r.path == "/keys" end)
    assert keys.path == "/keys"

    [identified_key] = keys.resources
    assert identified_key.path == "/{keyId}"
  end

  test "parses the example file" do
    parsed = Parser.parse(fixture("raml_redirects.raml"))

    redirects = Enum.find(parsed.resources, fn r -> r.path == "/redirects" end)
    assert redirects.methods.put.query_string.type == "Redirect"
    assert redirects.methods.put.responses["200"].body == "ShortURL"

    redirect = Enum.find(parsed.types, fn type -> type.name == "Redirect" end)
    assert redirect.properties == %{"name" => "Name", "url" => "URL"}

    forward = Enum.find(parsed.resources, fn r -> r.path == "/r/{name}" end)
    assert forward.uri_parameters == %{"name" => "Name"}
    assert forward.methods.get.responses["302"].headers == %{"Location" => "URL"}
  end

  defp fixture(file_name) do
    Path.expand("support/fixtures/#{file_name}", __DIR__)
  end
end
