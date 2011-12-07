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
ROOM = "status@conference.nj-incase/#{Feature}"
TAF = "c:\\testware\\result\\#{Feature}_status.xml"



#mybot = Husky::Bot.new(ClientName, USER, PASS, JID, ROOM)

mybot = Husky::Bot.new('ec2009demo', 'ec2009demo@jabber.org', 'ec2009demo','ec2009demo@jabber.org/office', TAF)
#gtalk.start

#mybot.unregister

#begin
#  mybot.register
#
#rescue Jabber::ServerError  =>  e
#  puts e
#end


mybot.start








