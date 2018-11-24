defmodule RAML.Parser do
  alias RAML.{Root, Resource, Method, Response}

  def parse(path) do
    enforce_raml_comment(path)

    path
    |> read_yaml
    |> parse_root
  end

  defp enforce_raml_comment(path) do
    unless File.open!(path, fn io -> IO.read(io, 10) end) == "#%RAML 1.0" do
      raise "Not a valid RAML 1.0 file:  #{path}"
    end
  end

  defp read_yaml(path) do
    :yamerl_constr.file(path)
    |> case do
         [yaml_document] ->
           yaml_document
         _parsed ->
           raise "Expected one YAML document"
       end
  end

  defp parse_root(yaml_document) do
    {'title', title} = Enum.find(yaml_document, &match?({'title', _title}, &1))
    %Root{
      title: to_string(title),
      resources: parse_resources(yaml_document),
      version: parse_optional_string(:version, yaml_document),
      description: parse_optional_string(:description, yaml_document),
      base_uri: parse_optional_string(:baseUri, yaml_document),
      media_type: parse_optional_string(:mediaType, yaml_document)
    }
  end

  defp parse_resources(yaml_document) do
    yaml_document
    |> Enum.filter(&match?({[?/ | _path], _resource}, &1))
    |> Enum.map(&parse_resource/1)
  end

  defp parse_resource({path, properties}) do
    methods =
      properties
      |> Enum.filter(fn {name, _property} ->
        name in ~w[get patch put post delete options head]c
      end)
      |> Enum.into(Map.new, fn {verb, properties} ->
        {String.to_atom(to_string(verb)), parse_method(properties)}
      end)
    %Resource{
      path: to_string(path),
      methods: methods
    }
  end

  defp parse_method(properties) do
    responses =
      properties
      |> Enum.find({'responses', %{ }}, &match?({'responses', _responses}, &1))
      |> elem(1)
      |> parse_responses
    %Method{responses: responses}
  end

  defp parse_responses(all_properties) do
    Enum.into(all_properties, Map.new, fn {status_code, properties} ->
      {to_string(status_code), parse_response(properties)}
    end)
  end

  defp parse_response(properties) do
    %Response{
    }
  end

  defp parse_optional_string(name, yaml) do
    charlist_name = to_charlist(name)
    case Enum.find(yaml, &match?({^charlist_name, _}, &1)) do
      {^charlist_name, result} ->
        to_string(result)
      nil ->
        nil
    end
  end
end
