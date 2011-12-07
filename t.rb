class TAFProxy

	def initialize
		@status =  Hash.new
		@keep_monitoring = true
	end

	# feed data into 'status'
	def get_status
		# do some stuff like parsing file under "result/report/current" and tcmtresult or sth else.
		@status = {
			:running => true,
			:did => 'policy-0010',
			:stat => {
				:pass => 10,
				:fail => 1,
				:skip => 2
			}
		}

		p @status
	end

	def exec_cmd(cmd)
		puts "executing #{cmd}"
	end

	def start
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

	def stop
		sleep 10
		@keep_monitoring = false

	end

	# def on_status_update(&block)
	# end
end


# usage
puts "..."
monitor = TAFProxy.new
monitor.start


# Thread.stop

# taf.on_status_change do |status|

	# handle updated status
	# is_running = status.running
	# current_did = status.did  # defined_id
	# stat = status.stat
# end

#
# taf.start


