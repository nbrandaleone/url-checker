require "./printer"
require "./stats_logger"
require "./status_checker"
require "./concurrency_util"
require "./config"
require "./diagnostic_logger"
require "log"

# Design:
# url generator -> [url] -> worker_0 -> [{url, result}] -> print
#													\_ worker_# How many threads or workers do we have

include ConcurrencyUtil

config = Config.load
Log.setup(:info, Log::IOBackend.new(formatter: MyFormat))
Log.context.clear

# Create Channels for multi-threading and communication (CSP)
interrupt = Channel(Nil).new

# Capture CTR-C signal
Signal::INT.trap do
	Log.context.set fiber_info: "trap"
	Log.info {"Shutting down program"}
	interrupt.send nil
end

# Read the config file every 2 seconds, and kick off a check of the URLs
url_stream = every(config.period, interrupt: interrupt) {
	Log.context.set fiber_info: "main"
	Log.info {"sending urls"}  # Log.info &.emit("User logged in", user_id: 42)
	Config.load.urls
}

# We have a pipeline of fibers doing the work.
result_stream = StatusChecker.run(url_stream, workers: config.workers)
stats_stream = StatsLogger.run(result_stream)
done = Printer.run(stats_stream)

# Put main thread into background, so we guarantee background threads will run. Normally sleep or Fiber.yield
# Wait on done channel sentinel
done.receive?

puts "\rEnd of program"
