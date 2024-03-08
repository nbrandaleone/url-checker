require "log"

# This has changed since the tutorial.  It is easier to use a custom formatter than subclass Log
# It would still be nice to override, since I would like to adjust the date-time format
# Macro. Log.define_formatter MyFormat, "- #{severity}: #{message}"
struct MyFormat < Log::StaticFormatter
	def run
#		@formatter = Formatter.new do |severity, datetime, progname, message, io|
#			string " -"
			severity
			string " - "
			timestamp
			string " - "
			progname
			string " -- "
			message
			string " [ "
			context
			string " ]"
			#			data
			#io << datetime.to_s("%H:%M:%S") << "[ " << severity << "] " << "#" << Process.pid
			#io << "( Fiber: " << Fiber.current.name << " )"
      #io << " -- : " << message
	end
end
