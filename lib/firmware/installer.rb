class FimrwareInstaller
  def initialize(config)
    @c = config
    @dev = %w(sys proc dev)
    # Source the right backend
    require_relative "#{@c.config[:firmware][:backend]}"
  end

  def run_in_chroot(cmd)
    system("sudo chroot #{@rootfs} #{cmd}")
  end

  def install(config)
    @rootfs = config[:rootfs]
    @bootfs = config[:bootfs]
    begin
      mount
      setup
      backend_install
    ensure
      cleanup
      unmount
    end
  end

  def mount
    system("sudo cp #{QEMU_ARM_STATIC} #{@rootfs}/usr/bin/")
    @dev.each do |d|
      system('sudo', 'mount', '--bind', "/#{d}", "#{@rootfs}/#{d}")
    end
  end

  def unmount
    @dev.each do |d|
      fail "Failed to unmount #{d}" unless system('sudo',  'umount', "#{@rootfs}/#{d}")
    end
    system("sudo rm #{@rootfs}/#{QEMU_ARM_STATIC}")
  end

  def setup
    # Networking setup
    system("sudo cp /etc/resolv.conf #{@rootfs}/etc/resolv.conf")
  end

  def cleanup
    system("sudo rm #{@rootfs}/etc/resolv.conf")
  end

  private :mount, :unmount
end
