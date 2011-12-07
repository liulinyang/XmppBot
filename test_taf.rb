# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'taf'

class TestTaf < Test::Unit::TestCase
  #  def test_foo
  #    assert(false, 'Assertion was false.')
  #    flunk "TODO: Write test"
  #    # assert_equal("foo", bar)
  #  end
  
  
  def test_get_status
    taf = Husky::TAF.new('C:\\testware\\result\\status.xml')
    5.times do
      p taf.is_complete?
      #    taf.get_status('install')
      #    taf.get_status('instalsfsl')
      p taf.show_status
      sleep 3
    end
  end

  def ttest_show_message
    taf = Husky::TAF.new('C:\\testware\\result\\status.xml')
    p taf.presence_status_message
  end

  def test_handle_shell_cmd
    puts 'start'
    taf = Husky::TAF.new('C:\\testware\\result\\status.xml')
    puts 'ok'
    taf.handle_shell_cmd('c:\\testware\\test.bat')
  end

  def test_current_case
    taf = Husky::TAF.new('C:\\testware\\result\\status.xml')
    p taf.current_case
  end


end
