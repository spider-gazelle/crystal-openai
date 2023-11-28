require "spec"
require "../src/openai"

TEST_SECRET     = "sk-some-funny-long-garbage-string"
AZURE_SAMPLE_EP = "https://placeos.openai.azure.com"
MODELS_SAMPLE   = <<-JSON
{
  "object": "list",
  "data": [
    {
      "id": "model-id-0",
      "object": "model",
      "created": 1686935002,
      "owned_by": "organization-owner"
    },
    {
      "id": "model-id-1",
      "object": "model",
      "created": 1686935002,
      "owned_by": "organization-owner"
    },
    {
      "id": "model-id-2",
      "object": "model",
      "created": 1686935002,
      "owned_by": "openai"
    }
  ]
}
JSON

MODEL_SAMPLE = <<-JSON
{
  "id": "davinci",
  "object": "model",
  "created": 1686935002,
  "owned_by": "openai"
}
JSON

ENGINES_SAMPLE = <<-JSON
{
  "object": "list",
  "data": [
    {
      "id": "davinci",
      "object": "engine",
      "ready": true,
      "owner": "organization-owner"
    },
    {
      "id": "engine-id-1",
      "object": "engine",
      "ready": true,
      "owner": "organization-owner"
    },
    {
      "id": "engine-id-2",
      "object": "engine",
      "ready": true,
      "owner": "openai"
    }
  ]
}
JSON

ENGINE_SAMPLE = <<-JSON
{
  "id": "davinci",
  "object": "engine",
  "owner": "openai",
  "ready": true
}
JSON

CHAT_COMPLETION_REQ = <<-JSON
{
    "model": "gpt-3.5-turbo",
    "messages": [
      {
        "role": "system",
        "content": "You are a helpful assistant."
      },
      {
        "role": "user",
        "content": "Hello!"
      }
    ]
}
JSON

CHAT_COMPLETION_RES = <<-JSON
{
	"id": "chatcmpl-123",
	"object": "chat.completion",
	"created": 1677652288,
	"model": "gpt-3.5-turbo-0613",
  "system_fingerprint": "fp_44709d6fcb",
	"choices": [{
		"index": 0,
		"message": {
			"role": "assistant",
			"content": "\\n\\nHello there, how may I assist you today?"
		},
		"finish_reason": "stop"
	}],
	"usage": {
		"prompt_tokens": 9,
		"completion_tokens": 12,
		"total_tokens": 21
	}
}
JSON

CHAT_COMPLETION_FUNC_PARAM = <<-JSON
{
	"type": "object",
	"properties": {
		"count": {
			"type": "integer",
			"description": "total number of words in sentence"
		},
		"words": {
			"items": {
				"type": "string"
			},
			"type": "array",
			"description": "list of words in sentence"
		}
	},
	"required": ["count", "words"]
}
JSON

CHAT_COMPLETION_STREAM_ERROR = <<-JSON
{
  "error": {
    "message": "Incorrect API key provided: sk-***************************************",
    "type": "invalid_request_error",
    "param": null,
    "code": "invalid_api_key"
  }
}
JSON

CHAT_COMPLETION_RATELIMIT_ERROR = <<-JSON
{
  "error": {
    "message": "You are sending requests too quickly.",
    "type": "rate_limit_reached",
    "param": null,
    "code": "rate_limit_reached"
  }
}
JSON

COMPLETION_RES = <<-JSON
{
  "id": "cmpl-uqkvlQyYK7bGYrRHQ0eXlWi7",
  "object": "text_completion",
  "created": 1589478378,
  "model": "text-davinci-003",
  "choices": [
    {
      "text": "\\n\\nThis is indeed a test",
      "index": 0,
      "logprobs": null,
      "finish_reason": "length"
    }
  ],
  "usage": {
    "prompt_tokens": 5,
    "completion_tokens": 7,
    "total_tokens": 12
  }
}
JSON

MODERATION_RES = <<-JSON
{
  "id": "modr-XXXXX",
  "model": "text-moderation-stable",
  "results": [
    {
      "flagged": true,
      "categories": {
        "sexual": false,
        "hate": false,
        "harassment": false,
        "self-harm": false,
        "sexual/minors": false,
        "hate/threatening": false,
        "violence/graphic": false,
        "self-harm/intent": false,
        "self-harm/instructions": false,
        "harassment/threatening": true,
        "violence": true
      },
      "category_scores": {
        "sexual": 1.2282071e-06,
        "hate": 0.010696256,
        "harassment": 0.29842457,
        "self-harm": 1.5236925e-08,
        "sexual/minors": 5.7246268e-08,
        "hate/threatening": 0.0060676364,
        "violence/graphic": 4.435014e-06,
        "self-harm/intent": 8.098441e-10,
        "self-harm/instructions": 2.8498655e-11,
        "harassment/threatening": 0.63055265,
        "violence": 0.99011886
      }
    }
  ]
}
JSON

EMBEDDING_1 = [1.23_f32, 4.56_f32, 7.89_f32]
EMBEDDING_2 = [-0.006968617_f32, -0.0052718227_f32, 0.011901081_f32]

EMBEDDING_RES = <<-J
{
  "object": "list",
  "data": [
    {
      "object": "embedding",
      "embedding": #{EMBEDDING_1},
      "index": 0
    },
    {
      "object": "embedding",
      "embedding": #{EMBEDDING_2},
      "index": 1
    }
  ],
  "model": "text-embedding-ada-002",
  "usage": {
    "prompt_tokens": 8,
    "total_tokens": 8
  }
}
J

EMBEDDING_RES_B64 = <<-J
{
  "object": "list",
  "data": [
    {
      "object": "embedding",
      "embedding": "pHCdP4XrkUDhevxA",
      "index": 0
    },
    {
      "object": "embedding",
      "embedding": "/1jku0G/rLvA/EI8",
      "index": 1
    }
  ],
  "model": "text-embedding-ada-002",
  "usage": {
    "prompt_tokens": 8,
    "total_tokens": 8
  }
}
J

AUDIO_SAMPLE = __FILE__
AUDIO_RES    = <<-J
{
  "text": "Imagine the wildest idea that you've ever had, and you're curious about how it might scale to something that's a 100, a 1,000 times bigger. This is a place where you can get to do that."
}
J

FILE_LIST_RES = <<-J
{
  "data": [
    {
      "id": "file-abc123",
      "object": "file",
      "bytes": 175,
      "created_at": 1613677385,
      "filename": "train.jsonl",
      "purpose": "search"
    },
    {
      "id": "file-abc123",
      "object": "file",
      "bytes": 140,
      "created_at": 1613779121,
      "filename": "puppy.jsonl",
      "purpose": "search"
    }
  ],
  "object": "list"
}
J

FILE_UPLOAD_RES = <<-J
{
  "id": "file-abc123",
  "object": "file",
  "bytes": 140,
  "created_at": 1613779121,
  "filename": "mydata.jsonl",
  "purpose": "fine-tune",
  "status": "uploaded"
}
J

FILE_DEL_RES = <<-J
{
  "id": "file-abc123",
  "object": "file",
  "deleted": true
}
J

IMAGE_RES = <<-J
{
  "created": 1589478378,
  "data": [
    {
      "url": "https://..."
    },
    {
      "url": "https://..."
    }
  ]
}
J

FINE_TUNING_JOB = <<-J
{
  "object": "fine_tuning.job",
  "id": "ft-AF1WoRqd3aJAHsqc9NY7iL8F",
  "model": "gpt-3.5-turbo-0613",
  "created_at": 1614807352,
  "fine_tuned_model": null,
  "organization_id": "org-123",
  "result_files": [],
  "status": "pending",
  "validation_file": null,
  "training_file": "file-abc123"
}
J

FINE_TUNING_JOB_LIST = <<-J
{
  "object": "list",
  "data": [
    {
      "object": "fine_tuning.job.event",
      "id": "ft-event-TjX0lMfOniCZX64t9PUQT5hn",
      "created_at": 1689813489,
      "level": "warn",
      "message": "Fine tuning process stopping due to job cancellation",
      "data": null,
      "type": "message"
    }
  ],
  "has_more": true
}
J

FINE_TUNING_JOB_RET = <<-J
{
  "object": "fine_tuning.job",
  "id": "ft-zRdUkP4QeZqeYjDcQL0wwam1",
  "model": "davinci-002",
  "created_at": 1692661014,
  "finished_at": 1692661190,
  "fine_tuned_model": "ft:davinci-002:my-org:custom_suffix:7q8mpxmy",
  "organization_id": "org-123",
  "result_files": [
      "file-abc123"
  ],
  "status": "succeeded",
  "validation_file": null,
  "training_file": "file-abc123",
  "hyperparameters": {
      "n_epochs": 4
  },
  "trained_tokens": 5768
}
J

FINE_TUNING_EVENTS_LIST = <<-J
{
  "object": "list",
  "data": [
    {
      "object": "fine_tuning.job.event",
      "id": "ft-event-ddTJfwuMVpfLXseO0Am0Gqjm",
      "created_at": 1692407401,
      "level": "info",
      "message": "Fine tuning job successfully completed",
      "data": null,
      "type": "message"
    },
    {
      "object": "fine_tuning.job.event",
      "id": "ft-event-tyiGuB72evQncpH87xe505Sv",
      "created_at": 1692407400,
      "level": "info",
      "message": "New fine-tuned model created: ft:gpt-3.5-turbo:openai::7p4lURel",
      "data": null,
      "type": "message"
    }
  ],
  "has_more": true
}
J

struct TestMessage
  include JSON::Serializable

  @[JSON::Field(description: "total number of words in sentence")]
  getter count : Int32

  @[JSON::Field(description: "list of words in sentence")]
  getter words : Array(String)

  def initialize(@count, @words, @reason)
  end
end
