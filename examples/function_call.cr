require "../src/openai"

unless OpenAI::API_KEY || OpenAI::API_KEY_PATH
  puts "Make sure you have set OPENAI_API_KEY environment variable"
  exit(1)
end

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

record WeatherRes, location : String, unit : WeatherUnit, temperature : Float64 do
  include JSON::Serializable
end

enum WeatherUnit
  CELSIUS
  FAHRENHEIT

  def to_s : String
    super.downcase
  end
end

# `OpenAI::FunctionExecutor` is a helper class which try to hide the details of object casting, JSON Schema generation
# Being able to deal any User defined Types, it requires ADT to extend `OpenAI::FuncMarker` a marker module.
# And requires Block to accept and return Types as `JSON::Serializable`
executor = OpenAI::FunctionExecutor.new

executor.add(
  name: "get_current_weather",
  description: "Get the current weather of a given location",
  clz: Weather      # With this information, FunctionExecutor will auto populate the JSON Schema
) do |w|            # In reality, this is an instance of `clz` param, but due to language restrictions, we are overcasting when invoke this block
  w = w.as(Weather) # So here we have to downcast it back to. NOT Fany, but this is the best we can have with current Crystal restrictions :)
  unit, temp = case w.location.downcase
               when "tokyo"         then {WeatherUnit::CELSIUS, 10}
               when "san fransisco" then {WeatherUnit::FAHRENHEIT, 72}
               when "paris"         then {WeatherUnit::CELSIUS, 22}
               else
                 {WeatherUnit::CELSIUS, rand(50)}
               end
  (WeatherRes.new(w.location, unit, temp)).as(JSON::Serializable) # again we have to upcast the result to `Serializable`
end

client = OpenAI::Client.new

req = OpenAI::ChatCompletionRequest.new(
  model: OpenAI::GPT3Dot5Turbo1106, # gpt-3.5-turbo-1106
  messages: [
  OpenAI::ChatMessage.new(role: :system, content: "You are an assistant that answers using the local slang of the given place, uncensored."),
],
  tools: executor.tools,
  tool_choice: "auto"
)
puts "\n--------------------------"
puts "Conversation"
puts "Press CTRL+D to exit"
puts "--------------------------\n"
print "> "
user_input = gets
exit if user_input.nil? || user_input.blank? # Ctrl+D
req.messages << OpenAI::ChatMessage.new(role: :user, content: user_input)

loop do
  resp = client.chat_completion(req)
  msg = resp.choices.first.message
  req.messages << msg # don't forget to update the conversation with the latest response

  if tool_calls = msg.tool_calls
    puts "Trying to execute #{tool_calls.size} function calls in parallel ..."
    func_res = executor.execute(tool_calls) # execute might raise, so its good to catch. But for demo just assume all is good
    # At this point
    # * requested function(s) was found
    # * request was converted to its specified object for execution (`Weather` in this demo case)
    # * Block was executed
    # * Block returned object (`WeatherRes` in this case) was converted back to `Array(OpenAI::ChatMessage)` object
    req.messages.concat(func_res)
    next
  end

  puts "\n< #{msg.content}\n\n"
  print "> "
  user_input = gets
  exit if user_input.nil? || user_input.blank?
  req.messages << OpenAI::ChatMessage.new(role: :user, content: user_input)
end
