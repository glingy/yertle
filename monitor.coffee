Client = require './src/client'

for [1..100]
  try
    Client()
  catch e
    console.log e