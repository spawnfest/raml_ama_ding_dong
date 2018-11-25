defmodule ResourcesTest do
  use ExUnit.Case, async: true

  @types "support/fixtures/types.raml"
  |> Path.expand(__DIR__)
  |> RAML.Parser.parse

  # @nested "support/fixtures/nested_resources.raml"
  # |> Path.expand(__DIR__)
  # |> RAML.Parser.parse

  test "returns not_found for routes that don't match" do
    result = Router.Resources.get_resource(@types, ["hello"])

    assert result == :not_found
  end

  test "doesn't match undefined sub routes" do
    result = Router.Resources.get_resource(@types, ["orgs"])

    assert result == :not_found
  end

  test "returns a resource struct for a matched route" do
    result = Router.Resources.get_resource(@types, ["orgs", "3"])

    assert result == {:ok, hd @types.resources}
  end

  test "rejects unsupported methods" do
    resource = hd @types.resources
    result = Router.Resources.validate_method(resource, :put)

    assert result == :method_not_allowed
  end

  test "accepts supported methods" do
    resource = hd @types.resources
    result = Router.Resources.validate_method(resource, :get)

    assert result == {:ok, resource.methods.get}
  end
end
