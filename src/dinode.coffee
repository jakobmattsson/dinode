core = require './core'
autoDeps = require './autoDeps'
augment = require './augment'

exports.construct = ->
  augmentors = [autoDeps, augment]
  diCore = core.construct({ })
  augmentors.reduce (di, augmentor) ->
    augmentor.construct({ di })
  , diCore
