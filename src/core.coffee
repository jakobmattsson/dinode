# hur förhindrar man dödlägen?
# vissa moduler kanske inte är färdigladdade, trots att det inte finns några kvar att registrera
# skulle kunna skicka in en flagga som styr huruvida man tillåter att det händer eller ej

# verkar inte faila rätt när man definierar två moduler med samma namn

setImm = (f) -> setTimeout(f, 1)









exports.construct = ({ lazy, onError }) ->

  onError ?= (err) ->
    console.log "do something defaulty"
    console.log err.message


  diModules = {}
  waiting = []
  unresolvedModules = {}

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

    # console.log "missing", Array::concat.apply([], waiting.map((x) -> Object.keys(x.missingModules)))

    resolved.forEach (m) ->
      m.callback.call(null, m.modules)



  registerModule: (id, modules, callback) ->
    # om den redan finns registrerad så ska ett fel genereras
    unresolvedModules[id] = true
    setImm ->
      loadModules modules, (loadedModules) ->
        # console.log "all loaded for #{id}: [#{modules.join(', ')}]"

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
          diModules[id] = { value: value }
          delete unresolvedModules[id]
          setImm -> onRegister(id, value)
