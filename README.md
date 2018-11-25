# RAML (ama ding dong)

[RAML](https://raml.org/)—**R**ESTful **A**PI **M**odeling **L**anguage—is a
tool for planning APIs, quickly scaffolding those plans for experimentation, 
validating parameters and responses for your API, testing what you've built 
without actually making requests, and more.  This (incomplete) Elixir 
implementation is intended to show off its utility.

## How do I use this thing?

The best way to learn a little about RAML is to use it to build something.
This example will walk you through the construction of a two action API for 
creating and using short URL redirects.  This is enough to show much of the
functionality of RAML.

Let's get started.

### Step 1:  Write a RAML Specification

When using RAML we begin by describing the API we want to build in RAML syntax.  Here's the file for our API:

```YAML
#%RAML 1.0
title: RAML Redirects
baseUri: http://localhost:4001
mediaType: application/json
types:
  Name:
    type: string
    pattern: '\A[-a-zA-Z0-9_]+\z'
  URL:
    type: string
    pattern: '\A\S+\z'
    example: http://example.com/
  Redirect:
    properties:
      name: Name
      url: URL
  ShortURL:
    properties:
      shortened: URL
      example:
        shortened: http://localhost:4001/r/example
/redirects:
  put:
    queryString: Redirect
    responses: 
      200:
        body: ShortURL
/r/{name}:
  uriParameters:
    name: Name
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


