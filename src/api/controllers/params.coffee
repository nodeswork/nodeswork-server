# Parameter validations.
_                = require 'underscore'
mongoose         = require 'mongoose'

{NodesworkError} = require '../errors'


# Generate parameters validation Koa middlewares.
#
# @param {Object} rules specifies rules for parsing parameters.
#
# @return [KoaMiddleware] the parameter validation middleware.
params = (rules) ->
  (ctx, next) ->
    await validate ctx, rules, ctx.request, []
    await next()


# Rules - Validate if the value does exist.
isRequired = (ctx, val, path) ->
  NodesworkError.required "#{path}": val, path
  return


# Rules - Populate from model based on id(s).
#
# @throw [NodesworkError] error when is is invalid or value doesn't exist.
#
# @return [Model, Array<Model>] the populated model(s).
populateFromModel = (model) ->
  (ctx, val, path) ->
    switch
      when val? and _.isArray val
        ids     = _.map val, (id) -> mongoose.Types.ObjectId id
        objects = await model.find _id: '$in': ids
        objects = _.object _.map objects, (object) ->
          [object._id.toString(), object]
        for id in val
          NodesworkError.unkownValue key: path, value: id unless objects[id]?
          objects[id]

      when val?
        object = await model.findById val
        NodesworkError.unkownValue key: path, value: val unless object?
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
  populateFromModel
}


module.exports = {
  params
  rules
}
