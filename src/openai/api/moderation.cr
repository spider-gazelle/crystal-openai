require "json"
require "time"

module OpenAI
  enum ModerationModel
    Stable
    Latest
    # moderation-text-xxx where xxx are numbers
    Deprecated

    def to_s(io : IO) : Nil
      io << to_s
    end

    def to_s
      "text-moderation-#{super.downcase}"
    end
  end

  # The moderations endpoint is a tool you can use to check whether content complies with OpenAI's usage policies.
  # Developers can thus identify content that our usage policies prohibits and take action, for instance by filtering it.
  struct ModerationRequest
    include JSON::Serializable

    # The input text to classify
    getter input : String

    # Two content moderations models are available: text-moderation-stable and text-moderation-latest.
    # The default is text-moderation-latest which will be automatically upgraded over time. This ensures you are always using our most accurate model.
    # If you use text-moderation-stable, we will provide advanced notice before updating the model.
    # Accuracy of text-moderation-stable may be slightly lower than for text-moderation-latest.
    getter model : ModerationModel

    def initialize(@input, @model = :stable)
    end
  end

  # Represents policy compliance report by OpenAI's content moderation model against a given input.
  struct ModerationResponse
    include JSON::Serializable

    # The unique identifier for the moderation request.
    getter id : String

    # The model used to generate the moderation results.
    @[JSON::Field(converter: OpenAI::ModerationModelConverter)]
    getter model : ModerationModel

    # A list of moderation objects.
    getter results : Array(ModerationResult)
  end

  struct ModerationResult
    include JSON::Serializable

    # Whether the content violates OpenAI's usage policies.
    getter flagged : Bool

    # A list of the categories, and whether they are flagged or not.
    getter categories : ModerationResultCategories

    # A list of the categories along with their scores as predicted by model.
    getter category_scores : ModerationResultCategoryScores
  end

  struct ModerationResultCategories
    include JSON::Serializable

    # Content that expresses, incites, or promotes hate based on race, gender, ethnicity, religion, nationality, sexual orientation,
    # disability status, or caste. Hateful content aimed at non-protected groups (e.g., chess players) is harrassment.
    getter hate : Bool = false

    # Hateful content that also includes violence or serious harm towards the targeted group based on race, gender, ethnicity, religion,
    # nationality, sexual orientation, disability status, or caste.
    @[JSON::Field(key: "hate/threatening")]
    getter hate_threatening : Bool = false

    # Content that expresses, incites, or promotes harassing language towards any target.
    getter harassment : Bool = false

    # Harassment content that also includes violence or serious harm towards any target.
    @[JSON::Field(key: "harassment/threatening")]
    getter harassment_threatening : Bool = false

    # Content that promotes, encourages, or depicts acts of self-harm, such as suicide, cutting, and eating disorders.
    @[JSON::Field(key: "self-harm")]
    getter self_harm : Bool = false

    # Content where the speaker expresses that they are engaging or intend to engage in acts of self-harm, such as suicide, cutting, and eating disorders.
    @[JSON::Field(key: "self-harm/intent")]
    getter self_harm_intent : Bool = false

    # Content that encourages performing acts of self-harm, such as suicide, cutting, and eating disorders, or that gives instructions or advice on how to commit such acts.
    @[JSON::Field(key: "self-harm/instructions")]
    getter self_harm_instructions : Bool = false

    # Content meant to arouse sexual excitement, such as the description of sexual activity, or that promotes sexual services (excluding sex education and wellness).
    getter sexual : Bool = false

    # Sexual content that includes an individual who is under 18 years old.
    @[JSON::Field(key: "sexual/minors")]
    getter sexual_minors : Bool = false

    # Content that depicts death, violence, or physical injury.
    getter violence : Bool = false

    # Content that depicts death, violence, or physical injury in graphic detail.
    @[JSON::Field(key: "violence/graphic")]
    getter violence_graphic : Bool = false
  end

  struct ModerationResultCategoryScores
    include JSON::Serializable

    # The score for the category 'hate'
    getter hate : Float64 = 0.0

    # The score for the category 'hate/threatening'.
    @[JSON::Field(key: "hate/threatening")]
    getter hate_threatening : Float64 = 0.0

    # The score for the category 'harassment'.
    getter harassment : Float64 = 0.0

    # The score for the category 'harassment/threatening'.
    @[JSON::Field(key: "harassment/threatening")]
    getter harassment_threatening : Float64 = 0.0

    # The score for the category 'self-harm'.
    @[JSON::Field(key: "self-harm")]
    getter self_harm : Float64 = 0.0

    # The score for the category 'self-harm/intent'.
    @[JSON::Field(key: "self-harm/intent")]
    getter self_harm_intent : Float64 = 0.0

    # The score for the category 'self-harm/instructions'.
    @[JSON::Field(key: "self-harm/instructions")]
    getter self_harm_instructions : Float64 = 0.0

    # The score for the category 'sexual'.
    getter sexual : Float64 = 0.0

    # The score for the category 'sexual/minors'.
    @[JSON::Field(key: "sexual/minors")]
    getter sexual_minors : Float64 = 0.0

    # The score for the category 'violence'.
    getter violence : Float64 = 0.0

    # The score for the category 'violence/graphic'.
    @[JSON::Field(key: "violence/graphic")]
    getter violence_graphic : Float64 = 0.0
  end

  module ModerationModelConverter
    def self.from_json(pull : JSON::PullParser)
      str = pull.read_string
      val = str.split('-').last
      begin
        # try deprecated models. if found return Deprecated instead
        val.to_i
        ModerationModel::Deprecated
      rescue ex
        ModerationModel.parse(val)
      end
    end

    def self.to_json(value, json : JSON::Builder) : Nil
      json.string(value.to_s)
    end
  end
end
