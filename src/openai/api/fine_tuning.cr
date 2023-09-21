require "json"

module OpenAI
  # Fine-tuning job object
  struct FineTuningJob
    include JSON::Serializable

    # The object identifier, which can be referenced in the API endpoints.
    getter id : String

    # The object type, which is always "fine_tuning.job".
    getter object : String = "fine_tuning.job"

    # The Unix timestamp (in seconds) when the fine-tuning job was created.
    @[JSON::Field(converter: Time::EpochConverter)]
    getter created_at : Time

    # The Unix timestamp (in seconds) for when the fine-tuning job was finished. The value will be null if the fine-tuning job is still running.
    @[JSON::Field(converter: Time::EpochConverter)]
    getter finished_at : Time?

    # The base model that is being fine-tuned.
    getter model : String

    # The name of the fine-tuned model that is being created. The value will be null if the fine-tuning job is still running.
    getter fine_tuned_model : String?

    # The organization that owns the fine-tuning job.
    getter organization_id : String

    # The current status of the fine-tuning job, which can be either created, pending, running, succeeded, failed, or cancelled.
    getter status : FineTuningStatus

    # The hyperparameters used for the fine-tuning job.
    getter hyperparameters : HyperParams?

    # The file ID used for training. You can retrieve the training data with the Files API.
    getter training_file : String

    # The file ID used for validation. You can retrieve the validation results with the Files API.
    getter validation_file : String?

    # The compiled results file ID(s) for the fine-tuning job. You can retrieve the results with the Files API.
    getter result_files : Array(String)

    # The total number of billable tokens processed by this fine-tuning job. The value will be null if the fine-tuning job is still running.
    getter trained_tokens : Int32?

    # For fine-tuning jobs that have failed, this will contain more information on the cause of the failure.
    getter error : JSON::Any?
  end

  class FineTuningJobRequest
    include JSON::Serializable

    # The ID of an uploaded file that contains training data.
    # See upload file for how to upload a file.
    # Your dataset must be formatted as a JSONL file. Additionally, you must upload your file with the purpose fine-tune.
    property training_file : String

    # The ID of an uploaded file that contains validation data.
    #
    # If you provide this file, the data is used to generate validation metrics periodically during fine-tuning. These metrics can be viewed in the fine-tuning results file.
    # The same data should not be present in both train and validation files.
    #
    # Your dataset must be formatted as a JSONL file. You must upload your file with the purpose fine-tune.
    property validation_file : String?

    # The name of the model to fine-tune. You can select one of the [supported models](https://platform.openai.com/docs/guides/fine-tuning/what-models-can-be-fine-tuned).
    property model : String

    # The hyperparameters used for the fine-tuning job.
    property hyperparameters : HyperParams?

    # A string of up to 18 characters that will be added to your fine-tuned model name.
    #
    # For example, a suffix of "custom-model-name" would produce a model name like ft:gpt-3.5-turbo:openai:custom-model-name:7p4lURel.
    property suffix : String?

    def initialize(@training_file, @model, @validation_file = nil, @hyperparameters = nil, @suffix = nil)
    end
  end

  record FineTuningJobEventList, object : String, data : Array(FineTuningJobEvent), has_more : Bool do
    include JSON::Serializable
  end

  record FineTuningJobEvent, object : String, id : String, created_at : Time, level : String, message : String, data : String?, type : String do
    include JSON::Serializable
    @[JSON::Field(converter: Time::EpochConverter)]
    getter created_at : Time
  end

  struct HyperParams
    include JSON::Serializable

    # The number of epochs to train the model for. An epoch refers to one full cycle through the training dataset. "Auto" decides the optimal number of epochs based
    # on the size of the dataset. If setting the number manually, we support any number between 1 and 50 epochs.
    getter n_epochs : Int32 | String

    def initialize(@n_epochs)
    end
  end

  enum FineTuningStatus
    Created
    Pending
    Running
    Succeeded
    Failed
    Cancelled

    def to_s
      super.downcase
    end
  end
end
