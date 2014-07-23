{expect} = require 'chai'
jscov = require 'jscov'
dinode = require jscov.cover('..', 'src', 'index')

describe 'dinode', ->

  beforeEach ->
    @di = dinode.construct()

  it 'can define and run modules', (done) ->
    @di.registerModule 'a', [], () -> { x: 5 }
    @di.registerModule null, ['a'], ({ a }) ->
      expect(a).to.eql { x: 5 }
      done()

  it 'can pass null instead of dependencies and it will be interpreted as no dependencies', (done) ->
    @di.registerModule 'a', null, () -> { x: 5 }
    @di.registerModule null, ['a'], ({ a }) ->
      expect(a).to.eql { x: 5 }
      done()

  it 'can skip dependencies and it will be interpreted as no dependencies', (done) ->
    @di.registerModule 'a', () -> { x: 6 }
    @di.registerModule null, ['a'], ({ a }) ->
      expect(a).to.eql { x: 6 }
      done()

  it 'can define modules after they are depended on', (done) ->
    @di.registerModule null, ['a'], ({ a }) ->
      expect(a).to.eql { x: 5 }
      done()
    @di.registerModule 'a', [], () -> { x: 5 }

  it 'can define modules in an async manner ', (done) ->
    @di.registerModule null, ['a'], ({ a }) ->
      expect(a).to.eql { x: 5 }
      done()
    @di.registerModule 'a', [], (deps, callback) ->
      setTimeout ->
        callback(null, { x: 5 })
      , 1

  it 'catches errors during sync module definitions', (done) ->
    @di = dinode.construct({
      onError: (err) ->
        expect(err).to.be.instanceof Error
        expect(err.message).to.eql "Module 'a' failed during registration: what"
        done()
    })
    @di.registerModule null, ['a'], ({ a }) ->
      expect(a).to.eql { x: 5 }
    @di.registerModule 'a', [], (deps) ->
      throw new Error("what")

  it 'catches errors during async module definitions', (done) ->
    @di = dinode.construct({
      onError: (err) ->
        expect(err).to.be.instanceof Error
        expect(err.message).to.eql "Module 'a' failed during registration: foobar"
        done()
    })
    @di.registerModule null, ['a'], ({ a }) ->
      expect(a).to.eql { x: 5 }
    @di.registerModule 'a', [], (deps, callback) ->
      callback(new Error("foobar"))

  it 'catches errors raised during anonymous module resolutions', (done) ->
    @di = dinode.construct({
      onError: (err) ->
        expect(err).to.be.instanceof Error
        expect(err.message).to.eql "Anonymous module failed during registration: what"
        done()
    })
    @di.registerModule null, [], ->
      throw new Error("what")

  it 'catches errors throw as objects that are not Errors', (done) ->
    @di = dinode.construct({
      onError: (err) ->
        expect(err).to.be.instanceof Error
        expect(err.message).to.eql "Anonymous module failed during registration: 42"
        done()
    })
    @di.registerModule null, [], ->
      throw 42

  it 'calls onError if a module name is defined twice', (done) ->
    @di = dinode.construct({
      onError: (err) ->
        expect(err).to.be.instanceof Error
        expect(err.message).to.eql "Module 'a' defined twice"
        done()
    })
    @di.registerVar('a', 1)
    @di.registerVar('a', 2)

  it 'throws exceptions if onError is invoked but not defined', (done) ->
    @di.registerVar('a', 1)
    expect(=> @di.registerVar('a', 2)).to.throw "Module 'a' defined twice"
    done()

  it 'resolves dependency-free modules in the order they were defined', (done) ->
    res = 0
    @di.registerModule null, [], ->
      expect(res++).to.eql 0
    @di.registerModule null, [], ->
      expect(res++).to.eql 1
      done()

  it 'resolves modules with dependencies in the order they were defined if they resolve in the same tick', (done) ->
    res = 0
    @di.registerModule null, ['a'], ->
      expect(res++).to.eql 0
    @di.registerModule null, ['a'], ->
      expect(res++).to.eql 1
      done()
    @di.registerModule 'a', [], ->

  it 'does not resolve unreferenced modules at all', (done) ->
    @di.registerModule 'a', [], () ->
      throw new Error("should never reach here")
    @di.registerModule null, [], ->
      done()

  it 'calls onError if undefined modules are referenced', (done) ->
    @di = dinode.construct({
      onError: (err) ->
        expect(err).to.be.instanceof Error
        expect(err.message).to.eql "The following dependencies was never defined: not-defined"
        done()
    })
    @di.registerModule null, ['not-defined'], ->
    
  it 'waits for additional module definitions in later ticks if "lazy" has been set to true', (done) ->
    @di = dinode.construct({
      lazy: true
    })
    @di.registerModule null, ['definedLater'], ({ definedLater }) ->
      expect(definedLater).to.eql { x: 7 }
      done()
    setTimeout =>
      @di.registerModule 'definedLater', [], -> { x: 7 }
    , 1

  it 'allows modules without names to be defined in a convenient way', (done) ->
    @di.run [], ->
      done()

  it 'allows run to take dependencies', (done) ->
    @di.registerModule 'a', [], -> { y: 2 }
    @di.run ['a'], ({ a }) ->
      expect(a).to.eql { y: 2 }
      done()

  it 'allows modules without dependencies to be defined in a convenient way', (done) ->
    @di.registerVar('a', 1)
    @di.run ['a'], ({ a }) ->
      expect(a).to.eql 1
      done()

  it 'allows multiple modules without dependencies to be defined at the same time', (done) ->
    @di.registerVars({ a: 2, b: 5 })
    @di.run ['a', 'b'], ({ a, b }) ->
      expect(a).to.eql 2
      expect(b).to.eql 5
      done()

  it 'creates an alias for a module', (done) ->
    @di.registerVars({ a: 2, b: 5 })
    @di.registerAlias('c', 'a')
    @di.run ['c'], ({ c }) ->
      expect(c).to.eql 2
      done()

  it 'registers a property from one module as a module of its own', (done) ->
    @di.registerVars({ a: { x: 2, y: 3 }, b: 5 })
    @di.registerProperty('x', 'a')
    @di.run ['x'], ({ x }) ->
      expect(x).to.eql 2
      done()

  it 'registerProperties registers several properties from one module as modules of their own', (done) ->
    @di.registerVars({ a: { x: 2, y: 3 }, b: 5 })
    @di.registerProperties(['x', 'y'], 'a')
    @di.run ['x', 'y'], ({ x, y }) ->
      expect(x).to.eql 2
      expect(y).to.eql 3
      done()

  it 'registerRequire loads a file, using the given require-function, and defines it as a module', (done) ->
    @di = dinode.construct({
      require: (filename) ->
        { a: 1, name: filename }
    })
    @di.registerRequire('myFile')
    @di.run ['myFile'], ({ myFile }) ->
      expect(myFile).to.eql { a: 1, name: "myFile" }
      done()

  it 'registerRequire can give the module a different name than the file being required', (done) ->
    @di = dinode.construct({
      require: (filename) ->
        { a: 1, name: filename }
    })
    @di.registerRequire('myModName', 'myFile')
    @di.run ['myModName'], ({ myModName }) ->
      expect(myModName).to.eql { a: 1, name: "myFile" }
      done()

  it 'registerRequire loads a file using the builtin require-function if none is given explicitly', (done) ->
    @di.registerRequire('coffee-script')
    @di.run ['coffee-script'], (deps) ->
      expect(deps['coffee-script'].VERSION).to.eql '1.7.1'
      done()

  it 'registerFile loads a file and uses the properties dependsOn and execute to define a module', (done) ->
    @di = dinode.construct({
      require: (filename) ->
        dependsOn: []
        execute: -> { x: filename }
    })
    @di.registerFile('modName', 'myFile')
    @di.run ['modName'], ({ modName }) ->
      expect(modName).to.eql { x: 'myFile' }
      done()

  it 'registerFile can load a file without a dependsOn-property', (done) ->
    @di = dinode.construct({
      require: (filename) ->
        execute: -> { x: filename }
    })
    @di.registerFile('modName', 'myFile')
    @di.run ['modName'], ({ modName }) ->
      expect(modName).to.eql { x: 'myFile' }
      done()

  it 'registerFile cannot load a file without an execute-property', (done) ->
    @di = dinode.construct({
      onError: (err) ->
        expect(err).to.be.instanceof Error
        expect(err.message).to.eql "Failed to register 'modName'. The file 'myFile' does not have an 'execute' property."
        done()
      require: (filename) ->
        what: 'foo'
    })
    @di.registerFile('modName', 'myFile')

  it 'detects circular dependencies', (done) ->
    @di = dinode.construct({
      onError: (err) ->
        expect(err).to.be.instanceof Error
        expect(err.message).to.eql "Circular dependency found: c <- b <- a <- c"
        done()
    })
    @di.registerModule 'a', ['c'], -> 'A'
    @di.registerModule 'b', ['a', 'e'], -> 'B'
    @di.registerModule 'c', ['b'], -> 'C'
    @di.registerModule 'd', ['a'], -> 'D'
    @di.registerModule 'e', [], -> 'E'
    @di.run ['a'], ->

  it 'raises an error if a module depends on itself', (done) ->
    @di = dinode.construct({
      onError: (err) ->
        expect(err).to.be.instanceof Error
        expect(err.message).to.eql "Circular dependency found: a <- a"
        done()
    })
    @di.registerModule 'a', ['a'], () -> { x: 5 }
    @di.registerModule null, ['a'], ->

  it 'raises an error if the dependency tree is too deep (to avoid getting stuck in buggy loops)', (done) ->
    @di = dinode.construct({
      onError: (err) ->
        expect(err).to.be.instanceof Error
        expect(err.message).to.eql "Dependency tree too deep (more than 1000 ancestors)"
        done()
    })
    [0..1010].forEach (e) =>
      @di.registerModule e.toString(), [(e+1).toString()], ->
    @di.registerModule null, ['0'], ->
