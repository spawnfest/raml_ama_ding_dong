defmodule RAML.Parser do
  alias RAML.Nodes.{
    Root, Resource, Method, Response, Body, TypeDeclaration, Example
  }

  def parse(path) do
    enforce_raml_comment(path)

    path
    |> read_yaml
    |> convert_null_to_nil
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

  defp convert_null_to_nil(yaml) when is_list(yaml) do
    Enum.map(yaml, fn item -> convert_null_to_nil(item) end)
  end
  defp convert_null_to_nil(yaml) when is_tuple(yaml) do
    yaml
    |> Tuple.to_list
    |> Enum.map(fn item -> convert_null_to_nil(item) end)
    |> List.to_tuple
  end
  defp convert_null_to_nil(:null), do: nil
  defp convert_null_to_nil(yaml), do: yaml

  defp parse_root(yaml_document) do
    {'title', title} = Enum.find(yaml_document, &match?({'title', _title}, &1))
    types = parse_optional(yaml_document, :types, &parse_types/1)
    %Root{
      title: to_string(title),
      types: types,
      resources: parse_resources(yaml_document),
      version: parse_optional_string(yaml_document, :version),
      base_uri: parse_optional_string(yaml_document, :baseUri),
      media_type: parse_optional_list_of_strings(yaml_document, :mediaType)
    }
  end

  defp parse_types(named_types) do
    Enum.map(named_types, &parse_named_type/1)
  end

  defp parse_named_type({name, properties}) do
    case parse_type(properties) do
      %TypeDeclaration{ } = type ->
        %TypeDeclaration{type | name: to_string(name)}
      bare_type ->
        %TypeDeclaration{name: to_string(name), type: bare_type}
    end
  end

  defp parse_type(built_in)
  when built_in in ~w[
    any object array number boolean string
    date-only time-only datetime-only datetime file integer nil
  ]c do
    to_string(built_in)
  end
  defp parse_type(inline) when inline == [ ] or inline |> hd |> is_tuple do
    parse_type_declaration(inline)
  end
  defp parse_type(union_or_user_defined) do
    type = to_string(union_or_user_defined)
    case String.split(type, ~r{\s*\|\s*}) do
      [user_defined] ->
        user_defined
      union ->
        union
    end
  end

  defp parse_type_declaration(properties) do
    facets =
      properties
      |> Enum.find({'facets', []}, &match?({'facets', _facets}, &1))
      |> elem(1)
      |> Enum.into(Map.new, fn {name, details} ->
        {to_string(name), details}
      end)
    %TypeDeclaration{
      default: parse_optional(properties, :default),
      type: parse_optional(properties, :type, &parse_type/1),
      facets: facets,
      enum: parse_optional(properties, :enum)
    }
    |> add_parsed_object_facets(properties)
    |> add_parsed_array_facets(properties)
    |> add_parsed_string_facets(properties)
    |> add_parsed_number_facets(properties)
    |> add_parsed_file_facets(properties)
    |> attach_parsed_examples(properties)
  end

  defp add_parsed_object_facets(object, properties) do
    Map.merge(
      object,
      %{
        properties: parse_property_list(properties, :properties),
        min_properties: parse_optional(properties, :minProperties),
        max_properties: parse_optional(properties, :maxProperties),
        additional_properties: parse_optional(properties, :additionalProperties),
        discriminator: parse_optional_string(properties, :discriminator),
        discriminator_value:
          parse_optional_string(properties, :discriminatorValue)
      }
    )
  end

  defp parse_property_list(properties, name) do
    charlist_name = to_charlist(name)
    properties
    |> Kernel.||([ ])
    |> Enum.find({charlist_name, []}, &match?({^charlist_name, _properties}, &1))
    |> elem(1)
    |> Enum.into(Map.new, fn {name, type} ->
      {name_suffix, raw_type} = parse_property_declaration(type)
      {to_string(name) <> name_suffix, parse_type(raw_type)}
    end)
  end

  defp parse_property_declaration(properties) do
    is_prop_declaration? =
      properties
      |> Enum.map(fn {name, _property} -> name; item -> item end)
      |> Enum.sort
      |> Kernel.in([['type'], ['required', 'type']])
    if is_prop_declaration? do
      {'type', type} = Enum.find(properties, &match?({'type', _type}, &1))
      required = parse_optional(properties, :required)
      {(if required != false, do: "?", else: ""), type}
    else
      {"", properties}
    end
  end

  defp add_parsed_array_facets(array, properties) do
    Map.merge(
      array,
      %{
        unique_items: parse_optional(properties, :uniqueItems),
        items: parse_optional(properties, :items),
        min_items: parse_optional(properties, :minItems),
        max_items: parse_optional(properties, :maxItems)
      }
    )
  end

  defp add_parsed_string_facets(string, properties) do
    Map.merge(
      string,
      %{
        pattern: parse_optional_string(properties, :pattern),
        min_length: parse_optional(properties, :minLength),
        max_length: parse_optional(properties, :maxLength)
      }
    )
  end

  defp add_parsed_number_facets(number, properties) do
    Map.merge(
      number,
      %{
        minimum: parse_optional(properties, :minimum),
        maximum: parse_optional(properties, :maximum),
        format: parse_optional_string(properties, :format),
        multiple_of: parse_optional(properties, :multipleOf)
      }
    )
  end

  defp add_parsed_file_facets(file, properties) do
    Map.put(file, :multiple_of, parse_optional(properties, :multipleOf))
  end

  defp attach_parsed_examples(attachable, properties) do
    case parse_optional(properties, :examples) do
      examples when is_list(examples) ->
        Map.put(
          attachable,
          :examples,
          Enum.into(examples, Map.new, fn {name, example} ->
            {to_string(name), parse_example(example)}
          end)
        )
      nil ->
        Map.put(
          attachable,
          :example,
          parse_optional(properties, :example, &parse_example/1)
        )
    end
  end

  defp parse_example(properties) do
    case Enum.find(properties, &match?({'value', _value}, &1)) do
      {'value', value} ->
        strict = parse_optional(properties, :strict)
        %Example{
          value: value,
          strict: (if is_boolean(strict), do: strict, else: true)
        }
      nil ->
        %Example{value: properties}
    end
  end

  defp parse_resources(yaml_document) do
    yaml_document
    |> Kernel.||([ ])
    |> Enum.filter(&match?({[?/ | _path], _resource}, &1))
    |> Enum.map(&parse_resource/1)
  end

  defp parse_resource({path, properties}) do
    methods =
      properties
      |> Kernel.||([ ])
      |> Enum.filter(fn {name, _property} ->
        name in ~w[get patch put post delete options head]c
      end)
      |> Enum.into(Map.new, fn {verb, properties} ->
        {String.to_atom(to_string(verb)), parse_method(properties)}
      end)
    %Resource{
      path: to_string(path),
      uri_parameters: parse_property_list(properties, :uriParameters),
      methods: methods,
      resources: parse_resources(properties)
    }
  end

  defp parse_method(properties) do
    responses =
      properties
      |> Enum.find({'responses', %{ }}, &match?({'responses', _responses}, &1))
      |> elem(1)
      |> parse_responses
    %Method{
      headers: parse_property_list(properties, :headers),
      responses: responses
    }
    |> attach_parsed_query(properties)
  end

  defp attach_parsed_query(attachable, properties) do
    case parse_property_list(properties, :query_parameters) do
      query when is_map(query) and map_size(query) > 0 ->
        Map.put(attachable, :query_parameters, query)
      %{ } ->
        Map.put(
          attachable,
          :query_string,
          parse_optional(properties, :queryString, &parse_type/1)
        )
    end
  end

  defp parse_responses(all_properties) do
    Enum.into(all_properties, Map.new, fn {status_code, properties} ->
      {to_string(status_code), parse_response(properties)}
    end)
  end

  defp parse_response(properties) do
    {'body', body} =
      Enum.find(properties, {'body', [ ]}, &match?({'body', _body}, &1))
    %Response{
      headers: parse_property_list(properties, :headers),
      body: parse_body(body)
    }
  end

  defp parse_body(properties) do
    has_media_types? = Enum.any?(properties, fn
      {name, _property} ->
        ?/ in name
      _char ->
        false
    end)
    if has_media_types? do
      media_types =
        Enum.into(properties, Map.new, fn {media_type, type} ->
          {to_string(media_type), parse_type_declaration(type)}
        end)
      %Body{media_types: media_types}
    else
      parse_type_declaration(properties)
    end
  end

  defp parse_optional(properties, name, parser \\ fn term -> term end) do
    charlist_name = to_charlist(name)
    case Enum.find(properties, &match?({^charlist_name, _}, &1)) do
      {^charlist_name, body} ->
        parser.(body)
      nil ->
        nil
    end
  end

  defp parse_optional_string(properties, name) do
    parse_optional(properties, name, &to_string/1)
  end

  defp parse_optional_list_of_strings(properties, name) do
    parse_optional(properties, name, fn
      body when body == [ ] or body |> hd |> is_list ->
        Enum.map(body, &to_string/1)
      body ->
        to_string(body)
    end)
  end
end
