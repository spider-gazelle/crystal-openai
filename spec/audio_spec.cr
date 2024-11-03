require "webmock"
require "./spec_helper"

module OpenAI
  describe "OpenAI::Audio" do
    it "test transcriptions" do
      client = Client.new(TEST_SECRET)
      parts = ["file", "model", "response_format"]
      WebMock.wrap do
        WebMock.stub(:post, "#{OPENAI_API_DEFAULT_URL}/audio/transcriptions")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return do |req|
            HTTP::FormData.parse(req) do |part|
              part.name.in?(parts).should be_true
            end
            HTTP::Client::Response.new(200, body: AUDIO_RES)
          end

        req = TranscriptionRequest.new(AUDIO_SAMPLE)
        res = client.transcription(req)
        res.text.should_not be_nil
      end
    end

    it "test translation" do
      client = Client.new(TEST_SECRET)
      parts = ["file", "model", "response_format"]
      WebMock.wrap do
        WebMock.stub(:post, "#{OPENAI_API_DEFAULT_URL}/audio/translations")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return do |req|
            HTTP::FormData.parse(req) do |part|
              part.name.in?(parts).should be_true
            end
            HTTP::Client::Response.new(200, body: AUDIO_RES)
          end

        req = TranscriptionRequest.new(AUDIO_SAMPLE)
        res = client.translation(req)
        res.text.should_not be_nil
      end
    end
  end
end
