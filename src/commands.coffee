Handlers = require './handlers'
{spawn} = require 'child_process'
{prompt, getUser} = require './util'


Handlers.register 'echo', (msg) ->
  if msg.content == "#{prompt}q"
    msg.channel.send 'Fine... I stopped. :slight_frown:'
    Handlers.set msg.author.tag, undefined
    return
  msg.channel.send (msg.content)

Handlers.register 'reverse', (msg) ->
  if msg.content == "#{prompt}q"
    msg.channel.send 'Fine... I stopped. :slight_frown:'
    Handlers.set msg.author.tag, undefined
    return
  msg.channel.send (msg.content.split('').reverse().join(''))

Commands =
  echo:
    handle: (args, msg) ->
      if args[1]
        user = Commands.who.handle ["who", args[1]], msg, true
        if user
          console.log user
          if user[1].tag == "glingy#9525"
            msg.channel.send "Nice try... \nI will echo you now. Type #{prompt}q to stop."
            Handlers.set msg.author.tag, 'echo'
            return
          if user[1].bot == true
            msg.channel.send "Sorry. I will not echo bots. They are my friends."
            return
          msg.channel.send "I will echo #{user[0]} now. They must press #{prompt}q to stop."
          Handlers.set user[1].tag, 'echo'
      else
        console.log msg.channel.members
        msg.channel.send "I will echo you now. Type #{prompt}q to stop."
        Handlers.set msg.author.tag, 'echo'
    info: "Echoes someone until they ask to stop"
    help: "echo [<name>]"
  dm:
    handle: (args, msg) ->
      if !msg.author.dmChannel
        msg.author.createDM().then () ->
          msg.author.dmChannel.send "Hello #{msg.author.username}!"
      else
        msg.author.dmChannel.send "Hello #{msg.author.username}!"
    info: "Starts a dm channel with me"

  reverse:
    handle: (args, msg) ->
      if args[1]
        user = Commands.who.handle ["who", args[1]], msg, true
        if user
          console.log user
          if user[1].tag == "glingy#9525"
            msg.channel.send "Nice try... \nI will reverse you now. Type #{prompt}q to stop."
            Handlers.set msg.author.tag, 'reverse'
            return
          if user[1].bot == true
            msg.channel.send "Sorry. I will not reverse bots. They are my friends."
            return
          msg.channel.send "I will reverse #{user[0]} now. They must press #{prompt}q to stop."
          Handlers.set user[1].tag, 'reverse'
      else
        console.log msg.channel.members
        msg.channel.send "I will reverse you now. Type #{prompt}q to stop."
        Handlers.set msg.author.tag, 'reverse'
    info: "Reverses someone until they ask to stop"
    help: "reverse [<name>]"

  info:
    handle: (args, msg) ->
      msg.channel.send 'Hello World!\nI am Yertle, a bot programmed by Gregory!\nFor help on commands, ask for `$help`.'
    info: "About Yertle!"
  who:
    handle: (args, msg, silent) ->
      if !args[1]
        msg.channel.send 'Please specify a name'
        return
      user = getUser(args[1], msg)
      if !(user[0] instanceof Array)
        console.log silent
        if (!silent) then msg.channel.send "#{user[0]} is #{user[1].tag}."
        return user
      else
        msg.channel.send "Please be more specific: #{(user.map (u) -> u[0]).join ', '}"
      return
    info: "Get the tag of a user"
    help: "who <part of nickname>"
  help:
    handle: (args, msg) ->
      if args[1] && args[1] != '-beta'
        if Commands[args[1]]
          if Commands[args[1]].help
            msg.channel.send "```#{args[1]}: #{Commands[args[1]].info}\n#{Commands[args[1]].help}```"
          else if Commands[args[1]].info
            msg.channel.send "```#{args[1]}: #{Commands[args[1]].info}```"
          else
            msg.channel.send "#{args[1]}: Indescribable command"
        else
          msg.channel.send "#{args[1]}: Unknown command"
      else
        hlp = '\n```'
        if args[1] == '-beta' then hlp += "Commands starting with _ are in beta.\n\n"
        for command, value of Commands
          if command[0] == '_' && (args[1] != '-beta' || command[1] == '_') then continue
          hlp += "#{(command + ' ').padEnd 10, ' '} #{value.info || 'Mysterious command'}\n"

        msg.channel.send hlp + '\n.          (without prompt) repeat last message```'
    info: 'Prints this help'
    help: 'help [<command>] [-beta]'
  src:
    handle: (args, msg) ->
      zip = spawn('zip', ['-ru', 'src.zip', 'src'], { stdio: [null, process.stdout, process.stderr]})
      zip.on 'exit', (code) ->
        if code == 0 || code == 12
          msg.channel.send 'Here is my current source: ',
            files: ['src.zip']
        else
          msg.channel.send "Error zipping source: Code #{code}"
    info: 'Shares a zip file of the source code'
  q:
    handle: (args, msg) ->
      msg.channel.send 'You are currently in command mode.'
    info: 'Exit current mode'
  __add: (name, cmd) ->
    Commands[name] = cmd

module.exports = Commands
