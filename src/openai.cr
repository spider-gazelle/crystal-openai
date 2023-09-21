require "json-schema"

module OpenAI
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}

  module FuncMarker
  end
end

require "./openai/**"
