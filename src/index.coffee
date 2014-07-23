core = require './core'
autoDeps = require './autoDeps'
augment = require './augment'

exports.construct = (params = {}) ->

  augParams = {
    require: params.require ? require
    lazy: params.lazy ? false
    onError: params.onError ? (err) -> throw err
  }

  augmentors = [autoDeps, augment]
  diCore = core.construct(augParams)
  augmentors.reduce (di, augmentor) ->
    augmentor.construct(di, augParams)
  , diCore
