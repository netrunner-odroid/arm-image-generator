require_relative 'imageconfig'
require 'open-uri'

class RootFS
  def initialize(config)
    @c = config
    @dev = %w(sys proc dev)
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

    begin
      mount
      configure
    ensure
      unmount
    end
  end


  def mount
    system("sudo cp /usr/bin/qemu-arm-static #{@destination}/usr/bin/")
    @dev.each do |d|
      system('sudo', 'mount', '--bind', "/#{d}", "#{@destination}/#{d}")
    end
  end

  def unmount
    @dev.each do |d|
      system('sudo',  'umount', "#{@destination}/#{d}")
    end
    system("sudo rm #{@destination}/usr/bin/qemu-arm-static")
  end

  def configure
    puts "Adding user #{@c.config[:login][:username]}"
    system("sudo chroot #{@destination} useradd #{@c.config[:login][:username]}")
    fail 'Could not add the user!' unless $?.success?

    puts 'Setting the password'
    # Mental password command
    pswdcmd = "sh -c \"echo \"#{@c.config[:login][:password]}:#{@c.config[:login][:username]}\" | chpasswd\""
    system("sudo chroot #{@destination} #{pswdcmd}")
    fail 'Could not add the user!' unless $?.success?
  end
end
