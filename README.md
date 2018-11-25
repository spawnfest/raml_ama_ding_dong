# RAML (ama ding dong)

[RAML](https://raml.org/)—**R**ESTful **A**PI **M**odeling **L**anguage—is a
tool for planning APIs, quickly scaffolding those plans for experimentation, 
validating parameters and responses for your API, testing what you've built 
without actually making requests, and more.  This (incomplete) Elixir 
implementation is intended to show off its utility.

## How do I use this thing?

The best way to learn a little about RAML is to use it to build something.
This example will walk you through the construction of a two-action API for 
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
    pattern: '^[-a-zA-Z0-9_]+$'
  URL:
    type: string
    pattern: '^\S+$'
    example: http://example.com/
  Redirect:
    properties:
      name: Name
      url: URL
  ShortURL:
    properties:
      shortened: URL
    example: 
      value: |
        {"shortened": "http://localhost:4001/r/example"}
      strict: false
/redirects:
  put:
    queryString: 
      type: Redirect
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
```

We need to add the RAML library to our project as a dependency, so 
insert the following line into the end of the `deps` list in `mix.exs`:

```Elixir
      {:raml_ama_ding_dong, path: "../raml_ama_ding_dong"}
```

Now fetch the project's dependencies:

```bash
$ mix deps.get
…
```

We need to point the library at our RAML file, so add the following line
to `config/config.exs`:

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
$ curl -H 'content-type: application/json' 'localhost:4001/not_an_action'
Not Found
$ curl -H 'content-type: application/json' 'localhost:4001/redirects'
Method Not Allowed
$ curl -X PUT -H 'content-type: application/json' 'localhost:4001/redirects'
{"shortened": "http://localhost:4001/r/example"}
```

Notice how the RAML file was used to determine which URLs to support?  
The server even returned an example response, since we haven't provided
the actual code yet.  We're up and running!

### Step 3:  Implement Actions

A scaffolded API is useful for early exploration, but eventually we're going
to want our API to run some real code.  Let's move on to looking at how our
own code gets wired in.

First, let's add a module in `lib/raml_redirects/url_table.ex` that can
remember and fetch named URLs for later use.  This is the business logic
for our trivial system, unrelated to RAML or APIs:

```Elixir
defmodule RamlRedirects.UrlTable do
  use Agent

  def start_link(_options) do
    Agent.start_link(fn ->
      :ets.new(:url_lookup_table, ~w[set public named_table]a)
    end)
  end

  def set_redirect(name, url) do
    :ets.insert(:url_lookup_table, {name, url})
  end

  def get_redirect(name) do
    case :ets.lookup(:url_lookup_table, name) do
      [{^name, url}] ->
        url
      [ ] ->
        nil
    end
  end
end
```

That module needs to be started with our application, so add the following line
at the end of the list of `children` in `lib/raml_redirects/application.ex`:

```Elixir
      RamlRedirects.UrlTable
```

We can now make use of that service to store and retrieve URLs as the endpoints
of our API are exercised.  We just need to define a callback module to handle
the various types of requests and the scaffolded API will automatically switch 
over to using our real implementation.  Drop this code into 
`lib/raml_redirects/api.ex`:

```Elixir
defmodule RamlRedirects.Api do
  alias RamlRedirects.UrlTable

  def call("/redirects", :put, request) do
    name = Map.fetch!(request.params, "name")
    UrlTable.set_redirect(name, Map.fetch!(request.params, "url"))
    {200, Map.new, %{"shortened" => "http://localhost:4001/r/#{name}"}}
  end

  def call("/r/{name}", :get, request) do
    case UrlTable.get_redirect(Map.fetch!(request.params, "name")) do
      url when is_binary(url) ->
        {302, %{"Location" => url}, ""}
      nil ->
        {404, Map.new, "Not found\n"}
    end
  end
end
```

Of course, we need to tell the RAML code how to find this module, so add 
one more line to the end of the `config/config.exs`:

```Elixir
config :raml_ama_ding_dong, processing_module: RamlRedirects.Api
```

Now we can talk to our fully functional API.  Let's save a shortened URL, 
then show the redirect to that location:

```bash
$ curl -X PUT -H 'content-type: application/json' 'localhost:4001/redirects?name=ex&url=http://example.com'
{"shortened":"http://localhost:4001/r/ex"}
$ curl -i -H 'co ntent-type: application/json' 'localhost:4001/r/ex'
HTTP/1.1 302 Found
Location: http://example.com
cache-control: max-age=0, private, must-revalidate
content-length: 3
date: Sun, 25 Nov 2018 22:57:52 GMT
server: Cowboy

""
```

Asking for a redirect that isn't in the system gets us a 404:

```bash
$ curl -s -i -H 'content-type: application/json' 'localhost:4001/r/not_a_thing' | head -n 1
HTTP/1.1 404 Not Found
```

We may be done with the API scaffolding, but RAML is still doing some work 
for us.  For example, it's validating the params being passed to our actions.
If we try to save a URL under an invalid name, we'll receive an error even 
though we didn't write any parameter checking code:

```bash
$ curl -X PUT -H 'content-type: application/json' 'localhost:4001/redirects?name=not+allowed&url=http://example.com'
FIXME
```

Handy, right?

### Step 4:  Next Steps

Obviously, we couldn't support the full RAML specification in two days time. 
What we have so far is definitely a useful subset, but there's plenty more 
to do.  We would eventually love to:

* Support the rest of the specification!
* Provide more tools for building API code, leveraging the RAML specification 
  when possible.  For example, it would be nice to have a `link()` helper 
  function that's aware of `baseUri`.
* Generate matching client code from a RAML file.
* Provide tools to ensure that a response validates in automated server tests
  and that request validate in automated client tests.
  
Thanks for taking the time to look at our code.
