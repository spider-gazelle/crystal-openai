require "./spec_helper"

module OpenAI
  describe OpenAI::Client::Config do
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
