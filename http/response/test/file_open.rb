require 'get_process_mem'

mem = GetProcessMem.new
puts mem.kb

a = File.new("test","r")
puts mem.kb

puts a.read(100)
puts mem.kb

a.close
puts mem.kb


