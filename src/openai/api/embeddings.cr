require "json"
require "base64"
require "io/byte_format"
require "./usage"
require "../errors"

module OpenAI
  # Embedding is a special format of data representation that can be easily utilized by machine
  # learning models and algorithms. The embedding is an information dense representation of the
  # semantic meaning of a piece of text. Each embedding is a vector of floating point numbers,
  # such that the distance between two embeddings in the vector space is correlated with semantic similarity
  # between two inputs in the original format. For example, if two texts are similar,
  # then their vector representations should also be similar.
  struct Embedding
    include JSON::Serializable

    # The index of the embedding in the list of embeddings.
    getter index : Int32

    # The object type, which is always "embedding".
    getter object : String

    # The embedding vector, which is a list of floats. The length of vector depends on the model as listed in the embedding guide.
    @[JSON::Field(converter: OpenAI::EmbeddingConverter)]
    getter embedding : Array(Float32)
  end

  struct EmbeddingRequest
    include JSON::Serializable

    # ID of the model to use. You can use the List models API to see all of your available models, or see our Model overview for descriptions of them.
    getter model : EmbeddingModel

    # Input text to embed, encoded as a string or array of tokens. To embed multiple inputs in a single request, pass an array of strings or array of token arrays.
    # Each input must not exceed the max input tokens for the model (8191 tokens for `EmbeddingModel::AdaEmbeddingV2`) and cannot be an empty string.
    getter input : String | Array(String) | Array(Array(Int32))

    # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse.
    getter user : String? = nil

    # EmbeddingEncoding is the format of the embeddings data.
    # Currently, only `float` and `base64` are supported, however, `base64` is not officially documented.
    # If not specified OpenAI will use "float".
    getter encoding_format : EmbeddingEncoding = EmbeddingEncoding::Float

    def initialize(@model, @input, @user = nil, @encoding_format = :float)
    end
  end

  struct EmbeddingResponse
    include JSON::Serializable
    getter object : String
    getter data : Array(Embedding)
    getter model : EmbeddingModel
    getter usage : Usage
  end

  # EmbeddingEncoding is the format of the embeddings data.
  # Currently, only `float` and `base64` are supported, however, `base64` is not officially documented.
  # If not specified OpenAI will use "float".
  enum EmbeddingEncoding
    Float
    Base64

    def to_s
      super.downcase
    end
  end

  # Enumerates the models which can be used to generate Embedding vectors.
  enum EmbeddingModel
    Unknown

    # Deprecated: Will be shut down on January 04, 2024. Use `AdaEmbeddingV2` instead
    AdaSimilarity
    # Deprecated: Will be shut down on January 04, 2024. Use `AdaEmbeddingV2` instead
    BabbageSimilarity
    # Deprecated: Will be shut down on January 04, 2024. Use `AdaEmbeddingV2` instead
    CurieSimilarity
    # Deprecated: Will be shut down on January 04, 2024. Use `AdaEmbeddingV2` instead
    DavinciSimilarity
    # Deprecated: Will be shut down on January 04, 2024. Use `AdaEmbeddingV2` instead
    AdaSearchDocument
    # Deprecated: Will be shut down on January 04, 2024. Use `AdaEmbeddingV2` instead
    AdaSearchQuery
    # Deprecated: Will be shut down on January 04, 2024. Use `AdaEmbeddingV2` instead
    BabbageSearchDocument
    # Deprecated: Will be shut down on January 04, 2024. Use `AdaEmbeddingV2` instead
    BabbageSearchQuery
    # Deprecated: Will be shut down on January 04, 2024. Use `AdaEmbeddingV2` instead
    CurieSearchDocument
    # Deprecated: Will be shut down on January 04, 2024. Use `AdaEmbeddingV2` instead
    CurieSearchQuery
    # Deprecated: Will be shut down on January 04, 2024. Use `AdaEmbeddingV2` instead
    DavinciSearchDocument
    # Deprecated: Will be shut down on January 04, 2024. Use `AdaEmbeddingV2` instead
    DavinciSearchQuery
    # Deprecated: Will be shut down on January 04, 2024. Use `AdaEmbeddingV2` instead
    AdaCodeSearchCode
    # Deprecated: Will be shut down on January 04, 2024. Use `AdaEmbeddingV2` instead
    AdaCodeSearchText
    # Deprecated: Will be shut down on January 04, 2024. Use `AdaEmbeddingV2` instead
    BabbageCodeSearchCode
    # Deprecated: Will be shut down on January 04, 2024. Use `AdaEmbeddingV2` instead
    BabbageCodeSearchText
    AdaEmbeddingV2

    def self.parse?(string : String) : self?
      OpenAI.em_2_text.invert[string]?
    end

    def to_s(io : IO) : Nil
      io << to_s
    end

    def to_s
      raise OpenAIError.new("Unkonwn embedding model received. #{self}") if self == Unknown
      OpenAI.em_2_text[self]
    end
  end

  # :nodoc
  class_getter(em_2_text) {
    {
      EmbeddingModel::AdaSimilarity         => "text-similarity-ada-001",
      EmbeddingModel::BabbageSimilarity     => "text-similarity-babbage-001",
      EmbeddingModel::CurieSimilarity       => "text-similarity-curie-001",
      EmbeddingModel::DavinciSimilarity     => "text-similarity-davinci-001",
      EmbeddingModel::AdaSearchDocument     => "text-search-ada-doc-001",
      EmbeddingModel::AdaSearchQuery        => "text-search-ada-query-001",
      EmbeddingModel::BabbageSearchDocument => "text-search-babbage-doc-001",
      EmbeddingModel::BabbageSearchQuery    => "text-search-babbage-query-001",
      EmbeddingModel::CurieSearchDocument   => "text-search-curie-doc-001",
      EmbeddingModel::CurieSearchQuery      => "text-search-curie-query-001",
      EmbeddingModel::DavinciSearchDocument => "text-search-davinci-doc-001",
      EmbeddingModel::DavinciSearchQuery    => "text-search-davinci-query-001",
      EmbeddingModel::AdaCodeSearchCode     => "code-search-ada-code-001",
      EmbeddingModel::AdaCodeSearchText     => "code-search-ada-text-001",
      EmbeddingModel::BabbageCodeSearchCode => "code-search-babbage-code-001",
      EmbeddingModel::BabbageCodeSearchText => "code-search-babbage-text-001",
      EmbeddingModel::AdaEmbeddingV2        => "text-embedding-ada-002",
    } of EmbeddingModel => String
  }

  # :nodoc
  module EmbeddingConverter
    def self.from_json(pull : JSON::PullParser) : Array(Float32)
      str = pull.read_raw
      if str.starts_with?('[') && str.ends_with?(']')
        Array(Float32).from_json(str)
      else
        bytes = Base64.decode(str.strip('"'))
        bsize = sizeof(Float32)
        Array(Float32).new(bytes.size // bsize) do |i|
          IO::ByteFormat::LittleEndian.decode(Float32, bytes[i*bsize..])
        end
      end
    end

    def self.to_json(value, json : JSON::Builder) : Nil
      value.to_json(json)
    end
  end
end
