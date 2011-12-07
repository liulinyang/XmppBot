require 'taf'
require 'husky_bot'

#Feature = 'log'
#Feature = 'install'

#Feature = 'policy'
Feature = ARGV[0]
puts "#{Feature}"
#exit
ClientName = "#{Feature}"
USER = "#{Feature}@nj-incase"
PASS = "#{Feature}"
JID = "#{Feature}@nj-incase/bot"
#ROOM = 'status@conference.nj-incase/policy'
TAF = "c:\\testware\\result\\#{Feature}_status.xml"
ROOM = "status@conference.nj-incase/#{Feature}"

mybot = Husky::Bot.new(ClientName, USER, PASS, JID, TAF, ROOM)

#mybot.unregister

#begin
#  mybot.register
#
#rescue Jabber::ServerError  =>  e
#  puts e
#end


mybot.start








