Client = require './client'
Store = require './storage'
History = require './history'
Message = require './message'
Botville = require './botville'
require './map-manager'
require('dotenv').config()
require './keepalive'

Client.on 'ready', (msg) ->
  console.log "Hello World! Logged in as #{Client.user.tag}!"

Client.on 'message', (msg) ->
  if msg.channel.name == 'yertle-log' then return
  Message.handle msg, Client

Client.on 'guildMemberAdd', (member) ->
  Botville.newMember member

Client.on 'messageDelete', (msg) ->
  if msg.author == Client.user
    msg.channel.send msg.content

Client.on 'error', (e) ->
  console.log "ERROR!!!!"
  console.log e

Client.login process.env.YERTLE_TOKEN

