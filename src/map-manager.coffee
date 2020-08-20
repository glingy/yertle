Storage = require './storage'
{download} = require './util'
Commands = require './commands'
Play = require './newplay'


Maps =
  save: (args, msg) ->
    if !args[2]
      msg.channel.send "I don't know what name to give this map."
      return
    if Storage.data.maps[args[2]] && Storage.data.maps[args[2]].owner != msg.author.tag
      msg.channel.send "Sorry. Only the author of a map can replace it"
    try
      if !msg.attachments || !msg.attachments.first()
        msg.channel.send "No map attached"
      download msg.attachments.first().url, (raw) ->
        try
          map = JSON.parse raw
          Storage.maps.write args[2], msg.author.tag, map
          msg.channel.send "Map saved as #{args[2]}."
        catch error
          msg.channel.send "Error downloading! #{error.message}"
    catch error
      msg.channel.send "Error downloading! #{error.message}"
  read: (args, msg) ->
    if !args[2]
      msg.channel.send "I don't know which map to read."
      return
    if (Storage.data.maps[args[2]])
      msg.channel.send "There is no map named #{args[2]}. Please use the full name."
      return
    msg.channel.send "Here is the map:",
      files: ["storage/maps/#{args[2]}.json"]
  play: (args, msg) ->
    if !args[2]
      msg.channel.send "I don't know which map to play."
      return
    Play.begin args[2], msg.author.tag, msg
  ###
  time: (args, msg) ->
    start = new Date
    for i in [1...10000]
      Storage.maps.read 'test'
    stop = new Date
    msg.channel.send "Time: #{stop - start}"
  ###

  list: (args, msg) ->
    console.log "List"
    maps = []
    maps = Object.keys(Storage.data.maps).reduce((str, map) ->
      str += "\n#{map} by #{Storage.data.maps[map].owner}"
    , '')
    console.log maps
    if maps.length == 0
      msg.channel.send "Sorry, I don't have any maps available right now."
    else msg.channel.send "```#{maps}```"
  restart: (args, msg) ->
    if !args[2]
      msg.channel.send "I don't know which map to play."
      return
    Play.begin args[2], msg.author.tag, msg, true

Commands.__add 'map',
  handle: (args, msg) ->
    if Maps[args[1]]
      Maps[args[1]] args, msg
    else
      msg.channel.send "I don't know how to #{args[1]} a map..."
  info: 'Text adventure game commands'
  help: """
map list                         List the available maps to play
map save <name> <attached JSON>  Save or update a map
map read <name>                  Read the source of a map
map play <name>                  Play a map
map restart <name>               Restart a map
"""