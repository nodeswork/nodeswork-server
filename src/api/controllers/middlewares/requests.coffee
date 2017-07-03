_                            = require 'underscore'
{ logger }                   = require 'nodeswork-logger'
{ NodesworkError }           = require 'nodeswork-utils'


# Log request and errors.
handleRequest = (ctx, next) ->
  # TODO: move to request logger.
  logger.info "Request:", _.pick ctx.request, 'method', 'url', 'headers'

  try
    await next()
    logger.info 'Request successed', {
      code:       ctx.response.status
      callstack:  ctx.callstack
    }
  catch e
    err                  = NodesworkError.fromError e
    logger.error 'Request failed:', _.extend(
      err.toJSON(), callstack: ctx.callstack
    )
    ctx.body             = _.omit err.toJSON(), 'stack'
    ctx.response.status  = err.meta?.responseCode ? 500


attachCallstack = (fn) ->
  (ctx, next) ->
    ctx.callstack ?= []
    ctx.callstack.push fn.name
    fn ctx, next


module.exports = {
  attachCallstack
  handleRequest
}
