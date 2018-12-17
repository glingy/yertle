Handlers = require './handlers'
{prompt, parseArgs} = require './util'
Storage = require './storage'

MapCommands =
  _exit:
    handle: (context) ->
      state.room = state.next_room
      doTurn '_enter', context, true
      return true
  _enter:
    handle: (context) ->
      doTurn 'l', context
  north:
    handle: ({args, state}) ->
      state.out.push "You cannot go #{args[0]}."
      return false
  south:
    handle: (args) -> MapCommands.north args
  west:
    handle: (args) -> MapCommands.north args
  east:
    handle: (args) -> MapCommands.north args
  take:
    handle: (args) ->
  name:
    prevent: true
  look:
    handle: ({args, map, params, state}) ->
      state.out.push ''
      for k, object of state.objects[state.room]
        console.log "LOOKING AT OBJECT #{k}"
        obj = map.rooms[object.room].objects[object.name]
        doTurn "name #{k}", map, params, state, false, true
        name = state.out.pop().toLowerCase()
        if name == ''
          state.out.push "(ERROR! UNNAMED OBJECT!)"
          console.log "Unnamed", state.out
          continue
        if state.objects[state.room][name] && name != k
          state.out.push "(ERROR! DUPLICATE NAME!)"
          continue
        state.objects[state.room][name] = state.objects[state.room][k]
        if name != k
          console.log "DELETE", name, k
          delete state.objects[state.room][k]

        console.log " NAME: #{name}"
        if obj.obvious then state.out.push "A(n) #{name} is here."
    prevent: true

Alias =
  look: ['name', 'look']
  l: ['name', 'look']
  examine: ['name', 'look']
  x: ['name', 'look']
  n: 'north'
  s: 'south'
# process the arguments given by the handler. Prevents _ names
doTurn = (str, map, params, state, allow_, nopad) ->
  # args = [verb, subject, direct object] (with filler words)
  args = str.match /^\$?([^ ]*)(?:(?:(?:|the|around|from|in|of|on|a|at|out) +)+(.*?)(?: (?:(?:the|around|from|in|of|on|a|at|out) +)+(.*?))?)?$/
  if !args
    state.out.push "PARSE ERROR!"
    return
  else
    args = args.slice 1
  console.log args
  args = args.map (arg) -> if arg then arg.toLowerCase()

  if Alias[args[0]]
    args[0] = Alias[args[0]]

  args[0] = if args[0] instanceof Array then args[0] else [args[0]]
  ret = true
  state.last = ''
  for arg in args[0]
    state.vars.verb = arg
    state.vars.subject = args[1]
    state.vars.object = args[2]


    if state.vars.subject
      # process objects
      #console.log  state.objects
      subject = if state.objects._inventory[state.vars.subject]
        state.objects._inventory[state.vars.subject]
      else
        state.objects[state.room][state.vars.subject]

      if subject
        execStrings [map.rooms[subject.room].objects[subject.name][state.vars.verb], map.rooms[state.room].actions[state.vars.verb], map.actions[state.vars.verb]], args, map, params, state
    else
      if state.vars.verb
        if state.vars.verb[0] == '_' && !allow_ then return

        #console.log "Exec"
        #console.log state.vars.verb
        #console.log args
        #console.log map.rooms[state.rooms]
        if (map.rooms[state.room] && map.rooms[state.room].actions[state.vars.verb]) || map.actions[state.vars.verb] || MapCommands[state.vars.verb]
          if execStrings [(map.rooms[state.room] && map.rooms[state.room].actions[state.vars.verb]) || '', map.actions[state.vars.verb]], args, map, params, state
            if MapCommands[state.vars.verb] && MapCommands[state.vars.verb].handle
              ret = MapCommands[state.vars.verb].handle {args, map, params, state}
        else
          execStrings [map.actions._default], args, map, params, state
    if !nopad then state.out.push ''
  return ret

# Return false on failure or prevention
execStrings = (strs, args, map, params, state) ->
  #console.log  "Exec Strings: #{strs.join ', '}"
  parse = (str) ->
    allow = true
    out = ""
    # state: ['text', 'bracket', 'ifT', 'ifF', 'room', 'write', 'done']
    status = ['text']
    isFalse = 0
    while status != 'done'
      ##console.log "STATUS: #{status}    OUTPUT: #{out}    ISFALSE: #{isFalse}"
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
          match = str.match /(?:(?!->)(?:([^?=\]]*)(\?|\])|([^=]*)(=)([^\]]*)\])|(->)([^\]]*)\])/
          if match == null
            state.out.push "PARSE ERROR! Just before #{str}"
            return false
          str = str.slice match[0].length

          if match[6] == '->'
            if isFalse
              status.pop()
              continue
            if state.room == match[7]
              state.out.push "ERROR!: Recursive Room #{match[7]}"
              return false
            if map.rooms[match[7]]
              if out.length > 0
                state.out.push out
              state.next_room = match[7]
              doTurn '_exit', context, true
              return false
            else
              state.out.push "ERROR!: Nonexistent Room `#{match[7]}` from room `#{state.room}`"
              return false
          else if match[4] == '='
            if !isFalse
              state.vars[match[3]] = match[5]
              #console.log "Set #{match[3]} to #{match[5]}"
            status.pop()
          else
            switch match[2]
              when '?'
                if state.vars[match[1]] && (state.vars[match[1]].toLowerCase() == 'true' || state.vars[match[1]] == '1')
                  status.pop()
                  status.push 'ifT'
                else
                  status.pop()
                  status.push 'ifF'
                  if !isFalse then isFalse = status.length
              when ']'
                if match[1] == 'prevent'
                  allow = false
                  status.pop()
                else
                  out += state.vars[match[1]]
                  status.pop()
        when 'ifT'
          match = str.match /([^[:\]]*)(.)/
          if !isFalse then out += match[1]
          str = str.slice match[0].length
          switch match[2]
            when ':'
              status.pop()
              status.push 'ifF'
            when '['
              status.push 'bracket'
            when ']'
              status.pop()
        when 'ifF'
          match = str.match /([^[:\]]*)(.)/
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

    state.out.push out
    return allow

  if strs
    for i, stri of strs
      #console.log i, stri
      #console.log "COMMAND"
      #console.log MapCommands[state.vars.verb] && MapCommands[state.vars.verb].prevent
      if (!parse stri || '') then return false
      if (MapCommands[state.vars.verb] && MapCommands[state.vars.verb].prevent) then return true

  return true

Handlers.register 'playing', (msg, params) ->
  if msg.content == "#{prompt}q"
    Handlers.set msg.author.tag
    msg.channel.send "Exited #{params[0]}"
    return
  if msg.content[0] == prompt then msg.content = msg.content.slice 1
  map = Storage.maps.read params[0]
  state = Storage.data.maps[params[0]][msg.author.tag]
  #msg.channel.send "Playing #{params[0]}"
  state.out = []
  doTurn msg.content, map, params, state
  msg.channel.send "```#{state.out.join '\n'}```"


module.exports = MapPlayer =
  begin: (name, tag, msg, restart) ->
    if Storage.data.maps[name]
      msg.channel.send "Beginning #{name}. Type #{prompt}q to stop."
      map = Storage.maps.read name
      state = Storage.data.maps[name][tag] = if Storage.data.maps[name][tag] && !restart then Storage.data.maps[name][tag] else {}
      state.vars = state.vars || {}
      state.objects = (() ->
        objs = {}
        #console.log map.rooms
        for kr, room of map.rooms
          #console.log kr, room
          objs[kr] = {}
          for ko, object of room.objects
            #console.log ko, object
            objs[kr][if object.ref then object.ref else ko] = {room: kr, name: ko}
        objs._inventory = {}
        return objs
      )()
      #console.log state.objects

      Handlers.set tag, ["playing", name]
      state.out = []
      if !state.room
        execStrings ["[->#{map.first_room}]"], ['_begin'], map, [name], state
      else
        doTurn 'look', map, [name], state
      msg.channel.send "```#{state.out.join '\n'}```"

    else
      msg.channel.send "Cannot find a map named #{name}. Please check using `map list`"
  save: () ->
