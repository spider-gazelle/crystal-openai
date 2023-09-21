require "json"
require "webmock"
require "./spec_helper"

module OpenAI
  describe "OpenAI::ChatCompletion" do
    it "should raise when attempting chat completion with wrong model" do
      config = Client::Config.new(TEST_SECRET, "http://localhost/v1")
      client = Client.new(config)
      req = ChatCompletionRequest.new("ada", [ChatMessage.new(:user, "Hello")])
      req.max_tokens = 5
      expect_raises(OpenAIError, "model 'ada' is not supported with this method, please use `#completion` method instead") do
        client.chat_completion(req)
      end
    end
    it "should raise when attempting chat completion with streaming enabled" do
      config = Client::Config.new(TEST_SECRET, "http://localhost/v1")
      client = Client.new(config)
      req = ChatCompletionRequest.new("ada", [ChatMessage.new(:user, "Hello")])
      req.stream = true
      expect_raises(OpenAIError, "streaming is not supported with this method, please use `#chat_completion_stream`") do
        client.chat_completion(req)
      end
    end

    it "should return valid chat completion response" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:post, "#{OPENAI_API_DEFUALT_URL}/chat/completions")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: CHAT_COMPLETION_RES)

        req = ChatCompletionRequest.from_json(CHAT_COMPLETION_REQ)
        res = client.chat_completion(req)
        res.id.should eq("chatcmpl-123")
        res.choices.size.should eq(1)
      end
    end

    it "test chat completion functions" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:post, "#{OPENAI_API_DEFUALT_URL}/chat/completions")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return do |req|
            cr = ChatCompletionRequest.from_json(req.body.try &.gets_to_end || "")
            cr.functions.should_not be_nil
            cr.functions.try &.size.should eq(1)
            fd = cr.functions.try &.first
            fd.should_not be_nil
            fd.try &.parameters.to_json.should eq(JSON.parse(CHAT_COMPLETION_FUNC_PARAM).to_json)
            HTTP::Client::Response.new(200, body: CHAT_COMPLETION_RES)
          end

        req = ChatCompletionRequest.new(GPT3Dot5Turbo0613, [ChatMessage.new(:user, "Hello")])
        req.max_tokens = 5
        req.functions = [ChatFunction.new("test", JSON.parse(CHAT_COMPLETION_FUNC_PARAM))]
        client.chat_completion(req)
      end
    end

    it "test chat completion function with test struct" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:post, "#{OPENAI_API_DEFUALT_URL}/chat/completions")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return do |req|
            cr = ChatCompletionRequest.from_json(req.body.try &.gets_to_end || "")
            cr.functions.should_not be_nil
            cr.functions.try &.size.should eq(1)
            fd = cr.functions.try &.first
            fd.should_not be_nil
            fd.try &.parameters.to_json.should eq(TestMessage.json_schema.to_json)
            HTTP::Client::Response.new(200, body: CHAT_COMPLETION_RES)
          end

        req = ChatCompletionRequest.new(GPT3Dot5Turbo0613, [ChatMessage.new(:user, "Hello")])
        req.max_tokens = 5
        req.functions = [ChatFunction.new("test", JSON.parse(TestMessage.json_schema.to_json))]
        client.chat_completion(req)
      end
    end

    it "should return valid chat completion response on azure calls" do
      client = Client.azure(TEST_SECRET, AZURE_SAMPLE_EP)
      WebMock.wrap do
        WebMock.stub(:post, "#{AZURE_SAMPLE_EP}/openai/deployments/gpt-35-turbo/chat/completions?api-version=2023-05-15")
          .with(headers: {"api-key" => TEST_SECRET})
          .to_return(body: CHAT_COMPLETION_RES)

        req = ChatCompletionRequest.from_json(CHAT_COMPLETION_REQ)
        res = client.chat_completion(req)
        res.id.should eq("chatcmpl-123")
        res.choices.size.should eq(1)
      end
    end

    describe "streaming" do
      it "should raise when attempting chat completion streaming with wrong model" do
        config = Client::Config.new(TEST_SECRET, "http://localhost/v1")
        client = Client.new(config)
        req = ChatCompletionRequest.new("ada", [ChatMessage.new(:user, "Hello")])
        req.max_tokens = 5
        expect_raises(OpenAIError, "model 'ada' is not supported with this method, please use `#completion` method instead") do
          client.chat_completion_stream(req)
        end
      end

      it "test chat completion streaming" do
        client = Client.new(TEST_SECRET)
        expected_resp = [
          ChatCompletionStreamResponse.from_json(<<-JSON
            {"id":"1","object":"completion","created":1694883972,"model":"gpt-3.5-turbo","choices":[{"index":0,"delta":{"content":"response1"},"finish_reason":"length"}]}
            JSON
          ),
          ChatCompletionStreamResponse.from_json(<<-JSON
          {"id":"2","object":"completion","created":1694883979,"model":"gpt-3.5-turbo","choices":[{"index":0,"delta":{"content":"response2"},"finish_reason":"stop"}]}
        JSON
          ),
        ]
        WebMock.wrap do
          WebMock.stub(:post, "#{OPENAI_API_DEFUALT_URL}/chat/completions")
            .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
            .to_return do |req|
              headers = HTTP::Headers.new.merge!({"Content-Type" => "text/event-stream"})

              cr = ChatCompletionRequest.from_json(req.body.try &.gets_to_end || "")
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

          req = ChatCompletionRequest.new(GPT3Dot5Turbo, [ChatMessage.new(:user, "Hello")])
          req.max_tokens = 5
          req.stream = true

          stream = client.chat_completion_stream(req)
          expected_resp.each do |exp|
            res = stream.next
            res.should eq(exp)
          end
        end
      end

      it "test chat completion streaming error without data prefix" do
        client = Client.new(TEST_SECRET)
        WebMock.wrap do
          WebMock.stub(:post, "#{OPENAI_API_DEFUALT_URL}/chat/completions")
            .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
            .to_return do |req|
              headers = HTTP::Headers.new.merge!({"Content-Type" => "text/event-stream"})

              cr = ChatCompletionRequest.from_json(req.body.try &.gets_to_end || "")
              cr.stream.should be_true

              HTTP::Client::Response.new(200, body: CHAT_COMPLETION_STREAM_ERROR + "\n", headers: headers)
            end

          req = ChatCompletionRequest.new(GPT3Dot5Turbo, [ChatMessage.new(:user, "Hello")])
          req.max_tokens = 5
          req.stream = true

          stream = client.chat_completion_stream(req)
          expect_raises(OpenAIError, "Incorrect API key provided") do
            stream.next
          end
        end
      end

      it "test chat completion streaming error with data prefix" do
        client = Client.new(TEST_SECRET)
        WebMock.wrap do
          WebMock.stub(:post, "#{OPENAI_API_DEFUALT_URL}/chat/completions")
            .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
            .to_return do |req|
              headers = HTTP::Headers.new.merge!({"Content-Type" => "text/event-stream"})

              cr = ChatCompletionRequest.from_json(req.body.try &.gets_to_end || "")
              cr.stream.should be_true
              data = String.build do |str|
                str << "data: " << <<-J
                    {"error":{"message":"The server had an error while processing your request. Sorry about that!", "type":"server_ error", "param":null,"code":null}}
                    J
                str << "\n\ndata: [DONE]\n\n"
              end
              HTTP::Client::Response.new(200, body: data, headers: headers)
            end

          req = ChatCompletionRequest.new(GPT3Dot5Turbo, [ChatMessage.new(:user, "Hello")])
          req.max_tokens = 5
          req.stream = true

          stream = client.chat_completion_stream(req)
          expect_raises(OpenAIError, "The server had an error") do
            stream.next
          end
        end
      end

      it "test chat completion streaming rate limit error" do
        client = Client.new(TEST_SECRET)
        WebMock.wrap do
          WebMock.stub(:post, "#{OPENAI_API_DEFUALT_URL}/chat/completions")
            .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
            .to_return do |req|
              headers = HTTP::Headers.new.merge!({"Content-Type" => "text/event-stream"})

              cr = ChatCompletionRequest.from_json(req.body.try &.gets_to_end || "")
              cr.stream.should be_true

              HTTP::Client::Response.new(200, body: CHAT_COMPLETION_RATELIMIT_ERROR + "\n", headers: headers)
            end

          req = ChatCompletionRequest.new(GPT3Dot5Turbo, [ChatMessage.new(:user, "Hello")])
          req.max_tokens = 5
          req.stream = true

          stream = client.chat_completion_stream(req)
          expect_raises(OpenAIError, "sending requests too quickly") do
            stream.next
          end
        end
      end

      it "test azure chat completion rate limit error" do
        code = 429
        err_message = "Requests to the Creates a completion for the chat message Operation under Azure OpenAI API \
                   version 2023-03-15-preview have exceeded token rate limit of your current OpenAI S0 pricing tier. \
                   Please retry after 20 seconds. \
                   Please go here: https://aka.ms/oai/quotaincrease if you would like to further increase the default rate limit."

        client = Client.azure(TEST_SECRET, AZURE_SAMPLE_EP)
        WebMock.wrap do
          WebMock.stub(:post, "#{AZURE_SAMPLE_EP}/openai/deployments/gpt-35-turbo/chat/completions?api-version=2023-05-15")
            .with(headers: {"api-key" => TEST_SECRET})
            .to_return do |req|
              headers = HTTP::Headers.new.merge!({"Content-Type" => "application/json"})

              cr = ChatCompletionRequest.from_json(req.body.try &.gets_to_end || "")
              cr.stream.should be_true
              data = String.build do |str|
                str << <<-J
                {"error": { "code": "#{code}", "message": "#{err_message}"}}
                J
              end
              HTTP::Client::Response.new(429, body: data, headers: headers)
            end

          req = ChatCompletionRequest.new(GPT3Dot5Turbo, [ChatMessage.new(:user, "Hello")])
          req.max_tokens = 5
          req.stream = true

          begin
            client.chat_completion_stream(req)
          rescue ex : APIError
            ex.code.should eq(code)
            ex.api_error.should eq(err_message)
          end
        end
      end
    end
  end
end
