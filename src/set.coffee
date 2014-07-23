SetBase = {
  isEmpty: ->
    @toList().length == 0

  addAll: (names) ->
    names.forEach (name) =>
      @add(name)
    @
}



exports.createSet = ->

  set = Object.create(SetBase)
  data = {}

  set.add = (name) ->
    data[name] = true
    @

  set.remove = (name) ->
    delete data[name]
    @

  set.toList = ->
    Object.keys(data)

  set
