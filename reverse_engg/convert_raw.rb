# ruby convert.rb <raw file path> <processed file name>
file = File.open(ARGV[0], "r")
file1 = File.open("./#{ARGV[1]}", "w")
file.each_line do |line|
  json = ""
  split = line.split(' ')
  if split[2] == "REQUEST"
    request = split[5] + ' ' + split[6]
    i = 7
    json = ""
    while !split[i].nil?
      json = json + " " + split[i] 
      i+=1
    end
  end
  file1.puts("#{request} #{json.strip}")
end
file1.close
