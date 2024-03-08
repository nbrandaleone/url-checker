require "http/client"
require "log"

module StatusChecker
	private def self.get_status(url : String)
		res = HTTP::Client.get url
		{url, res.status_code}
	rescue e : Exception
		{url, 999} 									# We are using status_code 999 to indicate an error. Otherwise, we could pass along the Exception (as a String)
	end														# This is simpler than passing along a union type of various Error types, {String, Int32 | Exception}

	def self.run(url_stream, workers : Int32)
		countdown = Channel(Nil).new(workers)
		Channel({String, Int32}).new.tap { |url_status_stream|
		  spawn(name: "supervisor") do	# Supervisor will close downstream channel when upstream channel `url_stream` is closed
			  workers.times {
				  countdown.receive
			  }
			  url_status_stream.close
		  end
			workers.times { |w_i|
				spawn(name: "worker_#{w_i}") do
					loop do
						url = url_stream.receive
						result = get_status(url)
						url_status_stream.send result
					end
				rescue Channel::ClosedError
					Log.context.set fiber_info: Fiber.current.name
	        Log.info {"channel stream was closed"}
				ensure
					countdown.send nil
				end
			}
		}
	end

end # End of module
