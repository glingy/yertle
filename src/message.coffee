Commands = require './commands'
Handlers = require './handlers'
{parseArgs, prompt} = require './util'
History = require './history'
Botville_data = require './commands/botville_data'

module.exports =
  handle: (msg, client, preventRecursion) ->
    if msg.author == client.user
      return
    #if msg.author.tag == 'glingy#9525'#'Simbot#7308'
    #  msg.delete()
      #(msg.channel.send ':turtle: ' + msg.content).catch (e) -> console.log e

    if msg.author.bot
      #if msg.author.tag == 'glingy#9525'#'Simbot#7308'
      #  msg.edit '🐢 ' + msg.content
      return
    if !process.env.DEV && msg.channel.guild && msg.channel.guild.id == Botville_data.ids.guild
      if msg.channel.id != Botville_data.ids.botmanagement && 
          msg.channel.id != Botville_data.ids.yertle && 
          msg.channel.id != Botville_data.ids.testing
        return

    if msg.content == '.' && !preventRecursion
      History.handle msg
      return

    History.set msg.author.tag, msg.content

    if !Handlers.run msg
      if msg.content[0] == prompt
        msg.content = (msg.content.slice 1).toLowerCase()
        args = parseArgs msg.content
        if Commands[args[0]] && Commands[args[0]].handle
          Commands[args[0]].handle args, msg
        else
          msg.channel.send "#{args[0]}: command not found"
    Storage.save()

Storage = require './storage'
