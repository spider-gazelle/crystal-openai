require "webmock"
require "./spec_helper"

module OpenAI
  describe "OpenAI::File" do
    it "test upload file" do
      client = Client.new(TEST_SECRET)
      parts = ["file", "purpose"]
      WebMock.wrap do
        WebMock.stub(:post, "#{OPENAI_API_DEFAULT_URL}/files")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return do |req|
            HTTP::FormData.parse(req) do |part|
              part.name.in?(parts).should be_true
            end
            HTTP::Client::Response.new(200, body: FILE_UPLOAD_RES)
          end

        req = FileRequest.new(AUDIO_SAMPLE)
        res = client.upload_file(req)
        res.status.to_s.should eq("uploaded")
      end
    end

    it "test delete file" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:delete, "#{OPENAI_API_DEFAULT_URL}/files/file-abc123")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: FILE_DEL_RES)

        res = client.delete_file("file-abc123")
        res.deleted.should be_true
      end
    end

    it "test list files" do
      client = Client.new(TEST_SECRET)
      WebMock.wrap do
        WebMock.stub(:get, "#{OPENAI_API_DEFAULT_URL}/files")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: FILE_LIST_RES)

        res = client.list_files
        res.size.should eq(2)
      end
    end

    it "test retrieve file contents" do
      client = Client.new(TEST_SECRET)
      body = File.read(AUDIO_SAMPLE)
      WebMock.wrap do
        WebMock.stub(:get, "#{OPENAI_API_DEFAULT_URL}/files/file-abc123/content")
          .with(headers: {"Authorization" => "Bearer #{TEST_SECRET}"})
          .to_return(body: body)

        res = client.get_file_contents("file-abc123")
        res.gets_to_end.should eq(body)
      end
    end
  end
end
