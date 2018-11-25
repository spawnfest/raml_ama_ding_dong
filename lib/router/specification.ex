defmodule RAML.Specification do
  use GenServer

  alias Router.Resources

  def init(state) do
    {:ok, state, {:continue, :finish_init}}
  end

  def start_link(opts) do
    path = Keyword.fetch!(opts, :path)
    processor = Keyword.get(opts, :processing_module)

    case GenServer.start_link(__MODULE__, %{path: path, contents: nil, processing_module: processor}, opts) do
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:ok, pid} -> {:ok, pid}
    end
  end

  def handle_continue(:finish_init, state) do
    contents =
      state.path
      |> RAML.Parser.parse

    {:noreply, %{state | contents: contents}}
  end

  def response_for(path, method, headers, query_params) do
    GenServer.call({:global, __MODULE__}, {:response_for, path, method, headers, query_params})
  end

  def contents do
    GenServer.call({:global, __MODULE__}, {:contents})
  end

  def handle_call({:contents}, _from, state) do
    {:reply, state.contents, state}
  end

  def handle_call({:response_for, path, method, headers, query_params}, _from, state) do
    default_content_type = Map.get(state.contents, :media_type, :not_provided)
    types = state.contents.types

    response =
      with {:ok, resource} <- Resources.get_resource(state.contents, path),
           {:ok, matched_method} <- Resources.validate_method(resource, method)
      do
        params = Map.merge(query_params, get_uri_params(resource.path, path))
        type_to_validate = Map.get(resource.methods, method).query_string

        RAML.Validator.validate(params, type_to_validate, types) |> IO.inspect

        handle_method(state.processing_module, method, resource.path, headers, matched_method, default_content_type, types, params)
      else
        :not_found -> not_found_response()
        :method_not_allowed -> method_not_allowed_response()
      end

    {:reply, response, state}
  end

  defp handle_method(nil, _method, _path, _headers, matched_method, _default_content_type, types, _query_params) do
    # ways this could go wrong
    # missing media types
    # missing types
    # plain example instead of type example
    # many many more

    resp = matched_method.responses["200"].body
    example = types |> Enum.find(&(&1.name == resp)) |> Map.get(:example) |> Map.get(:value)


    %{ headers: [{"content-type", "text/plain"}], status: 200, body: example }
  end
  defp handle_method(module, method, path, headers, _matched_method, _default_content_type, _types, query_params) do
    request = %{headers: headers, params: query_params}

    {status, headers, body} = :erlang.apply(module, :call, [path, method, request])

    %{ headers: headers, status: status, body: Jason.encode!(body) <> "\n" }
  end

  def not_found_response do
    %{
      headers: [{"content-type", "text/plain"}],
      status: 404,
      body: "Not Found\n"
    }
  end

  def method_not_allowed_response do
    %{
      headers: [{"content-type", "text/plain"}],
      status: 405,
      body: "Method Not Allowed\n"
    }
  end

  defp get_uri_params(route_path, submitted_path) do
    route_path
    |> String.split("/", trim: true)
    |> Enum.zip(submitted_path)
    |> Enum.reduce(%{}, &whatever/2)
  end

  def whatever({template, actual}, acc) do
    if String.starts_with?(template, "{") do
      Map.put(acc, String.slice(template, 1..-2), actual)
    else
      acc
    end
  end
end
