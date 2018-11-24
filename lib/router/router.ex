defmodule Router do
  use RAML.Router

  RAML.Router.build(["route", "another-route"])
end
