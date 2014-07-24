{expect} = require 'chai'
jscov = require 'jscov'
dinode = require jscov.cover('..', 'src', 'index')

describe 'dinode', ->

  beforeEach ->
    @di = dinode.construct()

  it 'sets status "referred" and "waiting" correctly', (done) ->
    @di = dinode.construct({ lazy: true })
    @di.registerModule 'a', ['b'], ->
    expect(@di.introspect()).to.eql {
      a:
        status: 'waiting'
        dependencies: ['b']
        dependants: []
      b:
        status: 'referred' 
        dependencies: []
        dependants: ['a']
    }
    done()

  it 'sets status "ready" correctly', (done) ->
    @di = dinode.construct({ lazy: true })
    @di.registerModule 'a', ['b'], ->
    @di.registerModule null, ['a'], ->
    expect(@di.introspect().a.status).to.eql 'ready'
    done()

  it 'sets status "resolving" and "resolved" correctly', (done) ->
    @di.registerModule 'a', [], =>
      expect(@di.introspect().a.status).to.eql 'resolving'
    @di.registerModule null, ['a'], =>
      expect(@di.introspect().a.status).to.eql 'resolved'
      done()
