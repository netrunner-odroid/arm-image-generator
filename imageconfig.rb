require 'yaml'

# Config parser class
class ImageConfig
  attr_accessor :config

  def initialize(config)
    @config = YAML.load_file(config)
  end
end
