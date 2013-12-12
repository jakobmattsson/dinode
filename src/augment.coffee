util = require './util'

exports.construct = ({ di }) ->

  di2 = util.clone(di)

  di2.registerVar = (id, value) ->
    di.registerModule id, [], ({}, callback) ->
      callback(null, value)

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
      throw new Error("Failed to register '#{id}'. The file '#{filename}' does not have an 'execute' property.")
      
    if !file.dependsOn?
      throw new Error("Failed to register '#{id}'. The file '#{filename}' does not have a 'dependsOn' property.")

    di.registerModule(id, file.dependsOn, file.execute)

  di2.run = (modules, callback) ->
    di.registerModule(null, modules, callback)

  di2
