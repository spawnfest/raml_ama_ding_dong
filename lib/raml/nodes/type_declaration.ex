defmodule RAML.Nodes.TypeDeclaration do
  defstruct ~w[
    name default type example examples facets enum

    properties min_properties max_properties additional_properties
    discriminator discriminator_value

    unique_items items min_items max_items

    pattern min_length max_length

    minimum maximum format multiple_of
  ]a
end
