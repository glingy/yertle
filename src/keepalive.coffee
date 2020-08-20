http = require 'http'

server = http.createServer {}, (req, res) ->
  res.end("OK")

server.listen process.env.PORT || 8080

interval = 0
server.on 'listening', ->
  console.log "Ping server listening!"
  interval = setInterval ->
    try 
      http.get process.env.URL || "http://localhost:8081", (res) ->
          if res.statusCode != 200
            console.log "ERROR! PING FAILED!"
            clearInterval interval
        .on 'error', (e) ->
          console.log e
    catch e
      console.log "ERROR! PING ERROR!"
  , 5000