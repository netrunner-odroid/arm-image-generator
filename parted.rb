# Class to setup partition of a image
class Parted
  def initialize(config)
    @c = config
  end

  def setup(file)
    fail 'Cannot find file!' unless File.exist? file
    ec = system("parted #{file} < #{@c.config_dir}/#{@c.config[:parted]}")
    fail 'Could not setup partitions!' unless ec
  end
end
