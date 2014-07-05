{unique, removeAll, flatten, once, setImm} = require './util'

exports.construct = ({ lazy, onError }) ->

  lazy ?= false
  onError ?= (err) -> throw err

  diModules = {}
  waiting = []
  allRegistered = {}

  loadModules = (modules, callback) ->
    missing = {}
    resolved = {}
  
    modules.forEach (m) ->
      if diModules[m]?
        resolved[m] = diModules[m].value
      else
        missing[m] = true

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

  checkAllRegistered = once ->
    return if lazy

    allModules = Object.keys(allRegistered)
    allDeps = flatten allModules.map (m) -> allRegistered[m].dependencies
    missing = removeAll(unique(allDeps), allModules)

    if missing.length > 0
      onError(new Error("The following dependencies was never defined: " + missing.join(', ')))



  listModules: -> allRegistered

  registerModule: (id, modules, callback) ->

    # if the module is anonymous, there's no need to register it
    if id?
      allRegistered[id] = { dependencies: modules, resolved: false }

    setImm ->
      checkAllRegistered()

      loadModules modules, (loadedModules) ->

        actualCallback = null

        if callback.length < 2
          actualCallback = (required, cb) ->
            cb(null, callback(required))
        else
          actualCallback = callback

        actualCallback loadedModules, (err, value) ->
          return if !id?
          return onError(new Error("Module '#{id}' defined twice")) if diModules[id]
          return onError(new Error("Module '#{id}' failed during registration: " + (err?.message || 'unknown error'))) if err?
          allRegistered[id].resolved = true
          diModules[id] = { value: value }
          setImm -> onRegister(id, value)
