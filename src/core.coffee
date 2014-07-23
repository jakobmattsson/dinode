{once, setImm, toObject, asyncify, getGUID} = require './util'
{createGraph} = require './graph'
{createSet} = require './set'

exports.construct = ({ lazy, onError }) ->

  #
  # PRIVATE STATE
  #

  onErr = once(onError)
  moduleGraph = createGraph()



  #
  # PRIVATE HELPERS
  #

  newModuleRegistered = (name, dependencies, callback) ->
    newModule = makeNewModuleNode(name, dependencies, callback)
    moduleGraph.addNode(newModule.name, newModule, dependencies)
    setImm(-> raiseErrorForUndefinedDependencies(newModule)) if !lazy
    setModuleAndAncestorsToEager(newModule.name) if shouldModuleBeEager(newModule)

  makeNewModuleNode = (name, dependencies, callback) ->
    externalName: name
    name: name || getGUID()
    unresolvedDeps: createSet().addAll(dependencies)
    definedAsEager: !name?
    eager: false
    resolver: once(asyncify(callback))
    resolved: false # TODO:::: three states, not two

  raiseErrorForUndefinedDependencies = (module) ->
    undefinedDeps = undefinedDependencies(module)
    if undefinedDeps.length > 0
      onErr(new Error("The following dependencies was never defined: " + undefinedDeps.join(', ')))

  undefinedDependencies = (module) ->
    module.unresolvedDeps.toList().filter (name) -> !moduleGraph.hasNode(name)

  shouldModuleBeEager = (module) ->
    thisShouldBeEager = module.definedAsEager
    anyChildIsEager = moduleGraph.anyChild(module.name, ((childName, childData) -> childData.eager))
    thisShouldBeEager || anyChildIsEager

  setModuleAndAncestorsToEager = (moduleName) ->
    node = moduleGraph.getNodeData(moduleName)
    return if !node? || node.eager
    setModuleToEager(node)
    moduleGraph.getParents(moduleName).forEach(setModuleAndAncestorsToEager)

  setModuleToEager = (module) ->
    module.eager = true
    attemptResolve(module)

  areAllDepsResolved = (module) ->
    module.unresolvedDeps.isEmpty()

  attemptResolve = (module) ->
    if module.eager && areAllDepsResolved(module)
      resolveModule(module)

  getResolvedDependencies = (module) ->
    parents = moduleGraph.getParents(module.name)
    toObject(parents.map (name) -> [name, moduleGraph.getNodeData(name).value])

  resolveModule = (module) ->
    module.resolver getResolvedDependencies(module), (err, value) ->
      if err?
        onModuleResolvedErroneously(module, err)
      else
        onModuleResolvedSuccessfully(module, value)

  markDependencyAsResolved = (module, dependencyName) ->
    module.unresolvedDeps.remove(dependencyName)
    attemptResolve(module)

  onModuleResolvedErroneously = (module, err) ->
    message = err.message || err.toString()
    if module.externalName?
      onErr(new Error("Module '#{module.externalName}' failed during registration: " + message))
    else
      onErr(new Error("Anonymous module failed during registration: " + message))

  onModuleResolvedSuccessfully = (module, value) ->
    module.resolved = true
    module.value = value
    moduleGraph.getChildren(module.name).forEach (childName) ->
      childModule = moduleGraph.getNodeData(childName)
      markDependencyAsResolved(childModule, module.name)



  #
  # PUBLIC INTERFACE
  #

  registerModule: (id, modules, callback) ->
    try
      newModuleRegistered(id, modules, callback)
    catch ex
      onErr(ex)

  listModules: ->
    throw new Error("not implemented")
    # TODO
    # - created (notResolved/resolutionStarted/resolved)
    # - only named
    # - also show all parents and children of each module
    # - askedToResolve (or something like it.. the external version of "eager")
