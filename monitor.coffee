{spawn} = require 'child_process'
Discord = require 'discord.js'
require('dotenv').config()

client = new Discord.Client()

client.on 'ready', () ->
  logChannel = client.channels.find (v) -> v.name == 'yertle-log'
  child = spawn 'yarn', ['start'],
    cwd: '.'
    shell: '/usr/local/bin/bash'

  child.stdout.setEncoding 'utf-8'
  child.stderr.setEncoding 'utf-8'
  console.log "Spawned! #{child.pid}"

  buffer = ''
  bufferTimeout = -1

  newData = (data) ->
    console.log data.trim()
    buffer += data.trim() + '\n'

    if bufferTimeout == -1
      bufferTimeout = setTimeout () ->
        logChannel.send "```#{buffer.trim().replace /```/g, ''}```", {split: true}
        buffer = ''
        bufferTimeout = -1
      , 5000


  child.stdout.on 'data', newData
  child.stderr.on 'data', newData

  cleanExit = () ->
    child.kill()
    process.exit()
  process.on 'SIGINT', cleanExit
  process.on 'SIGTERM', cleanExit

client.login process.env.YERTLE_MONITOR_TOKEN

client.on 'error', (e) ->
  console.log "MANAGER!: ", e
