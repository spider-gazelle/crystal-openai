require "webmock"
require "./spec_helper"

module OpenAI
  describe "OpenAI::Fine-Tuning" do
    it "test create fine-tuning job" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:post, "#{OPENAI_API_DEFUALT_URL}/fine_tuning/jobs")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: FINE_TUNING_JOB)

        res = client.create_fine_tuning_job(FineTuningJobRequest.new("some-training-file", GPT3Dot5Turbo))
        res.id.should eq("ft-AF1WoRqd3aJAHsqc9NY7iL8F")
        res.status.to_s.should eq("pending")
      end
    end

    it "test list fine-tuning jobs" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:get, "#{OPENAI_API_DEFUALT_URL}/fine_tuning/jobs?limit=20")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: FINE_TUNING_JOB_LIST)

        res = client.list_fine_tuning_jobs
        res.data.size.should eq(1)
      end
    end

    it "test retrieve fine-tuning job" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:get, "#{OPENAI_API_DEFUALT_URL}/fine_tuning/jobs/ft-AF1WoRqd3aJAHsqc9NY7iL8F")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: FINE_TUNING_JOB_RET)

        res = client.get_fine_tuning_job("ft-AF1WoRqd3aJAHsqc9NY7iL8F")
        res.id.should eq("ft-zRdUkP4QeZqeYjDcQL0wwam1")
        res.status.to_s.should eq("succeeded")
      end
    end

    it "test cancel fine-tuning job" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:post, "#{OPENAI_API_DEFUALT_URL}/fine_tuning/jobs/ft-AF1WoRqd3aJAHsqc9NY7iL8F/cancel")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: FINE_TUNING_JOB)

        res = client.cancel_fine_tuning_job("ft-AF1WoRqd3aJAHsqc9NY7iL8F")
        res.id.should eq("ft-AF1WoRqd3aJAHsqc9NY7iL8F")
        res.status.to_s.should eq("pending")
      end
    end

    it "test list fine-tuning events" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:get, "#{OPENAI_API_DEFUALT_URL}/fine_tuning/jobs/ft-AF1WoRqd3aJAHsqc9NY7iL8F/events?limit=20&after=5")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: FINE_TUNING_EVENTS_LIST)

        res = client.list_fine_tuning_events("ft-AF1WoRqd3aJAHsqc9NY7iL8F", "5")
        res.data.size.should eq(2)
      end
    end
  end
end
