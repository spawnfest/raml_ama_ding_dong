defmodule RAML.Parser do
  alias RAML.{Root, Resource}

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
      base_uri: parse_optional_string(:baseUri, yaml_document)
    }
  end

  defp parse_resources(yaml_document) do
    yaml_document
    |> Enum.filter(&match?({[?/ | _path], _resource}, &1))
    |> Enum.map(&parse_resource/1)
  end

  defp parse_resource({path, _properties}) do
    %Resource{
      path: to_string(path)
    }
  end

  defp parse_optional_string(name, yaml) do
    charlist_name = to_charlist(name)
    if (Enum.any?(yaml, &match?({^charlist_name, _}, &1))) do
      {^charlist_name, result} = Enum.find(yaml, &match?({^charlist_name, _}, &1))
      to_string result
    else
      nil
    end
  end
end
