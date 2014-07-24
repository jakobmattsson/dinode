{contains, inherit} = require './util'

findCycles = (graph, startNode) ->

  step = (current, path) ->
    if path.length > 1000
      throw new Error("Dependency tree too deep (more than 1000 ancestors)")

    graph.getParents(current).forEach (parent) ->
      if contains(path, parent)
        depPath = path.concat([parent]).join(' <- ')
        throw new Error("Circular dependency found: #{depPath}")
      step(parent, path.concat([parent]))

  step(startNode, [startNode])

GraphBase = {
  anyChild: (id, proc) ->
    @getChildren(id).some (name) =>
      proc(name, @getNodeData(name))
}

exports.createGraph = ->

  nodes = {}

  inherit(GraphBase, {
    hasNode: (id) -> nodes[id]?.defined
    getParents: (id) -> nodes[id].parents
    getChildren: (id) -> nodes[id].children
    getNodeData: (id) -> nodes[id].data
    addNode: (id, data, parents) ->

      if @hasNode(id)
        throw new Error("Module '#{id}' defined twice")

      if !nodes[id]?
        nodes[id] = { children: [] }

      nodes[id].defined = true
      nodes[id].parents = parents
      nodes[id].data = data

      parents.forEach (parent) ->
        nodes[parent] ?= { children: [], defined: false, parents: [] }
        nodes[parent].children.push(id)

      findCycles(@, id)
  })
