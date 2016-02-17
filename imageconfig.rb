require 'yaml'

# Config parser class
class ImageConfig
  attr_accessor :config
  attr_accessor :config_dir

  def initialize(config_dir)
    @config_dir = config_dir
    @config = YAML.load_file("#{@config_dir}/config.yml")
    raise 'You need to supply a partition table setup' if @config[:parted].nil?
  end
end
