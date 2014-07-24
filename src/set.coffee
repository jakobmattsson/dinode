{inherit} = require './util'

SetBase = {
  isEmpty: ->
    @toList().length == 0

  addAll: (names) ->
    names.forEach (name) =>
      @add(name)
    @
}

exports.createSet = ->

  data = {}

  inherit(SetBase, {
    add: (name) ->
      data[name] = true
      @

    remove: (name) ->
      delete data[name]
      @

    toList: ->
      Object.keys(data)
  })
