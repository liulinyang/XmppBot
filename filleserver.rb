$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'husky_fileserver'

Husky::FileServe.new("install@nj-incase", 'install', 'c:\\test')
puts "Up and running!"
Thread.stop