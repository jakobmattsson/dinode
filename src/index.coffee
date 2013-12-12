exports.construct = ->
  augmentors = [
    require './autoDeps'
    require './augment'
  ]
  
  diCore = require('./core').construct({ })
  
  augmentors.reduce (di, augmentor) ->
    augmentor.construct({ di })
  , diCore
