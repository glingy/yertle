Commands = require '../commands'
JSZip = require 'jszip'
fs = require 'fs'

Commands.__add 'src',
  handle: (args, msg) ->

    zip = JSZip()
    addFolder('src', zip).then ->
      zip.generateAsync
          type: "nodebuffer"
          compression: "DEFLATE"
    .then (buffer) ->
      msg.channel.send 'Here is my current source code: ',
        files : [
              attachment: buffer
              name: "src.zip"
          ]
    .catch (error) ->
      msg.channel.send "Whoops. That didn't work."
      
  info: 'Shares a zip file of the source code'


addFolder = (folder, zip) ->
  new Promise (res, rej) -> 
    fs.readdir folder, { withFileTypes: true }, (err, files) ->
      if err
        rej(err)
        return
      for file in files
        if file.isFile()
          await new Promise (res, rej) ->
            fs.readFile "#{folder}/#{file.name}", (err, data) ->
              if err
                rej(err)
                return
              zip.file "#{folder}/#{file.name}", data
              res()
        else if file.isDirectory()
          await addFolder "#{folder}/#{file.name}", zip
      res()