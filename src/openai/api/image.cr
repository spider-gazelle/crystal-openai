require "json"
require "http"
require "file"

module OpenAI
  # Image sizes defined by the OpenAI API.
  enum ImageSize
    # 256 x 256 size
    Small
    # 512 x 512 size
    Medium
    # 1024 x 1024 size
    Large

    def to_s
      case self
      in Small  then "256x256"
      in Medium then "512x512"
      in Large  then "1024x1024"
      end
    end
  end

  enum ImageRespFormat
    URL
    B64_JSON

    def to_s
      super.downcase
    end
  end

  class ImageRequest
    include JSON::Serializable

    # A text description of the desired image(s). The maximum length is 1000 characters.
    property prompt : String

    # The number of images to generate. Must be between 1 and 10.
    @[JSON::Field(key: "n")]
    property num_images : Int32 = 1

    # The size of the generated images
    property size : ImageSize = :large

    # The format in which the generated images are returned.
    property response_format : ImageRespFormat = :url

    # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse.
    property user : String? = nil

    def initialize(@prompt, @num_images = 1, @size = :large, @response_format = :url, @user = nil)
    end
  end

  class ImageEditRequest
    include JSON::Serializable

    # The image to edit. Must be a valid PNG file, less than 4MB, and square. If mask is not provided, image must have transparency, which will be used as the mask.
    @[JSON::Field(converter: OpenAI::StringConverter)]
    property image : File | Path | String

    # An additional image whose fully transparent areas (e.g. where alpha is zero) indicate where image should be edited. Must be a valid PNG file, less than 4MB, and have the same dimensions as image.
    @[JSON::Field(converter: OpenAI::StringConverter)]
    property mask : File | Path | String | Nil

    # A text description of the desired image(s). The maximum length is 1000 characters.
    property prompt : String

    # The number of images to generate. Must be between 1 and 10.
    @[JSON::Field(key: "n")]
    property num_images : Int32 = 1

    # The size of the generated images
    property size : ImageSize = :large

    # The format in which the generated images are returned.
    property response_format : ImageRespFormat = :url

    # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse.
    property user : String? = nil

    def initialize(@image, @prompt, @mask = nil, @num_images = 1, @size = :large, @response_format = :url, @user = nil)
    end

    def build_metada(builder : HTTP::FormData::Builder)
      image_file = get_file(image)
      metadata = HTTP::FormData::FileMetadata.new(filename: File.basename(image_file.path))
      builder.file("image", image_file, metadata)

      if m = mask
        mask_file = get_file(m)
        metadata = HTTP::FormData::FileMetadata.new(filename: File.basename(mask_file.path))
        builder.file("mask", mask_file, metadata)
      end
      builder.field("prompt", prompt)
      builder.field("n", num_images)
      builder.field("size", size.to_s)
      builder.field("response_format", response_format.to_s)
      builder.field("user", user) unless user.nil?
    end

    private def get_file(name) : File
      return name.as(File) if name.is_a?(File)
      File.open(name.as(Path | String))
    end
  end

  class ImageVariationRequest
    include JSON::Serializable

    # The image to use as the basis for the variation(s). Must be a valid PNG file, less than 4MB, and square.
    @[JSON::Field(converter: OpenAI::StringConverter)]
    property image : File | Path | String

    # The number of images to generate. Must be between 1 and 10.
    @[JSON::Field(key: "n")]
    property num_images : Int32 = 1

    # The size of the generated images
    property size : ImageSize = :large

    # The format in which the generated images are returned.
    property response_format : ImageRespFormat = :url

    # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse.
    property user : String? = nil

    def initialize(@image, @num_images = 1, @size = :large, @response_format = :url, @user = nil)
    end

    def build_metada(builder : HTTP::FormData::Builder)
      image_file = get_file
      metadata = HTTP::FormData::FileMetadata.new(filename: File.basename(image_file.path))
      builder.file("image", image_file, metadata)

      builder.field("n", num_images)
      builder.field("size", size.to_s)
      builder.field("response_format", response_format.to_s)
      builder.field("user", user) unless user.nil?
    end

    private def get_file : File
      return image.as(File) if image.is_a?(File)
      File.open(image.as(Path | String))
    end
  end

  record ImageRespData, url : String?, b64_json : String? do
    include JSON::Serializable
  end

  struct ImageResponse
    include JSON::Serializable

    @[JSON::Field(converter: Time::EpochConverter)]
    getter created : Time?

    getter data : Array(ImageRespData) = [] of ImageRespData
  end
end
