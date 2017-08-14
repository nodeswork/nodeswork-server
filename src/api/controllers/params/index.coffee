# Parameter validations.
_                   = require 'underscore'
mongoose            = require 'mongoose'

{ validator
  NAMED
  NodesworkError }  = require '@nodeswork/utils'


# Generate parameters validation Koa middlewares.
#
# @param {Object} rules specifies rules for parsing parameters.
#
# @return [KoaMiddleware] the parameter validation middleware.
params = (rules) ->
  NAMED 'validateParams', (ctx, next) ->
    await validate ctx, rules, ctx.request, []
    await next()


# Rules - Validate if the value does exist.
isRequired = (ctx, val, path) ->
  validator.isRequired val, meta: path: path
  return


wrapValidator = (options, fn) ->
  (ctx, val, path) ->
    return unless val?
    options.meta     ?= {}
    options.meta.path = path
    fn ctx, val, path
    return


isIn = (range, options={}) ->
  wrapValidator options, (ctx, val, path) ->
    validator.isIn val, range, options


equals = (comparison, options={}) ->
  wrapValidator options, (ctx, val, path) ->
    validator.equals val, comparison, options


notEquals = (comparison, options={}) ->
  wrapValidator options, (ctx, val, path) ->
    validator.notEquals val, comparison, options


# Rules - Populate from model based on id(s).
#
# @throw [NodesworkError] error when is is invalid or value doesn't exist.
#
# @return [Model, Array<Model>] the populated model(s).
populateFromModel = (model, query={}) ->
  prepareQuery = (ctx, ids) ->
    dbQuery = _.mapObject query, (val, key) ->
      switch
        when val.startsWith '@' then ctx[val.substring(1)]
        else val
    if _.isArray ids
      model.find _.extend dbQuery, _id: '$in': ids
    else model.findOne _.extend dbQuery, _id: ids


  (ctx, val, path) ->
    switch
      when val? and _.isArray val
        ids     = _.map val, (id) -> mongoose.Types.ObjectId id
        objects = await prepareQuery ctx, ids
        objects = _.object _.map objects, (object) ->
          [object._id.toString(), object]
        for id in val
          validator.isRequired objects[id], {
            meta:
              path: path
              id:   id
            message: 'id is invalid'
          }
          NodesworkError.unkownValue key: path, value: id unless objects[id]?
          objects[id]

      when val?
        object = await prepareQuery ctx, val
        validator.isRequired object, {
          meta:
            path: path
            id:   val
          message: 'id is invalid'
        }
        object

      else val


# @private
# Validate against ctx by rules.
validate = (ctx, rules, target, path) ->
  switch
    when _.isArray rules
      for rule in rules
        value   = await rule ctx, target, path.join('.')
        target  = value if value?
      target

    when _.isFunction rules
      value = await rules ctx, target, path.join('.')
      if value? then value else target

    else
      updates = _.object (
        for field, rule of rules
          [field, await validate ctx, rule, target[field], path.concat [field]]
      )
      for field, value of updates
        target[field] = value
      target


# Shortcut - Validate rules against ctx.body.
#
# @example Use params.body rules instead of params { body: rules }
#   {params} = require './params'
#
#   router.get '/', params.body {...rules}
#
body = (rules) ->
  params body: rules


_.extend params, { body }


rules = {
  isRequired
  isIn
  equals
  notEquals
  populateFromModel
}


module.exports = {
  params
  rules
}
