{contains} = require './util'

GraphBase = {
  anyChild: (id, proc) ->
    @getChildren(id).some (name) =>
      proc(name, @getNodeData(name))
}



exports.createGraph = ->

  childIndex = {}
  parentIndex = {}
  nodes = {}
  graph = Object.create(GraphBase)

  findCycles = (current, path, stop) ->
    if path.length > 1000
      throw new Error("Dependency tree too deep (more than 1000 ancestors)")

    graph.getParents(current).forEach (parent) ->
      if contains(path, parent)
        depPath = path.concat([parent]).join(' <- ')
        throw new Error("Circular dependency found: #{depPath}")
      findCycles(parent, path.concat([parent]), stop)


  graph.addNode = (id, data, parents) ->

    if graph.hasNode(id)
      throw new Error("Module '#{id}' defined twice")

    nodes[id] = { data: data }

    parentIndex[id] = parents
    parents.forEach (parent) ->
      childIndex[parent] ?= []
      childIndex[parent].push(id)

    findCycles(id, [id], id)



  graph.getParents = (id) -> parentIndex[id] || []
  graph.getChildren = (id) -> childIndex[id] || []
  graph.getNodeData = (id) -> nodes[id]?.data
  graph.hasNode = (id) -> nodes[id]?

  graph
