require_relative 'imageconfig'
require 'open-uri'

class RootFS
  def initialize(config)
    @c = config
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

    install_extra_packages
  end

  def install_extra_packages
    packages = @c.config[:packages].join(' ')
    system("sudo cp /usr/bin/qemu-arm-static #{@destination}/usr/bin/qemu-arm-static")
    system("sudo cp /etc/resolv.conf #{@destination}/etc/resolv.conf")
    system("sudo chroot #{@destination} /usr/bin/apt-get update")
    system("sudo chroot #{@destination} apt-get -y install #{packages}")
  end
end
