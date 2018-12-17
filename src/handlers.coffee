store = require './storage'

store.data.handlers = store.data.handlers || {}

handlers = {}

module.exports =
  set: (user, handler) ->
    if handler == undefined
      delete store.data.handlers[user]
    else
      if !(handler instanceof Array) then handler = [handler]
      store.data.handlers[user] = handler
    store.save()
  run: (msg) ->
    user = msg.author.tag
    if store.data.handlers[user] && handlers[store.data.handlers[user][0]]
      handlers[store.data.handlers[user][0]] msg, store.data.handlers[user].slice 1
      return true
    else
      return false
  register: (name, handler) ->
    handlers[name] = handler
