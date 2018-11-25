defmodule Router.Resources do
  def get_resource(spec, path) do
    spec.resources
    |> Enum.find(:not_found, &(match_route(&1.path, path)))
    |> case do
         :not_found -> :not_found
         resource -> {:ok, resource}
       end
  end

  def validate_method(resource, method) do
    resource.methods
    |> Map.get(method, :method_not_allowed)
    |> case  do
         :method_not_allowed -> :method_not_allowed
         matched_method -> {:ok, matched_method}
       end
  end

  defp route_match({spec, requested}) do
    spec == requested || String.match?(spec, ~r/\A\{.+\}$/)
  end

  defp match_route(spec_route, requested_route) do
    spec_route
    |> String.split("/", trim: true)
    |> Enum.zip(requested_route)
    |> Enum.all?(&route_match(&1))
  end
end
