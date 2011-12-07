# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'husky_fileserver'

class TestFileServer < Test::Unit::TestCase
  def test_foo
    assert(false, 'Assertion was false.')
    flunk "TODO: Write test"
    # assert_equal("foo", bar)
  end

  def test_file_server
    Husky::FileServe.new("install@nj-incase", 'install', 'c:\\test')
    puts "Up and running!"
    Thread.stop
  end
end
