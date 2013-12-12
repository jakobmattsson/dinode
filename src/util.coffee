exports.clone = (x) ->
  n = {}
  Object.keys(x).forEach (key) ->
    n[key] = x[key]
  n
