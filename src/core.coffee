{unique, removeAll, flatten, once, setImm, toObject, asyncify} = require './util'

exports.construct = ({ lazy, onError }) ->

  allRegistered = {}
  invertedIndex = {}


  isAllDepsResolved = (module) ->
    module? && Object.keys(module.unresolvedDeps).length == 0

  getResolvedDependencies = (module) ->
    toObject(module.directDeps.map (name) -> [name, allRegistered[name].value])

  newModuleRegistered = (name, dependencies, callback) ->

    if name? && allRegistered[name]?
      onError(new Error("Module '#{name}' defined twice"))
      return

    # Create the new module
    newModule = {
      name: name
      unresolvedDeps: {}
      directDeps: dependencies
      resolveEagerly: !name?
      resolver: callback
      resolved: false
    }

    if !lazy
      setTimeout ->
        missing = Object.keys(newModule.unresolvedDeps).filter (name) -> !allRegistered[name]?
        if missing.length > 0
          return onError(new Error("The following dependencies was never defined: #{missing.join(', ')}"))
      , 1


    # Add the new module to the directionary of modules
    allRegistered[name] = newModule

    # Add each direct dependency as an unresolved dependency in the module
    dependencies.forEach (dependency) ->
      newModule.unresolvedDeps[dependency] = allRegistered[dependency]

    # For each dependency, note the relation in the inverted index
    dependencies.forEach (dependency) ->
      invertedIndex[dependency] ?= []
      invertedIndex[dependency].push(newModule)

    # For every module already depending on this new module,
    # insert the reference to the new module
    invertedIndex[name] ?= []
    invertedIndex[name].forEach (mod) ->
      mod.unresolvedDeps[newModule.name] = newModule

    # For every module already depending on this new module,
    # copy its dependencies to the unresolved of the dependant
    invertedIndex[name].forEach (dependantOnTheNew) ->
      newModule.directDeps.forEach (depName) ->
        if !allRegistered[depName].resolved
          dependantOnTheNew.unresolvedDeps[depName] = allRegistered[depName]

    # Om den aktuella modulen ska resolva eagerly, då ska också alla dess icke-resolvade dependencies också göra det.
    anyChildIsEager = invertedIndex[name].some (dependantOnTheNew) -> dependantOnTheNew.resolveEagerly
    if newModule.resolveEagerly || anyChildIsEager
      newModule.resolveEagerly = true
      for key, value of newModule.unresolvedDeps
        if value?
          value.resolveEagerly = true
          if isAllDepsResolved(value)
            onAllDepsResolved(value)

    # If the module is already resolved (it has no deps) --- OR ALL DEPS ARE ALREADY RESOLVED? (how do we catch this?)
    if isAllDepsResolved(newModule)
      onAllDepsResolved(newModule)



  resolveModule = (mod) ->
    # Prevent the module from resolving multiple times
    return if !mod.resolver?
    resolver = mod.resolver
    mod.resolver = null

    # Now resolve it
    resolver getResolvedDependencies(mod), (err, value) ->
      if err
        if mod.name?
          onError(new Error("Module '#{mod.name}' failed during registration: " + (err?.message || 'unknown error'))) if err?
        else
          onError(new Error("Anonymous module failed during registration: " + (err?.message || 'unknown error'))) if err?
        return

      if mod.name?
        moduleResolved(mod, value)


  onAllDepsResolved = (mod) ->
    resolveModule(mod) if mod.resolveEagerly



  moduleResolved = (resolvedModule, value) ->
    resolvedModule.resolved = true
    resolvedModule.value = value
    invertedIndex[resolvedModule.name].forEach (module) ->
      delete module.unresolvedDeps[resolvedModule.name]
      if isAllDepsResolved(module)
        onAllDepsResolved(module)







  registerModule: (id, modules, callback) ->
    newModuleRegistered(id, modules || [], asyncify(callback))
