require "webmock"
require "./spec_helper"

module OpenAI
  describe "OpenAI::Embeddings" do
    it "test embedding models are properly serialized" do
      models = [EmbeddingModel::AdaSimilarity,
                EmbeddingModel::BabbageSimilarity,
                EmbeddingModel::CurieSimilarity,
                EmbeddingModel::DavinciSimilarity,
                EmbeddingModel::AdaSearchDocument,
                EmbeddingModel::AdaSearchQuery,
                EmbeddingModel::BabbageSearchDocument,
                EmbeddingModel::BabbageSearchQuery,
                EmbeddingModel::CurieSearchDocument,
                EmbeddingModel::CurieSearchQuery,
                EmbeddingModel::DavinciSearchDocument,
                EmbeddingModel::DavinciSearchQuery,
                EmbeddingModel::AdaCodeSearchCode,
                EmbeddingModel::AdaCodeSearchText,
                EmbeddingModel::BabbageCodeSearchCode,
                EmbeddingModel::BabbageCodeSearchText,
                EmbeddingModel::AdaEmbeddingV2]
      models.each do |model|
        req = EmbeddingRequest.new(model: model, input: [
          "The food was delicious and the waiter",
          "Other examples of embedding request",
        ])
        req.to_json.includes?(<<-J
        "model":"#{model}"
        J
        ).should be_true
      end
    end

    it "test embedding request input" do
      req = EmbeddingRequest.new(model: EmbeddingModel::AdaEmbeddingV2,
        input: [[1, 2, 3, 4, 5, 6, 7, 8], [6395, 6096, 286, 11525, 12083, 2581]]
      )
      req.to_json.should_not be_nil
    end

    it "test embeddings endpoint with float embeddings" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:post, "#{OPENAI_API_DEFUALT_URL}/embeddings")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: EMBEDDING_RES)

        resp = client.embeddings(EmbeddingRequest.new(model: EmbeddingModel::AdaEmbeddingV2, input: "say hello"))
        resp.data.size.should eq(2)
        resp.data.first.embedding.should eq(EMBEDDING_1)
        resp.data.last.embedding.should eq(EMBEDDING_2)
      end
    end

    it "test embeddings endpoint with base64 embeddings" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:post, "#{OPENAI_API_DEFUALT_URL}/embeddings")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: EMBEDDING_RES_B64)

        resp = client.embeddings(EmbeddingRequest.new(model: EmbeddingModel::AdaEmbeddingV2, input: "say hello", encoding_format: :base64))
        resp.data.size.should eq(2)
        resp.data.first.embedding.should eq(EMBEDDING_1)
        resp.data.last.embedding.should eq(EMBEDDING_2)
      end
    end
  end
end
