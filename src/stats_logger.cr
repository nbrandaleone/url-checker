require "./stats"
require "log"

module StatsLogger
  # Listen for results. Tally success and failures. Send results out on stats_stream
  def self.run(url_status_stream)
    Channel(Array({String, Stats::Info})).new.tap { |stats_stream|
			spawn(name: "stats_logger") do
				stats = Stats.new
					loop do
						url, result = url_status_stream.receive
						case result
						when 999
							stats.log_failure(url)
						when Int32  # Could also put in a if/then block to only allow values <400 as success
							stats.log_success(url)
						end # case

						# Creates a table for output. It prints it through every loop, which is not ideal
						data = stats.map { |k,v| {k,v}    #	[k, v["success"], v["failure"]]
						}
						# Log.info {"data object is #{data}"} => [{"https://amazon.com", {success: 4, failure: 0}},...]
						stats_stream.send data
					end # of loop
			rescue Channel::ClosedError
				Log.context.set fiber_info: Fiber.current.name
				Log.info { "input stream was closed"}
			ensure
				stats_stream.close
			end # spawn block
			}
	end # def

end  # End of module
