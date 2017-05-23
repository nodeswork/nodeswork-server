_                            = require 'underscore'

{ParameterValidationError}   = require '../errors'


module.exports = params = (rules) ->
  (ctx, next) ->
    try
      await validate ctx, rules, ctx.request, []
      await next()
    catch e
      if e instanceof ParameterValidationError
        ctx.body = {
          status: 'error'
          message: e.message
        }
        ctx.response.status = 422
      else
        throw e


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


params.isRequired = (ctx, val, path) ->
  unless val?
    throw new ParameterValidationError "#{path} is required."
  undefined


params.populateFromModel = (model) ->
  (ctx, val, path) ->
    object = await model.findById val
    unless object?
      throw new ParameterValidationError "#{path} is not valid."
    object
