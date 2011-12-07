require 'rexml/document'
include REXML

module Husky

  class TAF
    def initialize(xmlfile)
      @status = Hash.new
      @running = nil
      @keep_monitoring = true
      #      @xml = Document.new(File.open(xmlfile))
      @status = nil
      @mutex = Mutex.new
      @xmlfile = xmlfile
      @cmd_handler_lock = Mutex.new # only 1 shell_cmd_handler is permit to run concurrently
      @cmd_handler_count = 0
    end
    

    # turn on TAF means, it's start
    #  - monitoring the status xml from TAF
    # => reponse with command
    # each command actio should be mutex?
    


    def is_complete?
      #      puts @xml.root.attributes['complete']
      xml = Document.new(File.open(@xmlfile))
      return 'yes' == xml.root.attributes['complete']
    end

    def current_case
      xml = Document.new(File.open(@xmlfile))
      e = XPath.first(xml, "//running")
      return e.text
    end
    
    def show_usage
      "Usage goes here"
    end

    def show_help
      "Help Message goes here"
    end


    # Only return the "Summary" element of each suite specified
  	# feed data into 'status'
    # return nil when 'suite' doesn't exist
    def get_status(suite=nil)
      @status ||= {}

      xml = Document.new(File.open(@xmlfile))
      if suite.nil?
        # query status of all 'suite'
        XPath.each(xml, "//details/suite") { |s|
          suite_name = s.attributes['name']
          @status[suite_name] = construct_status_hash_for_suite(s)
        }
      else
        s = XPath.first(xml, "//details/suite[@name=\"#{suite}\"]")
        if s.nil?
          puts "#{suite} doesn't exist, please check the name of suite"
          return nil
        end
        
        suite_name = s.attributes['name']
        @status[suite_name] = construct_status_hash_for_suite(s)
      end
      #      p @status
    end

    def show_status
      @mutex.synchronize {
        get_status
      }
      @status
    end

    # construct presence status message for pod client
    def presence_status_message
      status = show_status
      total = 0
      pass = 0
      fail = 0
      abort = 0

      status.each_value { |suite_summary|
        #        p suite_summary
        
        pass = pass + suite_summary["pass"].to_i
        fail += suite_summary["fail"].to_i
        abort += suite_summary["abort"].to_i
      }
      total = pass + fail + abort
      
      "Total:#{total} | Pass:#{pass} | Fail:#{fail} | Abort:#{abort}"
    end


    def construct_status_hash_for_suite (suite_node)
      attr_res = {}
      XPath.first(suite_node, "summary").attributes.each do |name, value|
        attr_res[name] = value
      end
      attr_res
    end


    def dispatch(text)
      "I'll dispatching the command message"
    end

 
    def exec_cmd(cmd)
      puts "executing #{cmd}"
    end
    
    # hanlde shell cmd
    def handle_shell_cmd(cmd)
      @cmd_handler_lock.synchronize{
        @cmd_handler_count += 1
      }
      
      # good, it avaible, just fire
      #      shell_cmd = "start cmd /c #{cmd}"
      puts "executing #{cmd}<---"

      begin
        rc = `#{cmd}`
      rescue Exception => ex
        rc = "#{ex.class}: #{ex.message}"
      end

      @cmd_handler_lock.synchronize{
        @cmd_handler_count -= 1
      }
      
      puts rc
      rc
    end
    

    def enable
      Thread.new do
        puts "starting monitoring taf..."
        while(@keep_monitoring) do
          # get status every 1 sec
          get_status
          sleep 1
        end
        puts "monitoring is over"
      end
    end
    

    def disble
      sleep 10
      @keep_monitoring = false
    end

    def running?
      @running
    end
    
    ########
    def running_status
      puts 'executing 0010'
    end

    def start
      puts "start..."
    end

    def pause
      puts "pausing..."
    end

    def resume
      puts 'resuming...'
    end

    def method_missing(*args, &block)
      #      puts args.shift
      return "method missing"
    end
    
  end
  
end
