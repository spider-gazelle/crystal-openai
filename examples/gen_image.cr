require "../src/openai"

unless OpenAI::API_KEY || OpenAI::API_KEY_PATH
  puts "Make sure you have set OPENAI_API_KEY environment variable"
  exit(1)
end

client = OpenAI::Client.new

puts "\n--------------------------"
puts "Generates image given the prompt"
puts "--------------------------\n"

print "> "
prompt = gets
exit if prompt.nil? || prompt.try &.blank?

resp = client.create_image(OpenAI::ImageRequest.new(prompt))

puts "\n Generated Image URL\n"
resp.data.each { |d| puts d.url }
