require "webmock"
require "./spec_helper"

module OpenAI
  describe "OpenAI::Image" do
    it "test create image" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:post, "#{OPENAI_API_DEFUALT_URL}/images/generations")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: IMAGE_RES)

        res = client.create_image(ImageRequest.new("Lorem Ipsum"))
        res.data.size.should eq(2)
        res.data.first.should_not be_nil
      end
    end

    it "test edit image" do
      client = Client.new(TEST_SECRET)
      parts = ["image", "mask", "prompt", "n", "size", "response_format"]
      WebMock.wrap do
        WebMock.stub(:post, "#{OPENAI_API_DEFUALT_URL}/images/edits")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return do |req|
            HTTP::FormData.parse(req) do |part|
              part.name.in?(parts).should be_true
            end
            HTTP::Client::Response.new(200, body: IMAGE_RES)
          end

        req = ImageEditRequest.new(AUDIO_SAMPLE, "Lorem Ipsum")
        res = client.create_image_edit(req)
        res.data.size.should eq(2)
        res.data.first.should_not be_nil
      end
    end

    it "test image variation" do
      client = Client.new(TEST_SECRET)
      parts = ["image", "n", "size", "response_format"]
      WebMock.wrap do
        WebMock.stub(:post, "#{OPENAI_API_DEFUALT_URL}/images/variations")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return do |req|
            HTTP::FormData.parse(req) do |part|
              part.name.in?(parts).should be_true
            end
            HTTP::Client::Response.new(200, body: IMAGE_RES)
          end

        req = ImageVariationRequest.new(AUDIO_SAMPLE)
        res = client.create_image_variation(req)
        res.data.size.should eq(2)
        res.data.first.should_not be_nil
      end
    end
  end
end
