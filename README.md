# RAML (ama ding dong)

[RAML](https://raml.org/)—**R**ESTful **A**PI **M**odeling **L**anguage—is a tool for planning APIs, 
quickly scaffolding those plans for experimentation, validating that an API is
conforming to shared specifications, testing against an API without requiring
access to it, and more.  This (incomplete) Elixir implementation is intended to 
show off its utility.

## How do I use this thing?

### Step 1:  Write a RAML Specification

```YAML
#%RAML 1.0
title: RAML Redirects
baseUri: http://localhost:4001
mediaType: application/json
types:
  Redirect:
    properties:
      name:
        type: string
        pattern: '\A[-a-zA-Z0-9_]+\z'
      url:
        type: string
        pattern: '\A\S+\z'
  Saved:
    properties:
      url: string
      example:
        url: http://localhost:4001/r/example
  URL:
    type: string
    example: http://example.com/
/redirects:
  put:
    queryString: Redirect
    responses: 
      200:
        body: Saved
/r/{name}:
  get:
    responses:
      302:
        headers:
          Location: URL
```

### Step 2:  Play With Your Not-Yet-Finished API 

Let's turn your shiny new RAML file into a running API.  Clone this library
into a directory and build a fresh Elixir application in the same place:

```bash
$ git clone git@github.com:spawnfest/raml_ama_ding_dong.git
…
$ mix new raml_redirects --sup
…
$ cd raml_redirects/
```

```Elixir
config :raml_ama_ding_dong, raml_path: "priv/raml_redirects.raml"
```

```bash
$ mix deps.get
…
$ mkdir priv
$ cp PATH/TO/raml_redirects.raml priv/
$ mix run --no-halt
```

```bash
$ curl localhost:4001/hello
$ curl -H 'content-type: application/json' 'localhost:4001/hello'
{"message": "Hello World"}
```

### Step 3:  Implement Actions

### Step 4:  Next Steps


