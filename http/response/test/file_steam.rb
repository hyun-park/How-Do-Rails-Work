File.open("test", "rb") do |file|
  while chunk = file.read(12)
    puts chunk
    puts "hi"
    sleep(0.5)
  end
end
