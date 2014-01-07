require 'rubygems'
require 'selenium-webdriver'

file = File.open(ARGV[0], "r")
# Input capabilities
caps = Selenium::WebDriver::Remote::Capabilities.new
caps["browser"] = "IE"
caps["browser_version"] = "9.0"
caps["os"] = "Windows"
caps["os_version"] = "7"
caps["browserstack.debug"] = "true"
caps[:name] = "Testing Selenium 2 with Ruby on BrowserStack"

driver = Selenium::WebDriver.for(:remote,
                                 :url => "http://username:key@hub.browserstack.com/wd/hub",
                                 :desired_capabilities => caps)
session_id = driver.instance_variable_get("@bridge").instance_variable_get("@session_id")
file.each do |line|
  next if line.strip.empty?
  line.sub!('412db74eaaf664da6f283cd148a3482bc9b10064', session_id)
  split = line.split(' ')
    i = 2
    json = ""
    while !split[i].nil?
      json = json + " " + split[i] 
      i+=1
    end
  puts("REQUEST: curl -L --max-redirs 20 -v -i -H \'Accept: application/json\' -X #{split[0]} http://usersname:key@hub.browserstack.com/wd/hub#{split[1]} -d \'#{json.strip}\'") 
  `curl -L --max-redirs 20 -v -i -H \'Accept: application/json\' -X #{split[0]} http://usernam:key@hub.browserstack.com/wd/hub#{split[1]} -d \'#{json.strip}\'`
end
driver.quit
