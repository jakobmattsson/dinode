exports.construct = ->
  augmentors = [
    require './augment'
    require './autoDeps'
  ]
  
  diCore = require('./core').construct({ })
  
  augmentors.reduce (di, augmentor) ->
    augmentor.construct({ di })
  , diCore
