require 'tmpdir'

class Mount
  def self.mount(path)
    mntdir = nil

    unless path.nil?
      mntdir = Dir.mktmpdir
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
