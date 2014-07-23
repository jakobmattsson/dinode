exports.clone = (x) ->
  n = {}
  Object.keys(x).forEach (key) ->
    n[key] = x[key]
  n

exports.once = (f) ->
  ran = false
  (args...) ->
    return if ran
    ran = true
    f(args...)

exports.flatten = (arr) ->
  arrOfArrs = arr.map (e) ->
    if Array.isArray(e)
      exports.flatten(e)
    else
      e

  Array::concat.apply([], arrOfArrs)

exports.removeAll = (source, remove) ->
  source.filter (x) -> x not in remove

exports.unique = (arr) ->
  return [] if arr.length == 0

  head = arr[0]
  rest = arr.slice(1)
  uniqueRest = exports.unique(rest)

  [head].concat(uniqueRest.filter((x) -> x != head))

exports.setImm = (f) -> setTimeout(f, 1)

exports.toObject = (pairs) ->
  obj = {}
  pairs.forEach ([key, value]) ->
    obj[key] = value
  obj

exports.asyncify = (callback) ->
  if callback.length < 2
    (required, cb) ->
      res = null

      try
        res = callback(required)
      catch ex
        cb(ex)
        return

      cb(null, res)
  else
    callback
