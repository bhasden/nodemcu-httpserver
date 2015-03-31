return function (connection, args, formData)
    connection:send("HTTP/1.0 200 OK\r\nContent-Type: text/html\r\Cache-Control: private, no-store\r\n\r\n")
    connection:send('<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Arguments</title></head>')
    connection:send('<body>')
    connection:send('<h1>Wifi Setup</h1>')
    
    connection:send('<form method="POST">')
    connection:send('SSID:<br><input type="text" name="ssid"><br>')
    connection:send('Password:<br><input type="password" name="password"><br>')
    connection:send('<input type="submit" value="Submit">')
    connection:send('</form>')

    connection:send('</body></html>')

    if formData ~= nil then
        if formData["ssid"] ~= nil then
            if formData["password"] ~= nil then
                -- TODO: Figure out how to end the request normally before changing 
                -- TODO: the wifi configuration and restarting the device
                print("Updating wifi credentials")
                wifi.setmode(wifi.STATION)
                wifi.sta.config(formData["ssid"], formData["password"])
                print("Restarting device")
                node.restart()
            end
        end
    end
end
