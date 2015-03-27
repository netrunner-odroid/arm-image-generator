#!/usr/bin/env ruby

require_relative 'image'
require_relative 'imageconfig'

c = ImageConfig.new(ARGV[0])

i = Image.new(c)
i.run!
