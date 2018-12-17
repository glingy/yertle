Store = require './storage'
Commands = require './commands'

History = {}
module.exports = History # recursive dependency

Message = require './message'


Store.data.history = Store.data.history || {}

History.set = (user, command) ->
  Store.data.history[user] = command

History.handle = (msg) ->
  if Store.data.history[msg.author.tag]
    msg.channel.send "(#{Store.data.history[msg.author.tag]})"
    msg.content = Store.data.history[msg.author.tag]
    Message.handle msg, true
