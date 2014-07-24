util = require './util'

parseDestructedArg = (line, argName) ->
  if line.trim() == ''
    throw new Error("Unexpected format: cant work with empty line")
  
  assignments = line.split(',').map (x) -> x.trim()

  assignments.map (x) ->
    mm = x.match(/^([^; ]+) = _arg\.([^; ]+);?$/)
    if !mm || mm[1] != mm[2]
      throw new Error("Unexpect format: cannot figure out dependencies automatically")
    mm[1]

findDestructedArg = (lines, argName) ->
  for l in lines
    try
      x = parseDestructedArg(l, argName)
      return x
    catch ex
      # go on...
  throw new Error("nothing worked")

figureOutDependencies = (func) ->
  lines = func.toString().split('\n')
  
  signatureRegex = /^[ ]*function[ ]*\(([^,]*,)?([^,]*)?\)[ ]*{[ ]*$/
  signature = lines[0].match(signatureRegex)
  if !signature?
    throw new Error("Invalid number of parameters (more than 2); cannot figure out dependencies automatically")

  argNames = signature.slice(1).filter (x) -> x

  if argNames.length == 0
    []
  else if argNames.length == 1
    # this case is a guess. The passed in argument could be a callback
    # but that's quite ok, sicne this function will fail if yo have to supply deps explicitly
    findDestructedArg(lines.slice(1), argNames[0])
  else if argNames.length == 2
    findDestructedArg(lines.slice(1), argNames[0])



exports.construct = (di, params) ->
  di2 = util.clone(di)
  
  di2.registerModule = (id, modules, callback) ->
    if !callback?
      callback = modules
      modules = null

    if !modules?
      modules = figureOutDependencies(callback)

    di.registerModule(id, modules, callback)

  di2
