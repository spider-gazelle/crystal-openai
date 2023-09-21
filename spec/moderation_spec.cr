require "webmock"
require "./spec_helper"

module OpenAI
  describe "OpenAI::Moderation" do
    it "create moderation" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:post, "#{OPENAI_API_DEFUALT_URL}/moderations")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: MODERATION_RES)

        resp = client.moderation(ModerationRequest.new("I want to kill them."))
        resp.model.should eq(ModerationModel::Stable)
        resp.results.size.should eq(1)
        resp.results.first.flagged.should be_true
        resp.results.first.categories.harassment_threatening.should be_true
        resp.results.first.category_scores.harassment_threatening.should be > 0.0
      end
    end
  end
end
