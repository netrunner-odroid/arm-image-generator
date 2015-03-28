#!/usr/bin/env ruby

require_relative 'image'
require_relative 'imageconfig'

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: run.rb -c CONFIG'
  opts.on('-cCONFIG', '--config=CONFIG', 'Config file to build') do |c|
    options[:config] = c
  end
end.parse!

c = ImageConfig.new(options[:config])

i = Image.new(c)
i.run!
