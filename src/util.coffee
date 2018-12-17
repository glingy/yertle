commandRegex = /([^ ]+)/g
http = require 'https'


module.exports = Util =
  parseArgs: (str) ->
    args = []
    while arg = commandRegex.exec str
      args.push arg[0]
    return args
  prompt: '$'
  getUser: (str, msg) ->
    Util.choose str, msg.channel.members.map (member) ->
      #console.log member.displayName.replace(/[^\w\s]/gi, '*')
      [member.displayName.replace(/[^\w\s/()]/gi, '*'), member.user]
  levDist: (s1, s2) ->
    s1 = s1.toLowerCase()
    s2 = s2.toLowerCase()
    #console.log "Distance from #{s1} to #{s2}"

    if (s1 == s2) then return 0
    s1l = s1.length+1
    s2l = s2.length+1
    if s1l == 0 then return s2l
    if s2l == 0 then return s1l
    matrix = [] # [s1l] by [s2l]
    for i in [0...s1l]
      matrix.push [i]
    for i in [1...s2l]
      matrix[0].push i
    for i in [1...s1l]
      for j in [1...s2l]
        #console.log "#{s1[i-1]} == #{s2[j-1]}?"
        if s1[i-1] == s2[j-1]
          matrix[i][j] = matrix[i-1][j-1]
          #console.log "#{s1[i-1]} = #{s2[j-1]}"
        else
          matrix[i][j] = Math.min(Math.min(matrix[i-1][j], matrix[i-1][j-1]), matrix[i][j-1]) + 1
    #console.log matrix, s1l, s2l
    return matrix[s1l-1][s2l-1]
  choose: (str, array) ->
    #console.log array.map (item) -> item[0]
    rank = array.map (item) ->
      return [(Util.levDist str, item[0]), item[0], item[1]]

    rank.sort (item1, item2) ->
      #console.log "#{item1[0]}: #{item1[1]} is #{if item1[0] < item2[0] then 'better' else 'worse'} than #{item2[0]}: #{item2[1]}"
      return item1[0] - item2[0]
    console.log rank.map (item) -> [item[0], item[1]]
    #console.log rank.reverse().map (item) -> [item[0], item[1]]
    #rank.reverse()
    winners = rank.filter (item) ->
      item[0] == rank[0][0]
    #console.log winners
    if winners.length > 1 then return winners.map (winner) -> winner.slice 1
    #console.log winners
    return rank[0].slice 1




  download: (url, callback) ->
    http.get url, (res) ->
      if res.statusCode != 200
        res.resume()
        return {}
      res.setEncoding 'utf8'
      raw = ''
      res.on 'data', (chunk) ->
        raw += chunk
      res.on 'end', ->
        raw = raw.replace /[\u2028]/gu, ''
        console.log raw

        callback raw
