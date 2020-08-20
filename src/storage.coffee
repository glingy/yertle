fs = require 'fs'
STORAGE_FOLDER = 'storage'
FILE_NAME = "#{STORAGE_FOLDER}/data.json"
MAPS_FOLDER = "#{STORAGE_FOLDER}/maps"


if !fs.existsSync FILE_NAME
  if !fs.existsSync STORAGE_FOLDER
    fs.mkdirSync STORAGE_FOLDER
  fs.writeFileSync FILE_NAME, ""

if !fs.existsSync MAPS_FOLDER
    fs.mkdirSync MAPS_FOLDER

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
        return JSON.parse fs.readFileSync "#{MAPS_FOLDER}/#{name}.json"
      catch e
        return e
    write: (name, tag, map) ->
      if !Store.data.maps["#{name}"]
        Store.data.maps["#{name}"] = {owner: tag}
      Store.save()
      try
        fs.renameSync "#{MAPS_FOLDER}/#{name}.json", "#{MAPS_FOLDER}/#{name}_bak.json"
      catch
        console.log "New map!"
      fs.writeFileSync "#{MAPS_FOLDER}/#{name}.json", (JSON.stringify map, null, 2)
  save: () ->
    try fs.renameSync "#{STORAGE_FOLDER}/data.json", "#{STORAGE_FOLDER}/data_bak.json"
    fs.writeFileSync FILE_NAME, (JSON.stringify Store.data, null, 2)
