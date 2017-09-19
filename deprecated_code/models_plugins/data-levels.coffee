_              = require 'underscore'

{ validator }  = require '@nodeswork/utils'


MINIMAL   = 'MINIMAL'


DataLevel = (schema, options={}) ->
  schema.levelMap   ?= {}
  schema.dataLevels ?= [ MINIMAL ].concat options.levels ? []

  _addLevelMap schema, _levelPaths schema

  modifyProjection = (next) ->
    level = @_fields?.$level
    return next() unless level?

    validator.isIn level, schema.dataLevels, {
      message:  "$level is not one of [#{schema.dataLevels.join ', '}]"
      meta:
        path:   '$level'
    }

    delete @_fields.$level
    for l in schema.dataLevels
      paths = schema.levelMap[l] ? []
      _.each paths, (p) => @_fields[p] = 1
      if l == level then break

    next()

  schema.pre 'find', modifyProjection
  schema.pre 'findOne', modifyProjection

  return


_levelPaths = (schema) ->
  res = []
  schema.eachPath (pathname, schemaType) ->
    res.push path: pathname, level: schemaType.options.dataLevel ? 'MINIMAL'
  return res


_addLevelMap = (schema, levelPaths) ->
  _addLevelMap schema.parentSchema, levelPaths if schema.parentSchema?
  for { path, level } in levelPaths
    schema.levelMap[level] = _.union schema.levelMap[level], [path]


pop = (path, level) ->
  path:      path
  select:
    $level:  level


module.exports = {
  DataLevel
  pop
}
