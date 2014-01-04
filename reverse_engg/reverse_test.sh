#!/bin/bash
# Start the session
curl -L --max-redirs 20 -v -i -H "Accept: application/json" -X POST http://localhost:4444/wd/hub/session -d '{"desiredCapabilities":{"javascriptEnabled":false,"version":"","rotatable":false,"takesScreenshot":true,"cssSelectorsEnabled":true,"browserName":"firefox","nativeEvents":false,"platform":"ANY"}}'

#Get all sessions

curl -L --max-redirs 20 -v -i -H "Accept: application/json" -X GET http://localhost:4444/wd/hub/sessions

# curl -L --max-redirs 20 -v -i -H "Accept: application/json" -X GET http://localhost:4444/wd/hub/session/asdbasd

# Goto URL
curl -L --max-redirs 20 -v -i -H "Accept: application/json" -X POST http://localhost:4444/wd/hub/session/8ecea20a-7e63-41b3-94bc-b9611e8043ec/url -d '{"url":"http://www.google.com"}'

# Refresh URL
curl -L --max-reirs 20 -v -i -H "Accept: application/json" -X POST http://localhost:4444/wd/hub/session/8ecea20a-7e63-41b3-94bc-b9611e8043ec/refresh

# Delete the session
curl -L --max-redirs 20 -v -i -H "Accept: application/json" -X DELETE http://localhost:4444/wd/hub/session/412d8bd7-105f-47dc-937b-a7feab6a2aa9

# Take screenshot
curl -H "Accept: application/json" -X GET http://localhost:4444/wd/hub/session/8ecea20a-7e63-41b3-94bc-b9611e8043ec/screenshot

# Delete the session
curl -L --max-redirs 20 -v -i -H "Accept: application/json" -X DELETE http://localhost:4444/wd/hub/session/412d8bd7-105f-47dc-937b-a7feab6a2aa9
