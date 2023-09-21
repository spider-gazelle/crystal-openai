# Crystal OpenAI

Unofficial Crystal language shard for [OpenAI API](https://platform.openai.com/) and **Microsoft Azure Endpoints**. Shard supports: 

- ChatGPT
- GPT-3, GPT-4
- DALL·E 2
- Whisper

## Supported APIs

- [Audio](https://platform.openai.com/docs/api-reference/audio)
- [Chat Completions](https://platform.openai.com/docs/api-reference/chat/create)
- [Completions](https://platform.openai.com/docs/api-reference/completions)
- [Embeddings](https://platform.openai.com/docs/api-reference/embeddings)
- [Fine-tuning](https://platform.openai.com/docs/api-reference/fine-tuning)
- [Files](https://platform.openai.com/docs/api-reference/files)
- [Images](https://platform.openai.com/docs/api-reference/images)
- [Models](https://platform.openai.com/docs/api-reference/models)
- [Moderations](https://platform.openai.com/docs/api-reference/moderations)

#### Deprecated by OpenAI
- [Engines](https://platform.openai.com/docs/api-reference/engines)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     openai:
       github: spider-gazelle/crystal-openai
   ```

2. Run `shards install`

## Usage

```crystal
require "openai"
```

You can configure the environment using the following variables:

* `OPENAI_API_KEY`: API Key. Alternatively, you can configure the following environment variable if you have stored your API key in a Kubernetes secret or some other file storage.
* `OPENAI_API_KEY_PATH` : Path to the file containing the API Key. This is primarily used when you have configured your key via a Kubernetes secret.
* `OPENAI_API_BASE`: Base Endpoint URL of the API. For OpenAI, this will default to the OpenAI official link. For Azure endpoints, you will need to either configure this variable or configure it via code.

> Note: Refer to [constants.cr](src/constants.cr) for more environment configuration variables.

`OpenAI::Client` is the main entry point you will use to invoke OpenAI endpoints.

```crystal
  # If you have set `OPENAI_API_KEY` env var
  client = OpenAI::Client.new

  # If you prefer to configure via code
  client = OpenAI::Client.new(YOUR-OPENAPI-API-KEY)

  # For Azure endpoints
  client = OpenAI::Client.azure(....)
```

> **Note**: **`....`** is not a syntax; it refers to the details that need to be provided before invoking these functions.


### Audio (Whisper)

```crystal
  # transcribe audio into the input language.
  client.transcription(....)

  # translate audio into English.
  client.translation(....)

```

### Chat completions

```crystal
  # Create a completion for the chat message.
  client.chat_completion(....)

  # create a chat completion w/ streaming support. 
  client.chat_completion_stream(....)
```

### Completions

```crystal
    # API call to create a completion. This is the main endpoint of the API. Returns new text as well
    # as, if requested, the probabilities over each alternative token at each position.
    #
    # If using a fine-tuned model, simply provide the model's ID in the CompletionRequest object,
    # and the server will use the model's parameters to generate the completion.
    client.completion(....)

    # create a completion w/ streaming
    client.completion_stream(....)
```

### Embeddings

```crystal
  # Creates an embedding vector representing the input text.
  client.embeddings(.....)
```

### Fine-tuning

```crystal
  # Creates a job that fine-tunes a specified model from a given dataset.
  client.create_fine_tuning_job(....)

  # Get info about a fine-tuning job
  client.get_fine_tuning_job(....)

  # Immediately cancel a fine-tune job.
  client.cancel_fine_tuning_job(....)

  # List your organization's fine-tuning jobs
  client.list_fine_tuning_jobs(....)

  # Get status updates for a fine-tuning job.
  client.list_fine_tuning_events(....)
```

### Files

```crystal
  # Returns a list of files that belong to the user's organization.
  client.list_files

  # Delete file
  client.delete_file(....)

  # Upload file
  client.upload_file(....)

  # Retrieve File object
  client.get_file(....)

  # Retrieve file contents
  client.get_file_contents(....)

```

### Image generation (DALL·E)

```crystal
  # create image given prompt
  client.create_image(....)

  # Creates an edited or extended image given an original image and a prompt.
  client.create_image_edit(....)

  # Creates a variations of a given image.
  client.create_image_variation(....)
```

### Models

```crystal
  # Lists currently available models, and provide basic information
  client.models

  # Retrieves a model instance, providing basic information about the model
  client.model(....)
```

### Moderation

```crystal
  # Performs a moderation api call
  client.moderation(....)
```

### Engines

```crystal
  # Lists the currently available engines
  client.engines

  # Retrieves an engine instance, providing basic information about it
  client.engine(....)
```


### Functions

You can create your functions and define their executors easily using ChatFunction class, along with any of your custom classes that will serve to define their available parameters. You can also process the functions with ease, with the help of an executor called `OpenAI::FunctionExecutor`.

First we declare our function parameters:

```crystal
struct Weather
  extend OpenAI::FuncMarker # This marker module is required if you want to use FunctionExecutor
  include JSON::Serializable

  @[JSON::Field(description: "City and state, for example: San Francisco, CA")]
  getter location : String
  @[JSON::Field(description: "The temperature unit, can be 'celsius' or 'fahrenheit'")]
  getter unit : WeatherUnit

  def initialize(@location, @unit = :fahrenheit)
  end
end

record WeatherRes, location : String, unit : WeatherUnit, temperature : Float64, description : String? do
  include JSON::Serializable
end
```

Next, we declare the function itself and associate it with an executor, in this example we will fake a response from some API:

```crystal
executor = OpenAI::FunctionExecutor.new

executor.add(
  name: "get_weather",
  description: "Get the current weather of a given location",
  clz: Weather
) do |w|
  w = w.as(Weather)
  (WeatherRes.new(w.location, w.unit, rand(50), "sunny")).as(JSON::Serializable)
end

....
```

> Note: You can also create your own function executor. The return object of `ChatFunctionCall.arguments`` is a `JSON::Any` for simplicity and should be able to help you with that.

### Adding a Proxy

To use a proxy, configure below environment variables

- `PROXY_USERNAME`: Proxy User name
- `ROXY_PASSWORD`: Proxy User password
- `HTTP_PROXY`: When using HTTP proxy
- `HTTPS_PROXY`: When using HTTPS proxy
- `PROXY_VERIFY_TLS`: Boolean flag to toggle TLS verification
- `PROXY_DISABLE_CRL_CHECKS`: Boolean flag to toggle OpenSSL X509 Critical extension handling.

Or you can configure Proxy options via code

```crystal
  proxy = OpenAI::Client::ProxyConfig.new(user: xxxx, password: xxxx, proxy_url: xxxxx , proxy_port: xxxx)
  
  # and then when creating client
  config = OpenAI::Client::Config.default(api_key, proxy: proxy)
  client = OpenAI::Client.new(config)

  # or
  client = OpenAI::Client.new(API_KEY, proxy: proxy)

  # or for azure endpoint
  client = OpenAI::Client.azure(API_KEY, AZURE_ENDPOINT, proxy: proxy)
```

### Running examples

All the [examples](examples) requires is your OpenAI api token

```sh
export OPENAI_API_KEY="sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

Refer to `examples` or `specs` folder for sample usage

## Development

> Specs are run using Mock services, and don't require access to OpenAI service.

To run all specs

```crystal
  crystal spec
```

## FAQ
### Does this support GPT-4?
Yes! GPT-4 uses the ChatCompletion Api, and you can see the latest model options [here](https://platform.openai.com/docs/models/gpt-4).  

### Does this support functions?
Absolutely! It is very easy to use your own functions without worrying about doing the dirty work.
As mentioned above, you can refer to [examples/function_call.cr](examples/function_call.cr)

### Why am I getting connection timeouts?
Make sure that OpenAI is available in your country.

## Deprecated Endpoints
OpenAI has deprecated engine-based endpoints in favor of model-based endpoints. 
For example, instead of using `v1/engines/{engine_id}/completions`, switch to `v1/completions` and specify the model in the `CompletionRequest`.

## Contributing

1. Fork it (<https://github.com/spider-gazelle/crystal-openai/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Ali Naqvi](https://github.com/naqvis) - creator and maintainer
