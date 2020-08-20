Commands = require './commands'
Botville_data = require './botville_data'
Client = require './client'
Util = require './util'
Handlers = require './handlers'

help = """
botville claim <bot>             Claim a bot
botville invite <bot> <#channel> Add bot to channel
botville remove <bot> <#channel> Remove bot from channel
"""

log = (val) ->
  console.log val
  return val

Botville =
  _test: (args, msg) ->
    if msg.author.tag != "glingy#9525"
      msg.channel.send "Sorry, you shouldn't even know this exists..."
      return
    user = log Commands.who.handle args, msg, true
    Client.guilds.fetch Botville_data.ids.guild
      .then (guild) -> 
        member = guild.member user[1]
        newMember member
          .then ->
            msg.channel.send "Done!" 
      .catch (error) -> console.log error
  _test2: (args, msg) ->
    if msg.author.tag != "glingy#9525"
      msg.channel.send "Sorry, you shouldn't even know this exists..."
      return
    guild = Client.guilds.resolve Botville_data.ids.guild
    console.log args
    channel = guild.channels.resolve args[2]

    console.log channel
    console.log channel.permissions
    console.log channel.permissionOverwrites
  claim: (args, msg) ->
    botname = args
      .slice 2
      .join ' '
    user = Util.getFilteredUser botname, msg, (member) ->
      member.user.bot && !member.roles.cache.has Botville_data.ids.claimed
    if user == undefined
      msg.channel.send "Sorry, I didn't find an unclaimed bot by that name."
      return
    msg.channel.send "I found a bot named `#{user[1].username}`! Is that right?"
    Handlers.set msg.author.tag, ['botville-confirm', msg.channel.id, user[1].id]
  invite: (args, msg) ->
    channel = undefined
    found = 0
    for arg, i in args
      match = arg.match /<#([0-9]+)>/
      if match && match[1] && channel = msg.channel.guild.channels.resolve match[1]
        found = i
        break
    if !channel
      msg.channel.send "Sorry, I can't find the channel. Please try again."
      return
    if channel.parent.id != Botville_data.ids.bots
      msg.channel.send "Bots don't belong there"
      return
    potentialOwners = channel.permissionOverwrites.array()
      .filter (permission) ->
        permission.deny.bitfield == 0 && permission.allow.bitfield == 388160 && permission.type == 'member'
    if potentialOwners.length == 0
      msg.channel.send "Weird. I can't find the bot that runs that channel."
      return
    bot = Client.guilds.resolve Botville_data.ids.guild
        .members.resolve potentialOwners[0].id
    if bot == undefined 
      msg.channel.send "Weird. I can't find the bot that runs that channel."
      return
    owner = bot.roles.cache.find (role) -> role.name.startsWith "Owner: "
    if owner == undefined
      msg.channel.send "Weird. I can't find the owner of the bot that runs that channel."
      return
    owner = owner.name.slice 7
    if msg.author.tag != owner
      msg.channel.send "You aren't the owner of that channel."
      return
    if found == 2
      msg.channel.send "Sorry, I can't find the bot to add to #{channel}. Please try again."
    botname = args.slice 2, found
      .join ' '
    msg.channel.send botname
    bot = Util.getFilteredUser botname, msg, (member) ->
      member.user.bot && member.roles.cache.has Botville_data.ids.claimed
    if bot == undefined
      msg.channel.send "Sorry, I didn't find a claimed bot by that name."
      return
    if channel.permissionOverwrites.has bot[1].id
      msg.channel.send "That bot is already on that channel."
      return
    msg.channel.send "I am going to invite `#{bot[1].username}` to #{channel}. Is that what you want?"
    Handlers.set msg.author.tag, ['botville-confirminvite', 'invite', bot[1].id, channel.id]
    
  remove: (args, msg) ->
    channel = undefined
    found = 0
    for arg, i in args
      match = arg.match /<#([0-9]+)>/
      if match && match[1] && channel = msg.channel.guild.channels.resolve match[1]
        found = i
        break
    if !channel
      msg.channel.send "Sorry, I can't find the channel. Please try again."
      return
    if channel.parent.id != Botville_data.ids.bots
      msg.channel.send "There aren't any bots there to remove."
      return
    potentialOwners = channel.permissionOverwrites.array()
      .filter (permission) ->
        permission.deny.bitfield == 0 && permission.allow.bitfield == 388160 && permission.type == 'member'
    if potentialOwners.length == 0
      msg.channel.send "Weird. I can't find the bot that runs that channel."
      return
    bot = Client.guilds.resolve Botville_data.ids.guild
        .members.resolve potentialOwners[0].id
    if bot == undefined 
      msg.channel.send "Weird. I can't find the bot that runs that channel."
      return
    owner = bot.roles.cache.find (role) -> role.name.startsWith "Owner: "
    if owner == undefined
      msg.channel.send "Weird. I can't find the owner of the bot that runs that channel."
      return
    owner = owner.name.slice 7
    if msg.author.tag != owner
      msg.channel.send "You aren't the owner of that channel."
      return
    if found == 2
      msg.channel.send "Sorry, I can't find the bot to remove from #{channel}. Please try again."
    botname = args.slice 2, found
      .join ' '
    bot = Util.getFilteredUser botname, 
        channel: channel
      , (member) ->
        member.user.bot && member.roles.cache.has Botville_data.ids.claimed
    if bot == undefined
      msg.channel.send "Sorry, I didn't find a bot by that name in that channel."
      return
    if !channel.permissionOverwrites.has bot[1].id
      msg.channel.send "Sorry, I didn't find a bot by that name in that channel."
      return
    msg.channel.send "I am going to remove `#{bot[1].username}` from #{channel}. Is that what you want?"
    Handlers.set msg.author.tag, ['botville-confirminvite', 'remove', bot[1].id, channel.id]
    

# params - 'remove'/'invite', bot id, channel id
Handlers.register 'botville-confirminvite', (msg, params) ->
  if msg.content.toLowerCase()[0] == 'y'
    guild = Client.guilds.resolve Botville_data.ids.guild
    channel = guild.channels.resolve params[2]
    permissions = channel.permissionOverwrites.array()
    if params[0] == 'remove'
      permissions = permissions.filter (perm) ->
        console.log perm.id, params[1]
        perm.id != params[1]
      console.log permissions
      channel.overwritePermissions permissions
      bot = guild.members.resolve params[1]
      msg.channel.send "`#{bot.user.username}` has been removed from #{channel}."
    else
      permissions.push
        id: params[1]
        type: "member"
        allow: 388160
        deny: 1
      console.log permissions
      channel.overwritePermissions permissions
      bot = guild.members.resolve params[1]
      msg.channel.send "`#{bot.user.username}` has been added to #{channel}."
  else if msg.content.toLowerCase()[0] == 'n'
    msg.channel.send "Sorry I found the wrong one. :(\nIf I'm having trouble understanding, try mentioning the bot instead of using its name."
  else
    msg.channel.send "Sorry, I don't quite understand that... Is that right?"
    return
  console.log params, params[0]
  Handlers.set msg.author.tag
    


Handlers.register 'botville-confirm', (msg, params) ->
  if msg.content.toLowerCase()[0] == 'y'
    try
      console.log "Hello!"
      console.log Botville_data.ids.guild
      console.log Client.guilds.resolveID msg.channel.guild
      guild = Client.guilds.resolve Botville_data.ids.guild
      console.log guild
      channel = guild.channels.resolve params[0]
      console.log channel, params[0]
      bot = channel.members.get params[1]
      console.log bot, params
      newChannel = await guild.channels.create bot.displayName, 
        type: "text",
        parent: Botville_data.ids.bots
        permissionOverwrites: [
          id: bot.user.id
          allow: 388160
        ],
        reason: "#{msg.author} asked me to!"
      botrole = bot.roles.cache.find (role) ->
          !(role.name == '@everyone')
      botrole.edit
        name: "Owner: #{msg.author.tag}"
      
      bot.roles.add Botville_data.ids.claimed
      console.log newChannel
      
      msg.channel.send "Cool! Your new channel is #{newChannel}!"
    catch e
      msg.channel.send "Uh oh... Something's broken..."
      console.log e
    
  else if msg.content.toLowerCase()[0] == 'n'
    msg.channel.send "Sorry I found the wrong one. :(\nIf I'm having trouble understanding, try mentioning the bot instead of using its name."
  else
    msg.channel.send "Sorry, I don't quite understand that... Did I find the right bot?"
    return
  console.log params, params[0]
  Handlers.set msg.author.tag
    

  
    
Commands.__add 'botville',
  handle: (args, msg) ->
    if msg.channel.guild.id != Botville_data.ids.guild
      msg.channel.send "Sorry, that command is unavailable on this server."
    if Botville[args[1]]
      Botville[args[1]] args, msg
    else
      msg.channel.send "**Botville Management**```#{help}```"
  info: 'Botville Management'
  help: help

#checkName = (member) ->
  #if member.nickname
  #  if member.nickname.indexOf ' ' != -1
  #    #member.setNickname member.nickname.replace / /g, '_'
  #else
  #  if member.user.username.indexOf ' ' != -1
  #    #member.setNickname member.user.username.replace / /g, '_'
  #console.log member

newMember = (member) ->
  if member.guild.id == Botville_data.ids.guild # If this is in the Botville server,
    #checkName member
    if !member.user.bot
      member.roles.add Botville_data.ids.human # if it's a person, give them a role. If it's a bot ignore them for now
    else 
      # It's a bot! Remove all permissions from its role or give it a role
      if member.roles.cache.array().length > 2
        member.roles.remove member.roles.cache.filter (role) ->
          !(role.name == '@everyone')
      if member.roles.cache.array().length == 1 # If it doesn't have a built-in role...
        await Client.guilds.fetch Botville_data.ids.guild
          .then (guild) -> guild.roles.create
            data:
              name: member.user.username
              managed: true
          .then (role) -> member.roles.add role
      role = member.roles.cache.find (role) ->
        role.name != '@everyone'
      role.setPermissions 0
      Client.channels.fetch Botville_data.ids.serverinfo
        .then (channel) -> channel.send "Welcome #{member.user.username}!\nYour owner can claim you in the <#745737786233061437> channel!"

module.exports =
  newMember