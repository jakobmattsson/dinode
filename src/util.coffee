exports.inherit = (type, obj) ->
  newobj = Object.create(type)
  for key, value of obj
    newobj[key] = value
  newobj

exports.clone = (x) ->
  n = {}
  Object.keys(x).forEach (key) ->
    n[key] = x[key]
  n

exports.once = (f) ->
  ran = false
  ->
    return if ran
    ran = true
    f.apply(this, arguments)

exports.setImm = (f) ->
  setTimeout(f, 1)

exports.toObject = (pairs) ->
  obj = {}
  pairs.forEach ([key, value]) ->
    obj[key] = value
  obj

exports.contains = (list, element) ->
  list.indexOf(element) != -1

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

exports.getGUID = do ->
  v = 0
  ->
    v++
    "____leaf#{v}"

exports.pairs = (obj) ->
  Object.keys(obj).map (key) ->
    [key, obj[key]]

exports.occuranceCounter = (list) ->
  list.reduce (acc, item) ->
    acc[item] ?= 0
    acc[item]++
    acc
  , {}
