util = require './util'

exports.construct = (di, { onError, require }) ->

  di2 = util.clone(di)

  di2.registerVar = (id, value) ->
    di.registerModule id, [], ({}, callback) ->
      callback(null, value)

  di2.registerVars = (objs) ->
    Object.keys(objs).forEach (name) ->
      di2.registerVar(name, objs[name])

  di2.registerRequire = (id, value) ->
    value = id if !value?
    di.registerModule id, [], ({}, callback) ->
      callback(null, require(value))

  di2.registerAlias = (id, aliased) ->
    di.registerModule id, [aliased], (obj, callback) ->
      callback(null, obj[aliased])

  di2.registerFile = (id, filename) ->
    file = require(filename)

    if !file.execute?
      onError(new Error("Failed to register '#{id}'. The file '#{filename}' does not have an 'execute' property."))
      return
      
    di.registerModule(id, file.dependsOn, file.execute)

  di2.run = (modules, callback) ->
    di.registerModule(null, modules, callback)

  di2.registerProperty = (property, input) ->
    di.registerModule property, [input], (deps) ->
      deps[input][property]

  di2.registerProperties = (properties, input) ->
    properties.forEach (property) ->
      di2.registerProperty(property, input)

  di2
