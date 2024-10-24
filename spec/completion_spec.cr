require "json"
require "webmock"
require "./spec_helper"

module OpenAI
  describe "OpenAI::Completion" do
    it "should raise when attempting completion with wrong model" do
      config = Client::Config.new(TEST_SECRET, "http://localhost/v1")
      client = Client.new(config)
      req = CompletionRequest.new(GPT3Dot5Turbo, max_tokens: 5)
      expect_raises(OpenAIError, "is not supported with this method, please use `#chat_completion` method instead") do
        client.completion(req)
      end
    end
    it "should raise when attempting completion with streaming enabled" do
      config = Client::Config.new(TEST_SECRET, "http://localhost/v1")
      client = Client.new(config)
      req = CompletionRequest.new(model: GPT3Dot5Turbo, stream: true)
      expect_raises(OpenAIError, "streaming is not supported with this method, please use `#completion_stream`") do
        client.completion(req)
      end
    end

    it "should return valid completion response" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:post, "#{OPENAI_API_DEFAULT_URL}/completions")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: COMPLETION_RES)

        req = CompletionRequest.new("text-davinci-003", prompt: "Say this is a test", max_tokens: 7, temperature: 0.0)
        res = client.completion(req)
        res.id.should eq("cmpl-uqkvlQyYK7bGYrRHQ0eXlWi7")
        res.choices.size.should eq(1)
      end
    end

    describe "streaming" do
      it "should raise when attempting completion streaming with wrong model" do
        config = Client::Config.new(TEST_SECRET, "http://localhost/v1")
        client = Client.new(config)
        req = CompletionRequest.new(GPT3Dot5Turbo)
        req.max_tokens = 5
        expect_raises(OpenAIError, "is not supported with this method, please use `#chat_completion` method instead") do
          client.completion_stream(req)
        end
      end

      it "test completion streaming" do
        client = Client.new(TEST_SECRET)
        expected_resp = [
          CompletionResponse.from_json(<<-JSON
            {"id":"1","object":"completion","created":1694883972,"model":"text-davinci-002","choices":[{"index": 0, "text":"response1","finish_reason":"length"}]}
            JSON
          ),
          CompletionResponse.from_json(<<-JSON
          {"id":"2","object":"completion","created":1694883979,"model":"text-davinci-002","choices":[{"index": 1, "text":"response2","finish_reason":"stop"}]}
        JSON
          ),
        ]
        WebMock.wrap do
          WebMock.stub(:post, "#{OPENAI_API_DEFAULT_URL}/completions")
            .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
            .to_return do |req|
              headers = HTTP::Headers.new.merge!({"Content-Type" => "text/event-stream"})

              cr = CompletionRequest.from_json(req.body.try &.gets_to_end || "")
              cr.stream.should be_true

              data = String.build do |str|
                str << "event: message\n"
                str << "data: #{expected_resp.first.to_json}"

                str << "\n\n"
                str << "event: message\n"
                str << "data: #{expected_resp[1].to_json}"
                str << "\n\n"
                str << "event: done\n"
                str << "data: [DONE]\n\n"
              end
              HTTP::Client::Response.new(200, body: data, headers: headers)
            end

          req = CompletionRequest.new("text-davinci-002", max_tokens: 10, stream: true)

          stream = client.completion_stream(req)
          expected_resp.each do |exp|
            res = stream.next
            res.should eq(exp)
          end
        end
      end

      it "test completion streaming error without data prefix" do
        client = Client.new(TEST_SECRET)
        WebMock.wrap do
          WebMock.stub(:post, "#{OPENAI_API_DEFAULT_URL}/completions")
            .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
            .to_return do |req|
              headers = HTTP::Headers.new.merge!({"Content-Type" => "text/event-stream"})

              cr = CompletionRequest.from_json(req.body.try &.gets_to_end || "")
              cr.stream.should be_true

              HTTP::Client::Response.new(200, body: CHAT_COMPLETION_STREAM_ERROR + "\n", headers: headers)
            end

          req = CompletionRequest.new(GPT3Ada)
          req.max_tokens = 5
          req.stream = true

          stream = client.completion_stream(req)
          expect_raises(OpenAIError, "Incorrect API key provided") do
            stream.next
          end
        end
      end

      it "test chat completion streaming error with data prefix" do
        client = Client.new(TEST_SECRET)
        WebMock.wrap do
          WebMock.stub(:post, "#{OPENAI_API_DEFAULT_URL}/completions")
            .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
            .to_return do |req|
              headers = HTTP::Headers.new.merge!({"Content-Type" => "text/event-stream"})

              cr = CompletionRequest.from_json(req.body.try &.gets_to_end || "")
              cr.stream.should be_true
              data = String.build do |str|
                str << "data: " << <<-J
                    {"error":{"message":"The server had an error while processing your request. Sorry about that!", "type":"server_ error", "param":null,"code":null}}
                    J
                str << "\n\ndata: [DONE]\n\n"
              end
              HTTP::Client::Response.new(200, body: data, headers: headers)
            end

          req = CompletionRequest.new(GPT3Ada)
          req.max_tokens = 5
          req.stream = true

          stream = client.completion_stream(req)
          expect_raises(OpenAIError, "The server had an error") do
            stream.next
          end
        end
      end

      it "test completion streaming rate limit error" do
        client = Client.new(TEST_SECRET)
        WebMock.wrap do
          WebMock.stub(:post, "#{OPENAI_API_DEFAULT_URL}/completions")
            .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
            .to_return do |req|
              headers = HTTP::Headers.new.merge!({"Content-Type" => "text/event-stream"})

              cr = CompletionRequest.from_json(req.body.try &.gets_to_end || "")
              cr.stream.should be_true

              HTTP::Client::Response.new(200, body: CHAT_COMPLETION_RATELIMIT_ERROR + "\n", headers: headers)
            end

          req = CompletionRequest.new(GPT3Ada, max_tokens: 5, stream: true)

          stream = client.completion_stream(req)
          expect_raises(OpenAIError, "sending requests too quickly") do
            stream.next
          end
        end
      end

      it "test completion streaming broken json" do
        client = Client.new(TEST_SECRET)
        WebMock.wrap do
          WebMock.stub(:post, "#{OPENAI_API_DEFAULT_URL}/completions")
            .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
            .to_return do |req|
              headers = HTTP::Headers.new.merge!({"Content-Type" => "text/event-stream"})

              cr = CompletionRequest.from_json(req.body.try &.gets_to_end || "")
              cr.stream.should be_true

              data = String.build do |str|
                str << "event: message\n"
                str << "data: " << <<-JSON
                {"id":"1","object":"completion","created":1694883972,"model":"text-davinci-002","choices":[{"index": 0, "text":"response1","finish_reason":"length"}]}
                JSON

                str << "\n\n"
                str << "event: message\n"
                str << "data: " << <<-JSON
                {"id":"1","object":"completion","created":1694883972,"model":
                JSON
                str << "\n\n"
                str << "event: done\n"
                str << "data: [DONE]\n\n"
              end
              HTTP::Client::Response.new(200, body: data, headers: headers)
            end

          req = CompletionRequest.new("text-davinci-002", max_tokens: 10, stream: true)

          stream = client.completion_stream(req)
          stream.next
          expect_raises(OpenAIError, "Unexpected token") do
            stream.next
          end
        end
      end
    end
  end
end
