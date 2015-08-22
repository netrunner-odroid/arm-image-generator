require 'tmpdir'

class Mount
  def self.mount(path)
    mntdir = Dir.mktmpdir

    unless path.nil?
      fail 'Mounting partition failed!' unless system('sudo',
                                                      'mount',
                                                      path,
                                                      mntdir)
    end

    yield mntdir
  ensure
    system('sudo',
           'umount',
           mntdir) unless path.nil?
  end
end
