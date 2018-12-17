Discord = require 'discord.js'

client = new Discord.Client()
module.exports = client

Store = require './storage'
History = require './history'
Message = require './message'
require('dotenv').config()

client.on 'ready', (msg) ->
  console.log "Hello World! Logged in as #{client.user.tag}!"

client.on 'message', (msg) ->
  if msg.channel.name == 'yertle-log' then return
  console.log msg.author.tag + ": " + msg.content
  Message.handle msg

client.on 'messageDelete', (msg) ->
  if msg.author == client.user
    msg.channel.send msg.content

client.on 'error', (e) ->
  console.log e

client.login process.env.YERTLE_TOKEN
