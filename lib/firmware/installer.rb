class FimrwareInstaller
  def initialize(config)
    @c = config
    @dev = %w(sys proc dev)
    # Source the right backend
    require_relative "#{@c.config[:firmware][:backend]}"
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
    system("sudo cp /usr/bin/qemu-arm-static #{@rootfs}/usr/bin/")
    @dev.each do |d|
      system('sudo', 'mount', '--bind', "/#{d}", "#{@rootfs}/#{d}")
    end
  end

  def unmount
    @dev.each do |d|
      fail "Failed to unmount #{d}" unless system('sudo',  'umount', "#{@rootfs}/#{d}")
    end
    system("sudo rm #{@rootfs}/usr/bin/qemu-arm-static")
  end

  def setup
    # Networking setup
    system("sudo cp /etc/resolv.conf #{@rootfs}/etc/resolv.conf")
    system("sudo chroot #{@rootfs} dpkg-divert --rename --quiet --add /sbin/start-stop-daemon")
    system("sudo chroot #{@rootfs} ln -s /bin/true /sbin/start-stop-daemon")
  end

  def cleanup
    system("sudo rm #{@rootfs}/etc/resolv.conf")
    system("sudo chroot #{@rootfs} dpkg-divert --rename --quiet --remove /sbin/start-stop-daemon")
  end

  private :mount, :unmount
end
