require 'taf'
require 'husky_bot'

#Feature = 'log'
# Feature = 'install'

Feature = 'policy'

ClientName = "#{Feature}"
USER = "#{Feature}@nj-incase"
PASS = "#{Feature}"
JID = "#{Feature}@nj-incase/bot"
#ROOM = 'status@conference.nj-incase/policy'
ROOM = "status@conference.nj-incase/#{Feature}"

mybot = Husky::Bot.new(ClientName, USER, PASS, JID, ROOM)

#mybot.unregister

#begin
#  mybot.register
#
#rescue Jabber::ServerError  =>  e
#  puts e
#end


mybot.start








