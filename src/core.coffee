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
    setModuleAndAncestorsToEager(newModule.name) if shouldModuleBeEager(newModule)

  makeNewModuleNode = (name, dependencies, callback) ->
    externalName: name
    name: name || getGUID()
    unresolvedDeps: createSet().addAll(dependencies)
    definedAsEager: !name?
    resolver: once(asyncify(callback))
    status: 'waiting'

  isEager = (module) ->
    module.status != 'waiting'

  raiseErrorForUndefinedDependencies = (module) ->
    undefinedDeps = undefinedDependencies(module)
    if undefinedDeps.length > 0
      onErr(new Error("The following dependencies was never defined: " + undefinedDeps.join(', ')))

  undefinedDependencies = (module) ->
    module.unresolvedDeps.toList().filter (name) -> !moduleGraph.hasNode(name)

  shouldModuleBeEager = (module) ->
    thisShouldBeEager = module.definedAsEager
    anyChildIsEager = moduleGraph.anyChild(module.name, ((childName, childData) -> isEager(childData)))
    thisShouldBeEager || anyChildIsEager

  setModuleAndAncestorsToEager = (moduleName) ->
    node = moduleGraph.getNodeData(moduleName)
    return if !node? || isEager(node)
    setModuleToEager(node)
    moduleGraph.getParents(moduleName).forEach(setModuleAndAncestorsToEager)

  setModuleToEager = (module) ->
    module.status = 'ready'
    attemptResolve(module)
    setImm(-> raiseErrorForUndefinedDependencies(module)) if !lazy

  areAllDepsResolved = (module) ->
    module.unresolvedDeps.isEmpty()

  attemptResolve = (module) ->
    if isEager(module) && areAllDepsResolved(module)
      resolveModule(module)

  getResolvedDependencies = (module) ->
    parents = moduleGraph.getParents(module.name)
    toObject(parents.map (name) -> [name, moduleGraph.getNodeData(name).value])

  resolveModule = (module) ->
    module.status = 'resolving'
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
    module.status = 'resolved'
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

  introspect: ->
    toObject moduleGraph.listNodeNames().map (name) ->
      hasNode = moduleGraph.hasNode(name)
      status = if !hasNode then 'referred' else moduleGraph.getNodeData(name).status
      dependencies = moduleGraph.getParents(name)
      dependants = moduleGraph.getChildren(name)
      [name, { status, dependants, dependencies }]
