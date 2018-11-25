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

When using RAML we begin by describing the API we want to build in 
RAML syntax.  Here's the file for our API:

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

We won't explain this line by line, but it's worth noticing a few things:

* The two actions we're building are outlined towards the bottom 
  in `/redirects` and `/r/{name}`.  These actions detail what HTTP verbs
  can be used to reach the action, what needs to be passed in, and
  you can expect in response.
* Most of this file—the `types` section and later references to 
  the same—explains what we expect to be receiving and returning from our API.
  These specifications can be used to validate what the API consumes and
  produces.
* Some types even include an `example`.  This comes in very handy before 
  we've provided actual code for the actions, since the API can use it to
  sample responses.

Once we have a file roughed out, it's time to turn this thing on.

### Step 2:  Play With Your Not-Yet-Finished API 

Let's turn our shiny new RAML file into a running API.  Clone this library
into a directory and build a fresh Elixir application in the same place.
The following Unix shell commands (or equivalent instructions for your 
platform) should do the trick:

```bash
$ git clone git@github.com:spawnfest/raml_ama_ding_dong.git
…
$ mix new raml_redirects --sup
…
$ cd raml_redirects/
$ mix deps.get
…
```

We need to point the library at our RAML file, so add the following line
to `config/config.ex`:

```Elixir
config :raml_ama_ding_dong, raml_path: "priv/raml_redirects.raml"
```

Of course, there's no file actually there yet.  Let's copy the example 
out of the library's source and place it where we said it would be:

```bash
$ mkdir priv
$ cp ../raml_ama_ding_dong/test/support/fixtures/raml_redirects.raml priv/
```

That's enough setup.  Let's play with this thing already.  Start the
server with the following command:

```bash
$ mix run --no-halt
```

Now, in a different shell, let's use a command like `curl` to simulate 
a couple of requests to the API:

```bash
$ curl -H 'content-type: application/json' 'localhost:4001/hello'
{"message": "Hello World"}
```

Notice how the RAML file was used to determine which URLs to support?  
The server even returned an example response, since we haven't provided
the actual code yet.  We're up and running!

### Step 3:  Implement Actions



### Step 4:  Next Steps

Obviously, we couldn't support the full RAML specification in two days time. 
What we have so far is definitely a useful subset, but there's plenty more 
to do.  We would eventually love to:

* Support the rest of the specification!
* Generate matching client code from a RAML file.
* Provide tools to ensure that a response validates in automated server tests
  and that request validate in automated client tests.
  
Thanks for taking the time to look at our code.
