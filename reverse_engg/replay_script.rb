require 'rubygems'
require 'json'
require 'selenium-webdriver'
require 'pry'

## Variables
@username = "user_name"
@key = "key"
@session_id = ARGV[0]
@user_id = ARGV[1]
@user_define = ARGV[2].to_i || 0
@test_logs = ""
@capabilities = true

if ARGV.size < 2
  puts "Usage ruby replay_script.rb <session_id> <user_id> <user_define 0 || 1> <browser> <browser_version> <os> <os_version>" 
  exit 
end
if @user_define == 1 && ARGV.size < 7
  puts "Usage ruby replay_script.rb <session_id> <user_id> <user_define 0 || 1> <browser> <browser_version> <os> <os_version>" 
end

# Input capabilities

def create_driver
  caps = Selenium::WebDriver::Remote::Capabilities.new
  caps["browser"] = @browser
  caps["browser_version"] = @browser_version
  caps["os"] = @os
  caps["os_version"] = @os_version
  caps["browserName"] = @browserName
  caps["platform"] = @platform
  caps["version"] = @version

  caps["browserstack.debug"] = "true"
  caps[:name] = "Replay Script for #{@user_id} #{@session_id}"
  caps[:build] = "Replay Scripts"
  driver = Selenium::WebDriver.for(:remote,
                                   :url => "http://#{@username}:#{@key}@hub.browserstack.com/wd/hub",
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
  if (@user_define == 1)
    @browser = ARGV[3] || ""
    @browser_version = ARGV[4] || ""
    @os = ARGV[5] || ""
    @os_version = ARGV[6] || ""
    @browserName = ""
    @version = ""
    @platform = ""

    mod_json["desiredCapabilities"]["browserName"] = ""
    mod_json["desiredCapabilities"]["version"] = ""
    mod_json["desiredCapabilities"]["platform"] = ""

    mod_json["desiredCapabilities"]["browser"] = @browser
    mod_json["desiredCapabilities"]["browser_version"] = @browser_version
    mod_json["desiredCapabilities"]["os"] = @os
    mod_json["desiredCapabilities"]["os_version"] = @os_version
  else 
    @browserName = mod_json["desiredCapabilities"]["browserName"]  || ""
    @version = mod_json["desiredCapabilities"]["version"] || ""
    @platform = mod_json["desiredCapabilities"]["platform"] || ""

    @browser = mod_json["desiredCapabilities"]["browser"] || ""
    @browser_version = mod_json["desiredCapabilities"]["browser_version"] || ""
    @os = mod_json["desiredCapabilities"]["os"] || ""
    @os_version = mod_json["desiredCapabilities"]["os_version"] || ""
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
    @test_logs << "#{request} #{json.strip}\n"
  end
  @test_logs.strip!.gsub!("\n \n", "\n")
end

def simulate_test
  @test_logs << "\nDELETE /session/#{@session_id}"
  puts @test_logs
  start_time = Time.now
  @test_logs.each do |line|
    line.sub!(@session_id, @my_session_id)
    split = line.split(' ')
    i = 2
    json = ""
    while !split[i].nil?
      json = json + " " + split[i] 
      i+=1
    end
    puts ("\n##########################################################\n")
    puts("REQUEST: \n curl -L --max-redirs 20 -v -i -H \'Accept: application/json\' -X #{split[0]} http://#{@username}:#{@key}@hub.browserstack.com/wd/hub#{split[1]} -d \'#{json.strip}\'") 
    response = `curl -L --max-redirs 20 -v -i -H \'Accept: application/json\' -X #{split[0]} http://#{@username}:#{@key}@hub.browserstack.com/wd/hub#{split[1]} -d \'#{json.strip}\'`
    puts ("\n----------------------------------------------------------\n")
    puts ("RESPONSE \n #{response}")
  end
  end_time = Time.now 
  @replay_time = (end_time-start_time).to_i
end
def print_times
  puts ("\n##########################################################\n")
  puts "Client Time = #{@client_time} secs and Replay Time = #{@replay_time} secs"
  puts ("##########################################################\n")
end
get_logs
create_driver
simulate_test
print_times