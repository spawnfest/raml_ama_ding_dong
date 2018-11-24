defmodule RAML.Nodes.TypeDeclaration do
  defstruct ~w[
    name default type example examples facets enum
    properties min_properties max_properties additional_properties
    discriminator discriminator_value
  ]a
end
