require 'rubygems'
require 'json'
require 'selenium-webdriver'
require 'colorize'
require 'pry'

## Variables
@username = ARGV[0]
@key = ARGV[1]
@session_id = ARGV[2]
@user_id = ARGV[3]
@user_define = ARGV[4].to_i || 0
@test_logs = ""
@capabilities = true
@hub = ENV["HUB"] || "hub.browserstack.com"

if ARGV.size < 4
  puts "Usage HUB=<hub> ruby replay_script.rb <username> <key> <session_id> <user_id> <user_define 0 || 1 || 2> <browser || browserName> <browser_version || version> <os || platform> <os_version>" 
  exit 
end
if @user_define == 1 && ARGV.size < 9
  puts "Usage HUB=<hub> ruby replay_script.rb <username> <key> <session_id> <user_id> <user_define 0 || 1 || 2> <browser || browserName> <browser_version || version> <os || platform> <os_version>" 
end

# Input capabilities
def set_chrome_profile(caps)
  caps["chromeOptions"] = {}
  caps["chromeOptions"]["binary"] = ENV["CBINARY"]
end
def set_firefox_profile(caps)
  caps["firefox_binary"] = ENV["FBINARY"]
end
def create_driver
  caps = Selenium::WebDriver::Remote::Capabilities.new
  caps[:browserName] = @browserName
  caps["browserName"] = @browserName
  caps["platform"] = @platform
  caps[:platform] = @platform
  caps["version"] = @version
  caps[:version] = @version
  caps["browser"] = @browser
  caps["browser_version"] = @browser_version
  caps["os"] = @os
  caps["os_version"] = @os_version

  caps["browserstack.debug"] = "true"
  caps[:name] = "Replay Script for #{@user_id} #{@session_id}"
  caps[:build] = "Replay Scripts"
  if ENV["CBINARY"] != nil
    set_chrome_profile(caps)
  end
  if ENV["FBINARY"] != nil
    set_firefox_profile(caps)
  end
  driver = Selenium::WebDriver.for(:remote,
                                   :url => "http://#{@username}:#{@key}@#{@hub}/wd/hub",
                                   :desired_capabilities => caps)
  @my_session_id = driver.instance_variable_get("@bridge").instance_variable_get("@session_id")
end

def get_url
  sess_json = JSON.parse(`curl -s -u "#{@username}:#{@key}" "https://www.browserstack.com/automate/sessions/#{@session_id}.json?user_id=#{@user_id}"`)
  @client_time = sess_json["automation_session"]["duration"]
  return sess_json["automation_session"]["browser_url"]
end

def modify_capabilities(json)
  @capabilities = false
  mod_json = JSON.parse(json.strip)
  mod_json["desiredCapabilities"][:name] = "Replay Script for #{@user_id} #{@session_id}"
  mod_json["desiredCapabilities"][:build] = "Replay Scripts"
  mod_json["desiredCapabilities"][:project] = ""
  if (@user_define == 1)
    @browser = ARGV[5] || ""
    @browser_version = ARGV[6] || ""
    @os = ARGV[7] || ""
    @os_version = ARGV[8] || ""
    @browserName = ""
    @version = ""
    @platform = ""

    mod_json["desiredCapabilities"][:browserName] = ""
    mod_json["desiredCapabilities"][:version] = ""
    mod_json["desiredCapabilities"][:platform] = ""

    mod_json["desiredCapabilities"]["browser"] = @browser
    mod_json["desiredCapabilities"]["browser_version"] = @browser_version
    mod_json["desiredCapabilities"]["os"] = @os
    mod_json["desiredCapabilities"]["os_version"] = @os_version
  elsif (@user_define == 0)
    @browserName = mod_json["desiredCapabilities"]["browserName"]  || ""
    @version = mod_json["desiredCapabilities"]["version"] || ""
    @platform = mod_json["desiredCapabilities"]["platform"] || ""

    @browser = mod_json["desiredCapabilities"]["browser"] || ""
    @browser_version = mod_json["desiredCapabilities"]["browser_version"] || ""
    @os = mod_json["desiredCapabilities"]["os"] || ""
    @os_version = mod_json["desiredCapabilities"]["os_version"] || ""
  elsif (@user_define ==2)
    @browserName = ARGV[5]
    @version = ARGV[6]
    @platform = ARGV[7]
puts @browserName
puts @version
puts @platform
    mod_json["desiredCapabilities"][:browserName] = @browserName
    mod_json["desiredCapabilities"][:version] = @version
    mod_json["desiredCapabilities"]["platform"] = @platform

    mod_json["desiredCapabilities"]["browser"] = ""
    mod_json["desiredCapabilities"]["browser_version"] = ""
    mod_json["desiredCapabilities"]["os"] = ""
    mod_json["desiredCapabilities"]["os_version"] = ""
  end
  return mod_json.to_json
end

def get_logs
  raw_url = get_url
  @raw_logs = `curl -s -u "#{@username}:#{@key}" "#{raw_url}/logs?user_id=#{@user_id}"`
  @raw_logs.each_line do |line|
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
    if (@capabilities)
      json = modify_capabilities(json)
    end
    json.gsub!("'", "")
    @test_logs << "#{request} #{json.strip}\n"
  end
  @test_logs.strip!.gsub!("\n \n", "\n")
end

def simulate_test
  puts "Starting test for #{@session_id} with user_id #{@user_id} and replay_id #{@my_session_id}"
  @test_logs << "\nDELETE /session/#{@session_id}"
  start_time = Time.now
  a = true
  @test_logs.each do |line|
    next if line.strip.empty?
    if a
      a = false
      next
    end
    line.sub!(@session_id, @my_session_id)
    split = line.split(' ')
    i = 2
    json = ""
    while !split[i].nil?
      json = json + " " + split[i] 
      i+=1
    end
    puts ("\n##########################################################\n")
    puts("REQUEST: \n curl -L --max-redirs 20 -v -i -H \'Accept: application/json\' -X #{split[0]} http://#{@username}:#{@key}@#{@hub}/wd/hub#{split[1]} -d \'#{json.strip}\'".blue) 
    response = `curl -s -L --max-redirs 20 -i -H \'Accept: application/json\' -X #{split[0]} http://#{@username}:#{@key}@#{@hub}/wd/hub#{split[1]} -d \'#{json.strip}\'`
    puts ("\n----------------------------------------------------------\n")
    puts ("RESPONSE \n #{response}".green)
  end
  end_time = Time.now 
  @replay_time = (end_time-start_time).to_i
end
def print_times
  puts ("\n##########################################################".red)
  puts "#{@my_session_id} #{@session_id} Client Time = #{@client_time} secs and Replay Time = #{@replay_time} secs".red
  puts ("##########################################################\n".red)
end
get_logs
create_driver
simulate_test
print_times
