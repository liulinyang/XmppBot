require 'xmpp4r'
require 'xmpp4r/bytestreams'
require 'yaml'

Jabber::debug = true

ARGV[0] = 'husky@nj-incase/office'
ARGV[1] = 'test'
ARGV[2] = 'c:\\test\\batch.jar'

#fh = File.new(ARGV[2])



if ARGV.size != 3
  puts "Usage: #{$0} <jid> <description> <file>"
  exit
end

conf = YAML::load File.new('sendfile.conf')

cl = Jabber::Client.new(Jabber::JID.new(conf['jabber']['jid']))
puts "Connecting Jabber client..."
cl.connect
puts "Authenticating..."
cl.auth conf['jabber']['password']

puts "Starting local Bytestreams server"
#bss = Jabber::Bytestreams::SOCKS5BytestreamsServer.new(conf['local']['port'])
#conf['local']['addresses'].each { |address|
#  bss.add_address(address)
#}

bss = Jabber::Bytestreams::StreamHost.new('proxy.nj-incase', '10.64.12.30', '7777')
#sleep 10
ft = Jabber::FileTransfer::Helper.new(cl)
#ft.allow_bytestreams = false
file_size = File.size(ARGV[2])
source = Jabber::FileTransfer::FileSource.new(ARGV[2])
source.length=(file_size)
puts "Offering #{source.filename} to #{ARGV[0]}"
stream = ft.offer(Jabber::JID.new(ARGV[0]), source, ARGV[1])

if stream
  puts "Starting stream initialization (#{stream.class})"

  if stream.kind_of? Jabber::Bytestreams::SOCKS5BytestreamsInitiator
    stream.add_streamhost(bss)
#    (conf['proxies'] || []).each { |proxy|
#      puts "Querying proxy #{proxy}"
#      stream.add_streamhost proxy
#    }
    puts "Offering streamhosts " + stream.streamhosts.collect { |sh| sh.jid }.join(' ')

    stream.add_streamhost_callback { |streamhost,state,e|
      case state
        when :connecting
          puts "Connecting to #{streamhost.jid} (#{streamhost.host}:#{streamhost.port})"
        when :success
          puts "Successfully using #{streamhost.jid} (#{streamhost.host}:#{streamhost.port})"
        when :failure
          puts "Error using #{streamhost.jid} (#{streamhost.host}:#{streamhost.port}): #{e}"
      end
    }
  end

  stream.open
  if stream.kind_of? Jabber::Bytestreams::SOCKS5BytestreamsInitiator
    puts "Using streamhost #{stream.streamhost_used.jid} (#{stream.streamhost_used.host}:#{stream.streamhost_used.port})"
  end

  while buf = source.read

    print "#{buf.size}."
#    $stdout.flush
    stream.write buf
    stream.flush
  end
  puts "!"
  sleep 5
  stream.close

else
  puts "Peer declined"
end

cl.close
