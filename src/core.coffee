{unique, removeAll, flatten, once, setImm} = require './util'

exports.construct = ({ lazy, onError }) ->

  lazy ?= false
  onError ?= (err) -> throw err

  diModules = {}
  waiting = []
  allRegistered = {}



  beginResolving = (name) ->
    resolver = allRegistered[name]?.resolveMe
    if resolver
      allRegistered[name].resolveMe = null
      resolver()



  loadModules = (modules, callback) ->
    missing = {}
    resolved = {}
  
    modules.forEach (m) ->
      if diModules[m]?
        resolved[m] = diModules[m].value
      else
        missing[m] = true
        beginResolving(m)

    if Object.keys(missing).length == 0
      setImm -> callback(resolved)
    else
      waiting.push({
        missingModules: missing
        modules: resolved
        callback: callback
      })



  onRegister = (id, value) ->
    waiting.forEach (w) ->
      if w.missingModules[id]
        w.modules[id] = value
        delete w.missingModules[id]
  
    resolved = waiting.filter (x) -> Object.keys(x.missingModules).length == 0

    waiting = waiting.filter (x) -> Object.keys(x.missingModules).length > 0

    resolved.forEach (m) ->
      m.callback.call(null, m.modules)



  checkIfAllDepsDefined = (modules) ->
    missing = {}
    needed = {}
    traversing = []

    addToTraversing = (list) ->
      list.forEach (e) ->
        traversing.push(e) if !needed[e]

    addToTraversing(modules)

    while traversing.length > 0
      name = traversing.pop()
      needed[name] = true
      e = allRegistered[name]

      if e
        addToTraversing(e.dependencies)
      else
        missing[name] = true

    missingList = Object.keys(missing)

    if missingList.length > 0
      onError(new Error("The following dependencies was never defined: " + missingList.join(', ')))



  asyncifyCallback = (callback) ->
    if callback.length < 2
      (required, cb) -> cb(null, callback(required))
    else
      callback



  listModules: -> allRegistered

  registerModule: (id, modules, callback) ->

    resolveMe = ->
      loadModules modules, (loadedModules) ->
        actualCallback = asyncifyCallback(callback)
        actualCallback loadedModules, (err, value) ->
          return if !id?
          return onError(new Error("Module '#{id}' defined twice")) if diModules[id]
          return onError(new Error("Module '#{id}' failed during registration: " + (err?.message || 'unknown error'))) if err?
          allRegistered[id].resolved = true
          diModules[id] = { value: value }
          setImm -> onRegister(id, value)

    # only register modules if they're named
    if id?
      allRegistered[id] = {
        dependencies: modules
        resolved: false
        resolveMe: resolveMe
      }

    # trigger resolution if this is an anonymous module
    if !id?
      setImm ->
        checkIfAllDepsDefined(modules) if !lazy
        resolveMe()
