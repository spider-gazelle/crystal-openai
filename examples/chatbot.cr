require "../src/openai"

unless OpenAI::API_KEY || OpenAI::API_KEY_PATH
  puts "Make sure you have set OPENAI_API_KEY environment variable"
  exit(1)
end

client = OpenAI::Client.new

req = OpenAI::ChatCompletionRequest.new(
  model: OpenAI::GPT3Dot5Turbo, # gpt-3.5-turbo
  messages: [
  OpenAI::ChatMessage.new(role: :system, content: "You are a helpful chatbot"),
] # .... Other Chat completion request settings
)

puts "\n--------------------------"
puts "Conversation"
puts "Press CTRL+D to exit"
puts "--------------------------\n"
loop do
  print "> "
  user_input = gets
  exit if user_input.nil? # Ctrl+D

  req.messages << OpenAI::ChatMessage.new(role: :user, content: user_input)

  resp = client.chat_completion(req)
  msg = resp.choices.first.message
  puts "\n< #{msg.content}\n\n"
  req.messages << msg
end
