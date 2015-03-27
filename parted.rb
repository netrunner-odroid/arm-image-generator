# Class to setup partition of a image
class Parted
  def setup(file = 'debian.img')
    fail "Can't find file!" unless File.exist? file
    system("parted #{file} < parted.txt")
  end
end
