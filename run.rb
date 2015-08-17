#!/usr/bin/env ruby

require_relative 'image'
require_relative 'imageconfig'

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: run.rb -c CONFIG'
  opts.on('-cCONFIG', '--config=CONFIG', 'Config directory') do |c|
    options[:config_dir] = c
  end
end.parse!

c = ImageConfig.new(options[:config_dir])
i = Image.new(c)
i.run!
