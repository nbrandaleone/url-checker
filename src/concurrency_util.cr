require "log"

module ConcurrencyUtil
	def timer(time : Time::Span)
		Channel(Nil).new(1).tap { |ch|
			spawn(name: "timer") do
				sleep time
				ch.send(nil)
			end
		}
	end

	def every(period : Time::Span, interrupt : Channel(Nil), &block : -> Enumerable(T)) forall T
		Channel(T).new.tap { |out_stream|
			spawn(name: "generator") do
				loop do
					select
					when timer(period).receive
				  	block.call >> out_stream
					when interrupt.receive
						Log.context.set fiber_info: Fiber.current.name
				  	Log.info {"Shutting down program due to Interrupt"}
						break
				  end
	  		end
			ensure
				out_stream.close
			end
		}
	end
end # End of Module

module Enumerable(T)

	def >>(channel : Channel(T))
		spawn do
			each { |value|
				channel.send value
			}
		end
	end
end
