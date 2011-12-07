# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'husky_bot'
require 'taf'

class TestBot < Test::Unit::TestCase
  Feature = 'policy'

  ClientName = "#{Feature}"
  USER = "#{Feature}@nj-incase"
  PASS = "#{Feature}"
  JID = "#{Feature}@nj-incase/bot"
  ROOM = 'status@conference.nj-incase/policy'
  #  def test_foo
  #    assert(false, 'Assertion was false.')
  #    flunk "TODO: Write test"
  #    # assert_equal("foo", bar)
  #  end

  def test_command_handler
    

    bot = Husky::Bot.new(ClientName, USER, PASS, JID, ROOM)

#    bot.handle_command('test')
#    bot.handle_command('\\get  c:\\test\\a.txt')
#    bot.handle_command('tssest')
#    bot.handle_command('test')
#    bot.handle_command('taf status')
    bot.deliver_file('c:\\test\\a.txt', 'husky@nj-incase/office')
  end

  
end
