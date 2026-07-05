require "./spec_helper"

module OpenAI
  describe OpenAI::ApiType do
    it "detects azure from openai.azure.com URL" do
      ApiType.detect("https://placeos.openai.azure.com").should eq(ApiType::Azure)
    end

    it "detects azure from cognitiveservices.azure.com URL" do
      ApiType.detect("https://my-service.cognitiveservices.azure.com").should eq(ApiType::Azure)
    end

    it "detects standard for default OpenAI URL" do
      ApiType.detect(OPENAI_API_DEFAULT_URL).should eq(ApiType::OpenAI)
    end

    it "detects standard for third-party URLs" do
      ApiType.detect("http://localhost:11434/v1").should eq(ApiType::OpenAI)
    end

    it "detects standard for custom proxy URLs" do
      ApiType.detect("https://my-proxy.example.com/v1").should eq(ApiType::OpenAI)
    end
  end

  describe OpenAI::Client::Config do
    it "auto-detects azure from URL in Client.new" do
      client = Client.new(TEST_SECRET, "https://placeos.openai.azure.com")
      client.config.api_type.azure?.should be_true
      client.config.api_type.should eq(ApiType::Azure)
    end

    it "auto-detects standard for third-party URL in Client.new" do
      client = Client.new(nil, "http://localhost:11434/v1")
      client.config.api_type.should eq(ApiType::OpenAI)
      client.config.api_key.should eq("")
    end

    it "auto-detects standard when no custom endpoint given" do
      conf = Client::Config.default(TEST_SECRET)
      conf.api_type.should eq(ApiType::OpenAI)
      conf.api_base.should eq(OPENAI_API_DEFAULT_URL)
    end

    it "test model mapper for azure deployments with default mapper" do
      conf = Client::Config.azure("sk-abc123", "https://azure.openai.com")
      conf.azure_deployment_by_model("").should eq("")
      conf.azure_deployment_by_model("gpt-3.5-turbo").should eq("gpt-35-turbo")
      conf.azure_deployment_by_model("gpt-3.5-turbo-0301").should eq("gpt-35-turbo-0301")
      conf.azure_deployment_by_model("text-embedding-ada-002").should eq("text-embedding-ada-002")
    end

    it "test model mapper for azure deployments with custom mapper" do
      mapper = ->(str : String) do
        mappings = {"gpt-3.5-turbo" => "my-gpt35"}
        mappings[str]? || str
      end
      conf = Client::Config.azure("sk-abc123", "https://azure.openai.com", model_mapper: mapper)
      conf.azure_deployment_by_model("").should eq("")
      conf.azure_deployment_by_model("text-embedding-ada-002").should eq("text-embedding-ada-002")

      conf.azure_deployment_by_model("gpt-3.5-turbo").should eq("my-gpt35")
    end
  end
end
