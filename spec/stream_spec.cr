require "./spec_helper"

module OpenAI
  describe OpenAI::StreamReader do
    it "test too many empty stream messages" do
      stream = ChatCompletionStream.new(3, IO::Memory.new("\n\n\n\n"))
      expect_raises(OpenAIError, "stream has sent too many empty messages") do
        stream.next
      end
    end
  end
end
