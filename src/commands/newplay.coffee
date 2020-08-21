Handlers = require '../handlers'
{prompt, parseArgs} = require '../util'
Storage = require '../storage'

MapCommands =
  _exit:
    handle: (context) ->
      context.state.room = context.state.next_room
      doTurn '_enter', context, true
      return true
  _enter:
    handle: (context) ->
      doTurn 'l', context
  north:
    handle: ({cmd, state, out}) ->
      if out.length == 0
        out.push "You cannot go #{cmd.verb}."
      return false
  south:
    handle: (context) -> MapCommands.north.handle context
  west:
    handle: (context) -> MapCommands.north.handle context
  east:
    handle: (context) -> MapCommands.north.handle context
  take:
    prehandle: (context, cmd_names) ->
      {out} = context
      object = getObject context, cmd_names.object, cmd_names.container, context.state.room
      if !object
        context.allow = false
        return
      if object.location.room == '_inventory'
        out.push 'You already have that.'
        context.allow = false
        return

    handle: (context) ->
      {cmd, state, out} = context
      if cmd.object.location.container
        state.objects._inventory[cmd.object.location.name] = state.objects[cmd.object.location.room][cmd.object.location.container].objects[cmd.object.location.name]
        delete state.objects[cmd.object.location.room][cmd.object.location.container].objects[cmd.object.location.name]
      else
        state.objects._inventory[cmd.object.location.name] = state.objects[cmd.object.location.room][cmd.object.location.name]
        delete state.objects[cmd.object.location.room][cmd.object.location.name]
      out.push "#{cmd.object.location.name[0].toUpperCase() + cmd.object.location.name.slice 1} taken."
  put:
    prehandle: (context, cmd_names) ->
      context.cmd = {verb: cmd_names.verb}
      if cmd_names.container && !(context.cmd.container = getRootObject context, cmd_names.container)
        return
      if cmd_names.object && !(context.cmd.object = getRootObject context, cmd_names.object)
        return

      console.log "COMMAND", context.cmd

      {cmd, out} = context
      if !cmd.object
        context.allow = false
        return
      if cmd.object.location.room != '_inventory'
        out.push 'You do not have that.'
        context.allow = false
        return

    handle: (context) ->
      {cmd, state, out} = context
      if cmd.container
        console.log "CONTAINER!", state.objects._inventory, cmd.object.location.name
        state.objects[state.room][cmd.container.location.name].objects[cmd.object.location.name] = state.objects._inventory[cmd.object.location.name]
        delete state.objects._inventory[cmd.object.location.name]
      else
        state.objects[state.room][cmd.object.location.name] = state.objects._inventory[cmd.object.location.name]
        delete state.objects._inventory[cmd.object.location.name]
      out.push "#{cmd.object.location.name[0].toUpperCase() + cmd.object.location.name.slice 1} placed."



  look:
    handle: (context) ->
      {cmd, state, out} = context
      desc = context.out.pop()

      if cmd.object
        context.out.push capitalize(cmd.object.state.name) + '\n'
        context.out.push if desc == '' then "There is nothing special about the #{cmd.object.state.name}." else desc
      else
        context.out.push capitalize(state.room) + '\n'
        context.out.push if desc == '' then "There is nothing special in this room." else desc

      if !cmd.object
        out.push ''
        for key, object of state.objects[state.room]
          if getRootObject(context, key).obvious
            out.push "#{articlize(key)} is here."
            console.log "LOOKING AT", getRootObject(context, key, state.room).state.objects
            for ki, inner of getRootObject(context, key, state.room).state.objects
              if getObject(context, ki, key).obvious then out.push "#{articlize(ki)} is inside the #{key}."
    prevent: true
  inventory:
    handle: ({state, out}) ->
      o = ''
      for k, obj of state.objects._inventory
        o += articlize(k) + '\n'
      if o == ''
        out.push 'Inventory is empty.'
      else
        out.push 'Inventory:\n\n' + o

capitalize = (str) ->
  str.toLowerCase().split(' ').map((s) -> s.charAt(0).toUpperCase() + s.substring(1)).join(' ')
articlize = (str) ->
  'A' + (if str.match(/^([aeiou])/) then 'n ' else ' ') + str


Alias =
  l: 'look'
  examine: 'look'
  i: 'inventory'
  x: 'look'
  n: 'north'
  s: 'south'
  t: 'take'
  get: 'take'
  pick: 'take'
  drop: 'put'
  throw: 'put'

# Object
getObject = (context, object_name, container_name, room_name) ->
  room_name = room_name || context.state.room
  context.error = ''

  if container_name
    container = getRootObject context, container_name, room_name
    if context.error then return null # Error send by getRootObject
    if object_name && container.state.objects && (object_state = container.state.objects[object_name]) # find the subject state (map file location)
      if (state_room = getRoom context, object_state.room) && (object = (if object_state.container then state_room.objects[object_state.container].objects[object_state.name] else state_room.objects[object_state.name]))
        object.location = {room: container.location.room, name: object_name, container: container.location.name}
        object.state = object_state
        return object
      else context.error = 'Internal Error! Code 0'
    else context.error = "There is no #{object_name} in the #{container_name}."
  else
    return getRootObject context, object_name, room_name
  return null

# Container
getRootObject = (context, object_name, room_name) ->
  room_name = room_name || context.state.room
  context.error = ''

  if object_name
    if context.state.objects[room_name] && (object_state = context.state.objects[room_name][object_name])
      if (state_room = getRoom context, object_state.room) && (object = (if object_state.container then state_room.objects[object_state.container].objects[object_state.name] else state_room.objects[object_state.name]))
        object.location = {room: room_name, name: object_name}
        object.state = object_state
        return object
      else context.error = 'Internal Error! Code 1'
    else if context.state.objects._inventory && (object_state = context.state.objects._inventory[object_name])
      if (state_room = getRoom context, object_state.room) && (object = (if object_state.container then state_room.objects[object_state.container].objects[object_state.name] else state_room.objects[object_state.name]))
        object.location = {room: '_inventory', name: object_name}
        object.state = object_state
        return object
      else context.error = 'Internal Error! Code 2'
    else context.error = "There is no #{object_name} here."
  return null

getRoom = (context, room) ->
  if !room then room = context.state.room
  if room && context.map.rooms[room]
    return context.map.rooms[room]
  else return

getVar = ({state, cmd}, v) ->
  if v[0] == '$'
    if v == '$room' then return state.room
    if v == '$verb' then return cmd.verb
    if v == '$object' then return cmd.object.location.name
    if v == '$container' then return cmd.container.location.name
  else
    return state.vars[v] || ''

# process the arguments given by the handler. Prevents _ names
# context: {map, state}
doTurn = (str, context, allow_, nopad) ->
  context.cmd = undefined
  # Process Arguments
  args = str.match /^\$?([^ ]*)(?:(?:(?:|the|around|from|in|of|on|a|at|out) +)+(.*?)(?: (?:(?:the|around|from|in|of|on|a|at|out) +)+(.*?))?)?$/

  if !args || !args[0]
    context.out.push "PARSE ERROR!"
    return
  else
    args = args.slice 1
  args = args.map (arg) -> if arg then arg.toLowerCase()

  if Alias[args[0]]
    args[0] = Alias[args[0]]
  args[0] = if args[0] instanceof Array then args[0] else [args[0]]

  # Do the actions for each verb
  for arg in args[0]
    if arg[0] == '_' && !allow_ then continue
    context.allow = true

    if (c = MapCommands[arg]) && c.prehandle
      c.prehandle context, {verb: arg, object: args[1], container: args[2]}

    if context.error
      context.out.push context.error
      return

    if !context.allow then continue

    if !context.cmd
      context.cmd = {verb: arg}
      if args[2] && !(context.cmd.container = getRootObject context, args[2])
        context.out.push context.error
        return
      if args[1] && !(context.cmd.object = getObject context, args[1], args[2])
        context.out.push context.error
        return

    stringList = []

    if context.cmd.object
      stringList.push context.cmd.object[context.cmd.verb] || ''

    if context.cmd.container
      stringList.push context.cmd.container[context.cmd.verb] || ''

    if (r = getRoom context)
      stringList.push r.actions[context.cmd.verb] || ''

    if context.map.actions[context.cmd.verb]
      stringList.push context.map.actions[context.cmd.verb]

    if (stringList.join '') == '' && !(c = MapCommands[context.cmd.verb]) && c.handle
      execString context.map.actions._missingverb || '', context

    for str in stringList
      execString str, context
      if !context.allow || ((c = MapCommands[context.cmd.verb]) && c.prevent) then break
    if context.allow && (c = MapCommands[context.cmd.verb]) && c.handle
      c.handle context

    context.out.push ''

# Return false on failure or prevention
execString = (str, context) ->
  {map, cmd, state} = context
  out = ""
  # state: ['text', 'bracket', 'ifT', 'ifF', 'room', 'write', 'done']
  status = ['text']
  isFalse = 0
  while status != 'done'
    #console.log "STATUS: #{status}    OUTPUT: #{out}    ISFALSE: #{isFalse}"
    switch status[status.length - 1]
      when 'text'
        match = str.match /[^\[]*/
        out += match[0]
        str = str.slice match[0].length + 1
        if str.length == 0
          status = 'done'
          break
        status.push 'bracket'
      when 'bracket'
        match = str.match /(?:(?!->)(?:((?:[^?=\]]|==)*)(\?|\])|([^=]*)(=)([^\]]*)\])|(->)([^\]]*)\])/
        if match == null
          context.out.push "PARSE ERROR! Just before #{str}"
          return false
        str = str.slice match[0].length

        if match[6] == '->'
          if isFalse
            status.pop()
            continue
          if state.room == match[7]
            context.out.push "ERROR!: Recursive Room #{match[7]}"
            return false
          if map.rooms[match[7]]
            if out.length > 0
              context.out.push out
            state.next_room = match[7]
            doTurn '_exit', {map, state, out: context.out}, true
            return false
          else
            context.out.push "ERROR!: Nonexistent Room `#{match[7]}` from room `#{state.room}`"
            return false
        else if match[4] == '='
          if !isFalse
            if match[3][0] != '$'
              state.vars[match[3]] = match[5]
            #console.log "Set #{match[3]} to #{match[5]}"
          status.pop()
        else
          switch match[2]
            when '?'
              if match[1].includes '=='
                [a, b] = match[1].split('==')
                if (getVar context, a) == b
                  status.pop()
                  status.push 'ifT'
                else
                  status.pop()
                  status.push 'ifF'
                  if !isFalse then isFalse = status.length
              else
                if ((getVar context, match[1]).toLowerCase() == 'true' || (getVar context, match[1]) == '1')
                  status.pop()
                  status.push 'ifT'
                else
                  status.pop()
                  status.push 'ifF'
                  if !isFalse then isFalse = status.length
            when ']'
              if !isFalse
                if match[1] == 'prevent'
                  context.allow = false
                else if match[1] == 'exit'
                  context.exit = true
                  Handlers.set context.author.tag
                else
                  out += getVar context, match[1]
              status.pop()
      when 'ifT'
        match = str.match /((?:\\.|[^[:\]])*)([[:\]])/
        if !isFalse then out += match[1].replace /\\(.)/, '$1'
        str = str.slice match[0].length
        switch match[2]
          when ':'
            status.pop()
            status.push 'ifF'
            if !isFalse then isFalse = status.length
          when '['
            status.push 'bracket'
          when ']'
            status.pop()
      when 'ifF'
        match = str.match /((?:\\.|[^[:\]])*)([[:\]])/
        str = str.slice match[0].length
        switch match[2]
          when ':'
            if status.length == isFalse then isFalse = 0
            status.pop()
            status.push 'ifT'
          when '['
            status.push 'bracket'
          when ']'
            #console.log status.length
            if status.length == isFalse then isFalse = 0
            status.pop()

  context.out.push out
  if context.exit
    return false
  return true


Handlers.register 'playing', (msg, params) ->
  if msg.content == "#{prompt}q"
    Handlers.set msg.author.tag
    msg.channel.send "Exited #{params[0]}"
    return
  if msg.content[0] == prompt then msg.content = msg.content.slice 1
  map = Storage.maps.read params[0]
  state = Storage.data.maps[params[0]][msg.author.tag]

  out = []
  context = {map, state, out, author: msg.author}
  doTurn msg.content, context
  if out.join('\n').length > 0
    msg.channel.send "```#{out.join '\n'}```"
  else
    msg.channel.send "```No output...?```"
  if context.exit
    msg.channel.send "```Game Over```"


module.exports = MapPlayer =
  begin: (map_name, tag, msg, restart) ->
    if Storage.data.maps[map_name]
      msg.channel.send "Beginning #{map_name}. Type #{prompt}q to stop."
      map = Storage.maps.read map_name
      state = Storage.data.maps[map_name][tag] = if Storage.data.maps[map_name][tag] && !restart then Storage.data.maps[map_name][tag] else {}
      state.vars = state.vars || {}
      state.objects = (() ->
        objs = {}
        for room_name, room of map.rooms
          objs[room_name] = {}
          for object_name, object of room.objects
            objs[room_name][object_name] = {room: room_name, objects: {}, name: object_name}
            if object.objects
              for child_name, child of object.objects
                objs[room_name][object_name].objects[child_name] = {room: room_name, name: child_name, container: object_name}
        objs._inventory = {}
        return objs
      )()

      Handlers.set tag, ["playing", map_name]
      out = []
      if !state.room
        doTurn '_begin', {map, state, out, author: msg.author}, true
      else
        doTurn 'look', {map, state, out, author: msg.author}

      if out.join('\n').length > 0
        msg.channel.send "```#{out.join '\n'}```"
      else
        msg.channel.send "```No output...?```"

    else
      msg.channel.send "Cannot find a map named #{name}. Please check name using `map list`."
