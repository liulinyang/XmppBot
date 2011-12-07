require 'rubygems'
require 'win32/changenotify'
include Win32
filter = ChangeNotify::FILE_NAME | ChangeNotify::DIR_NAME | ChangeNotify::LAST_WRITE
path   = 'c:/testware/result'

puts 'starting....'

mainthread = Thread.current

Thread.new  do
  cn = ChangeNotify.new(path, true, filter)
  cn.wait{ |arr|
    arr.each{ |info|
      p info.file_name
      p info.action
    }
  }
  cn.close
end

Thread.new {
  loop {
    puts "Input str: "
    str =  STDIN.gets
    puts ">>> #{str}"
    mainthread.wakeup
  }
}



Thread.stop

puts 'exit....'







#if ARGV.size < 2
#    puts "Usage: stakeout.rb <command> [files to watch]+"
#    exit 1
#  end
#
#  command = ARGV.shift
#  files = {}
#
#  ARGV.each do |arg|
#    Dir[arg].each { |file|
#      files[file] = File.mtime(file)
#    }
#  end
#
#  loop do
#
#    sleep 1
#
#    changed_file, last_changed = files.find { |file, last_changed|
#      File.mtime(file) > last_changed
#    }
#
#    if changed_file
#      files[changed_file] = File.mtime(changed_file)
#      puts "=> #{changed_file} changed, running #{command}"
#      system(command)
#      puts "=> done"
#    end
#
#  end
