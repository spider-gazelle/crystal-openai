require "../src/openai"

unless OpenAI::API_KEY || OpenAI::API_KEY_PATH
  puts "Make sure you have set OPENAI_API_KEY environment variable"
  exit(1)
end

client = OpenAI::Client.new

resp = client.completion(OpenAI::CompletionRequest.new(
  model: OpenAI::GPT3Ada,
  max_tokens: 7,
  prompt: "Say this is a test"
))

resp.choices.each do |c|
  puts c.text
end
