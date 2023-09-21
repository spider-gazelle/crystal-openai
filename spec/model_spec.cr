require "webmock"
require "./spec_helper"

module OpenAI
  describe OpenAI::Model do
    it "Returns a list of models" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:get, "#{OPENAI_API_DEFUALT_URL}/models")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: MODELS_SAMPLE)

        resp = client.models
        resp.size.should eq(3)
      end
    end
    it "Returns a model by particular id" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:get, "#{OPENAI_API_DEFUALT_URL}/models/davinci")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: MODEL_SAMPLE)

        resp = client.model("davinci")
        resp.to_json.should eq(JSON.parse(MODEL_SAMPLE).to_json)
      end
    end

    it "Returns a list of models from Azure Endpoint" do
      client = Client.azure(TEST_SECRET, AZURE_SAMPLE_EP)
      WebMock.wrap do
        WebMock.stub(:get, "#{AZURE_SAMPLE_EP}/openai/models?api-version=#{AZURE_API_VERSION}")
          .with(headers: {AZURE_API_HEADER => TEST_SECRET})
          .to_return(body: MODELS_SAMPLE)

        resp = client.models
        resp.size.should eq(3)
      end
    end
    it "Returns a model from Azure Endpoint" do
      client = Client.azure(TEST_SECRET, AZURE_SAMPLE_EP)
      WebMock.wrap do
        WebMock.stub(:get, "#{AZURE_SAMPLE_EP}/openai/models/davinci?api-version=#{AZURE_API_VERSION}")
          .with(headers: {AZURE_API_HEADER => TEST_SECRET})
          .to_return(body: MODEL_SAMPLE)

        resp = client.model("davinci")
        resp.to_json.should eq(JSON.parse(MODEL_SAMPLE).to_json)
      end
    end
  end

  describe OpenAI::Engine do
    it "Returns a list of engines" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:get, "#{OPENAI_API_DEFUALT_URL}/engines")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: ENGINES_SAMPLE)

        resp = client.engines
        resp.size.should eq(3)
      end
    end
    it "Returns a engine by particular id" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:get, "#{OPENAI_API_DEFUALT_URL}/engines/davinci")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: ENGINE_SAMPLE)

        resp = client.engine("davinci")
        resp.to_json.should eq(JSON.parse(ENGINE_SAMPLE).to_json)
      end
    end
  end
end
