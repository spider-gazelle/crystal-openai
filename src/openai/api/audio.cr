require "json"
require "http"
require "file"

module OpenAI
  # Whisper response formats. Whisper uses JSON format by default
  enum AudioRespFormat
    JSON
    TEXT
    SRT
    VERBOSE_JSON
    VTT

    def to_s
      super.downcase
    end
  end

  # AudioRequest represents a request structure for audio API
  class AudioRequest
    include JSON::Serializable

    # The audio file object to transcribe, in one of these formats: flac, mp3, mp4, mpeg, mpga, m4a, ogg, wav, or webm.
    @[JSON::Field(converter: OpenAI::StringConverter)]
    property file : File | Path | String

    # ID of the model to use. Only whisper-1 is currently available.
    property model : String

    # An optional text to guide the model's style or continue a previous audio segment. The prompt should match the audio language.
    property prompt : String?

    # The format of the transcript output, in one of these options: json, text, srt, verbose_json, or vtt.
    property response_format : AudioRespFormat

    # The sampling temperature, between 0 and 1. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it
    # more focused and deterministic. If set to 0, the model will use log probability to automatically increase the temperature until certain thresholds are hit.
    property temperature : Float64 = 0.0

    # The language of the input audio. Supplying the input language in ISO-639-1 format will improve accuracy and latency.
    property language : String?

    def initialize(@file, @model = "whisper-1", @prompt = nil, @response_format = AudioRespFormat::JSON, @temperature = 0.0, @language = nil)
    end

    def build_metada(builder : HTTP::FormData::Builder)
      audio = get_file
      metadata = HTTP::FormData::FileMetadata.new(filename: File.basename(audio.path))
      builder.file("file", audio, metadata)

      builder.field("model", model)
      builder.field("prompt", prompt) unless prompt.nil?
      builder.field("response_format", response_format.to_s)
      builder.field("temperature", sprintf("%.2f", temperature)) if temperature > 0.0
    end

    private def get_file : File
      return file.as(File) if file.is_a?(File)
      File.open(file.as(Path | String))
    end
  end

  record Segment, id : Int32?, seek : Int32?, start : Float64?, end : Float64?, text : String?, tokens : Array(Int32)?,
    temperature : Float64?, avg_logprob : Float64?, compression_ratio : Float64?, no_speec_prob : Float64?, transient : Bool? do
    include JSON::Serializable
  end

  record AudioResponse, task : String?, language : String?, duration : Float64?, segments : Array(Segment)?, text : String? do
    include JSON::Serializable
  end
end
