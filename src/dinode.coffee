core = require './core'
autoDeps = require './autoDeps'
augment = require './augment'

exports.construct = (params = {}) ->
  augmentors = [autoDeps, augment]
  diCore = core.construct(params)
  augmentors.reduce (di, augmentor) ->
    augmentor.construct(di, params)
  , diCore
