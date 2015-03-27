require_relative 'imageconfig'
require 'open-uri'

class RootFS
  def initialize(config)
    @c = config
    system('sudo apt-get install qemu-user-static')
  end
  def install(d)
    @destination = d
    Dir.mkdir('cache') unless Dir.exist?('cache')

    puts "Writing #{@c.config[:rootfs]}"
    # FIXME: Assume tar.gz format for now
    unless File.exist? 'cache/rootfs.tar.gz'
      Dir.chdir('cache') do
        File.write('rootfs.tar.gz', open(@c.config[:rootfs]).read)
      end
    end

    # tar spits out a whole bunch of stuff that I don't care about
    `sudo tar xvf cache/rootfs.tar.gz -C #{@destination}`
    fail 'Could not untar the rootfs!' unless $?.success?
  end
end
