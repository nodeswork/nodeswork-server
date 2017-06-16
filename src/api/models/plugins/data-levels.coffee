_              = require 'underscore'
{ validator }  = require 'nodeswork-utils'

DataLevel = (schema, options={}) ->
  { levels  = [] } = options
  levels    =  [ 'MINIMAL' ].concat levels
  lp        =  null

  modifyProjection = (next) ->
    unless lp?
      lp = levelPaths schema
      lp = _.groupBy lp, (v) -> v.level
      lp = _.mapObject lp, (v) -> _.map v, _.property 'path'

    level = @_fields?.$level
    return next() unless level?

    validator.isIn level, levels, {
      message:  "$level is not one of [#{levels.join ', '}]"
      meta:
        path:   '$level'
    }

    delete @_fields.$level
    for l in levels
      paths = lp[l] ? []
      _.each paths, (p) => @_fields[p] = 1
      if l == level then break

    next()

  schema.pre 'find', modifyProjection
  schema.pre 'findOne', modifyProjection

  return


levelPaths = (schema) ->
  res = []
  schema.eachPath (pathname, schemaType) ->
    res.push path: pathname, level: schemaType.options.dataLevel ? 'MINIMAL'
  return res


module.exports = {
  DataLevel
}
