require "json"
require "http"
require "file"

module OpenAI
  enum FileStatus
    Uploaded
    Processed
    Pending
    Error
    Deleting
    Deleted

    def to_s
      super.downcase
    end
  end

  # Represents OpenAPI file object
  struct FileResponse
    include JSON::Serializable

    # The file identifier, which can be referenced in the API endpoints.
    getter id : String

    # the object type, which is always "file"
    getter object : String = "file"

    # The size of the file in bytes
    getter bytes : Int32

    # The Unix timestamp (in seconds) when the model was created.
    @[JSON::Field(converter: Time::EpochConverter)]
    getter created_at : Time

    # The name of the file
    getter filename : String

    # The intended purpose of the file. Currently, only "fine-tune" is supported.
    getter purpose : String = "fine-tune"

    # The current status of the file
    getter status : FileStatus?

    # Additional details about the status of the file. If the file is in the error state, this will include a message describing the error.
    getter status_details : String? = nil
  end

  # Represents File upload request
  struct FileRequest
    include JSON::Serializable

    # Name of the [JSON Lines]() files to be uploaded.
    # If the `purpose` is set to "fine-tune", the file will be used for fine-tuning
    @[JSON::Field(converter: OpenAI::StringConverter)]
    getter file : File | Path | String

    # The intended purpose of the uploaded documents.
    # Use "fine-tune" for fine-tuning. This allows us to validate the format of the uploaded file.
    getter purpose : String

    def initialize(@file, @purpose = "fine-tune")
    end

    def build_metada(builder : HTTP::FormData::Builder)
      tune_file = get_file
      metadata = HTTP::FormData::FileMetadata.new(filename: File.basename(tune_file.path))
      builder.file("file", tune_file, metadata)

      builder.field("purpose", purpose)
    end

    private def get_file : File
      return file.as(File) if file.is_a?(File)
      File.open(file.as(Path | String))
    end
  end

  # File Deletion request status
  record FileDeletionStatus, id : String?, object : String?, deleted : Bool? do
    include JSON::Serializable
  end
end
