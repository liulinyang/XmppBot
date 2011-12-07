require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/muc'
require 'xmpp4r-simple'
require 'xmpp4r/bytestreams'
#require 'xmpp4r/muc/helper/mucclient'

module Husky
  class Bot
    include Jabber

    Jabber::debug = true
    # const definition

    # update status every 2 seconds
    STATUS_UPDATE_INTERVAL = 2

    
    # name of test client
    attr_reader :name
    attr_reader :bot
    attr_reader :jid
    attr_reader :room


    def initialize(clientName, user, pass, jid, taf, room = nil)
      @name = clientName
      @user = user
      @pass = pass
      @jid = jid
      @room = room
      @bot = Jabber::Client.new(JID::new(@jid))

#      @taf = TAF.new('C:\\testware\\result\\status.xml')
      @taf = TAF.new(taf)
      @queue = Queue.new
      @bss = nil
      @keep_update = true
      @muc_list = Array.new
#      @create_new_account = create_new_account
    end

    # register the bot with Jebber server

    # All starts with being registerd with "bot ID", which is the IP of TAF
    # controller. (Any better idea than ip addree? )  
    def register
      #      @ip = get_ip_address
      
      # The usual procedure
      @bot ||= Jabber::Client.new(Jabber::JID.new(@jid))
      puts "Connecting"
      @bot.connect unless @bot.is_connected?

      # Registration of the new user account
      puts "Registering..."

      begin
        @bot.register(@pass)
      rescue Jabber::ServerError => e
        if e.to_s =~ /conflict/
          puts "#{@user} has already be register, which is ok as well"
          puts "Successful"
          return true
        else
          puts "Error: #{e}"
          #          cl.close
          return false
        end
      end
    end

    def unregister
      # The usual procedure
      cl = Jabber::Client.new(Jabber::JID.new(@user))
      puts "Connecting"
      cl.connect

      # we need auth self firstly before remove self off the list
      cl.auth(@pass)

      # Registration of the new user account
      puts "Unregistering..."
      cl.remove_registration
      puts "Successful"

      # Shutdown
      cl.close
    end


    # Direct access to the underlying Roster helper.
    def roster
      return @roster if @roster
      @roster = Roster::Helper.new(@bot)
    end

    def login
      #    Jabber::Simple.new(@user, @pass, "idle")
      #    @bot = Client.new(JID::new('policy@nj-incase/bot'))

      @bot ||= Jabber::Client.new(JID::new(@jid))

#      uri = '//http://jabberd.eu/'
#      @bot ||= Jabber::HTTPBinding::Client.new(JID::new(@jid))
      @bot.connect unless @bot.is_connected?
      @bot.auth(@pass)
      @bot.send(Jabber::Presence.new.set_show(:chat).set_status('Here i am...'))

      #      mainthread = Thread.current

      # setup msg handle
      @bot.add_message_callback do |message|
        #        p message
        if message.type != :error
          queue(:received_messages) << message unless message.body.nil?
        end
      end

      # always allow other guys add me into their buddy list
      roster.add_subscription_callback do |roster_item, presence|
        if presence.type == :subscribed
          queue(:new_subscriptions) << [roster_item, presence]
        end
      end

      # automatically accepts subscriptions
      roster.add_subscription_request_callback do |roster_item, presence|
        puts "Accept request from #{presence.from}!"
        roster.accept_subscription(presence.from)
        #        if accept_subscriptions?
        #          roster.accept_subscription(presence.from)
        #        else
        #          queue(:subscription_requests) << [roster_item, presence]
        #        end
      end
    end


    def join_chat_room(room)
      #@muc = Jabber::MUC::SimpleMUCClient.new(@bot)

      muc = Jabber::MUC::MUCClient.new(@bot)
      muc.add_message_callback do |m|
        puts m.body
        p @name
        p m.from

        # Message time (e.g. history)
        time = nil
        m.each_element('x') { |x|
          if x.kind_of?(Delay::XDelay)
            time = x.stamp
          end
        }
        unless time.nil?  # ok, history message
          p time
        end

        #
        # !notice: we don't response to message sent from self and anyother bot.
        #
        #        unless m.body.nil? or m.from.resource == @name or not time.nil?
        unless m.body.nil? or m.from.resource != 'husky' or not time.nil?
          queue(:received_messages_on_muc) << m.body
        end
      end


      #      @muc.on_message do |time,nick,text|
      #        # puts (time || Time.new).strftime('%I:%M') + " <#{nick}> #{text}"
      ##        say("<--- #{text}")
      #        #      puts "#{nick}: #{text}"
      #        puts "#{text}"
      #        queue(:received_messages_on_muc) << text unless text.nil?
      #      end
      #    muc.join(Jabber::JID.new('linux-automation-status@conference.nj-incase/policy'))
      muc.join(Jabber::JID.new(room)) unless room.nil?
      @muc_list << muc
    end


    # change status text showing in the client
    # Here 
    # * nil (Available, no <show/> element)
    # * :away
    # * :chat (Free for chat)
    # * :dnd (Do not disturb)
    # * :xa (Extended away)
    def update_status(presence, status_message)
      #      @presence ||= presence
      #      @status_message ||= message
      #      stat_msg = Presence.new(@presence, @status_message)
      stat_msg = Jabber::Presence.new.set_show(presence).set_status(status_message)
      #      @bot.send(Jabber::Presence.new.set_show(:chat).set_status('Here i am...'))
      @bot.send(stat_msg)
    end

    

    def queue(queue)
      @queues ||= Hash.new { |h,k| h[k] = Queue.new }
      @queues[queue]
    end


    def dequeue(queue, non_blocking = false, max_items = 1, &block)
      puts "dequeu... #{queue}"
      queue_items = []
      max_items.times do
        queue_item = queue(queue).pop(non_blocking) # rescue nil
        break if queue_item.nil?
        queue_items << queue_item
        yield queue_item if block_given?
      end
      queue_items
      puts "done #{queue_items}"
    end


    def cmd_syntax_is_santiy?(cmd)
      if cmd =~ /^\\(taf|shell|get) (.+)$/
        return $1,$2
      else
        return nil, nil
      end
    end

    #
    # Delegate command processing to 'TAF'
    # Be carefule.
    # it need to be thread-safe
    #
    def handle_command(cmd, from=nil)
      cmd.chomp
      
      puts "handle incoming command: #{cmd}"
      type,cmd_str = cmd_syntax_is_santiy?(cmd)
      cmd_response = 'Invalid command. Please input "taf help" to see help message!'
      case type

      when 'taf'
        # taf related command
        if cmd_str == 'stop update'
          @keep_update = false
          cmd_response = 'Got it. Stopping update status!'
        elsif cmd_str == 'start update'
          @keep_update = true
          cmd_response = 'Start updating status'
        else
          method = cmd_str.split(' ').join('_')
          cmd_response = @taf.send("#{method}")
        end

        #         method = cmd_str.split(' ').join('_')
        #          cmd_response = @taf.send("#{method}")

      when 'shell'
        # just a common shell cmd
        # good, we need to start a new thread a start this task
        worker = Thread.new {
          @taf.handle_shell_cmd(cmd_str)
        }
        puts "worker is running and we'll waitin'"
        worker.join
        #        cmd_response = "#{cmd_str} start running"
        cmd_response = worker.value

      when 'get'
        return "Won't reponse with file request in room" if from.nil?
        
        # start to transfer a file by request, on 1-on-1 chatting
        t = Thread.new {
          begin
            deliver_file(cmd_str, from)
          rescue Exception => e
            puts e.backtrace.join("\n")
            puts "oops, in delivering file: #{cmd_str} -> #{from}, #{e}"
            "#{e}"
          end
        }
        puts "start sending file"
        t.join(10)
        cmd_response = t.value rescue "Internal error!"
        
      else # no valid type
        puts cmd_response
      end
      
      cmd_response
    end

    def deliver_file(filename, to)
      puts "#{filename} --> #{to}"

      #      bss = Jabber::Bytestreams::SOCKS5BytestreamsServer.new(conf['local']['port'])
      #      conf['local']['addresses'].each { |address|
      #        bss.add_address(address)
      #      }

      @bss ||= Jabber::Bytestreams::SOCKS5BytestreamsServer.new('7777')
      @bss.add_address('10.64.44.12')

      #      bss = Jabber::Bytestreams::StreamHost.new('proxy.nj-incase', '10.64.12.30', '7777')
      ft = Jabber::FileTransfer::Helper.new(@bot)
      #ft.allow_bytestreams = false

      source = Jabber::FileTransfer::FileSource.new(filename)
      #      file_size = File.size(ARGV[2])
      #      source.length=(file_size)
      puts "Offering #{source.filename}"
      stream = ft.offer(Jabber::JID.new(to), source)
      p stream

      if stream
        puts "Starting stream initialization (#{stream.class})"

        if stream.kind_of? Jabber::Bytestreams::SOCKS5BytestreamsInitiator
          stream.add_streamhost(@bss)
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
        #        sleep 5
        stream.close
        return "Sent ok!"

      else
        puts "Peer declined"
        return 'Peer declined'
      end
    end

    # start the main loop, acting as a server
    def start
      puts "starting..."
#      unless register
#        puts "cannot register, exiting..."
#        return
#      end

      login

      # Join the chat room based on invitaion
#            join_chat_room(@room)
      
      # processing conversation from client and chatting room

      Thread.new {
        loop {
          dequeue(:received_messages_on_muc) do |text|
            puts "Received muc message:  #{text}"
            if text == "shifs@SXSDFt"
              mainthread.wakeup
            end

            # it seems like we cannot
            response = handle_command(text)
            puts "After hanlde: #{response}"
            #            @muc.say(response) unless response.nil?

            m = Message::new(nil, "#{response}")

            begin
              @muc_list.first.send(m)
            rescue
              nil
            end
            
          end
        }
      }
      
      mainthread = Thread.current
      
      Thread.new {
        loop {
          dequeue(:received_messages) do |message|
            puts "Received message from #{message.from}: #{message.body}"
            #          @taf.send(message.body.to_sym)
            if (message.body == 'sshusky')
              mainthread.wakeup
            end

            if (message.type == :normal) and (message.body =~ /invites you to the room/)
              puts "Got a MUC invitation"
              # join the room
              begin
                room = "#{message.from}/#{@name}"
                join_chat_room(room)
              rescue Excpetion=>e
                e.backtrace.join("\n")
              end
              next
            end
            
            response  = handle_command(message.body, message.from)
            
            msg =Message.new(message.from)
            msg.type = :chat
            msg.body = response
            @bot.send(msg)
            
          end
        }
      }

      # setting up to monitoring status
      puts "start update status thread"
      Thread.new {
        # for testing
        i = 0
        # every STATUS_UPDATE_INTERVAL seconds wake up

        loop do
          if @keep_update
            state = (@taf.is_complete? ? :chat : :dnd)
            #          p state

            status_message = @taf.presence_status_message
            status_message = "#{status_message} + #{i} seconds "

            # append info about which test case is running
            if(state == :dnd)
              cur = @taf.current_case
              status_message = "Executing {#{cur}} ... #{status_message}"
            end

            update_status(state, status_message)
            i = i + 1
          end
          sleep STATUS_UPDATE_INTERVAL
        end
      }

      Thread.stop
      puts "exiting...."
    end

  end
end


#
#
#xmpp = Client.new(JID::new('policy@nj-incase/bot'))
#xmpp.connect
#xmpp.auth('policy')
#
#
#
#
#muc = Jabber::MUC::SimpleMUCClient.new(xmpp)
##muc.join(Jabber::JID.new('linux-automation-status@conference.nj-incase/policy'))
#mainthread = Thread.current
#
#muc.on_message do |time,nick,text|
#  # puts (time || Time.new).strftime('%I:%M') + " <#{nick}> #{text}"
#  # say("<--- #{text}")
#  puts text
#  if text == 'husky'
#    mainthread.wakeup
#  end
#
#end
#
#muc.join(Jabber::JID.new('linux-automation-status@conference.nj-incase/policy'))
#
## m = Message::new(nil, 'hello everybody')
## muc.send m
#
#puts 'before'
#Thread.stop
#
#puts 'haha'


