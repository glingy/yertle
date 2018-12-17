fs = require 'fs'
FILE_NAME = 'storage/data.json'
content = fs.readFileSync(FILE_NAME)
store =
  maps: {}


try
  store = JSON.parse content
catch

module.exports = Store =
  data: store,
  maps:
    read: (name) ->
      try
        return JSON.parse fs.readFileSync "storage/maps/#{name}.json"
      catch e
        return e
    write: (name, tag, map) ->
      if !Store.data.maps["#{name}"]
        Store.data.maps["#{name}"] = {owner: tag}
      Store.save()
      try
        fs.renameSync "storage/maps/#{name}.json", "storage/maps/#{name}_bak.json"
      catch
        console.log "New map!"
      fs.writeFileSync "storage/maps/#{name}.json", (JSON.stringify map, null, 2)
  save: () ->
    try fs.renameSync "storage/data.json", "storage/data_bak.json"
    fs.writeFileSync FILE_NAME, (JSON.stringify Store.data, null, 2)
