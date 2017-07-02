_                            = require 'underscore'
{ logger }                   = require 'nodeswork-logger'
{ NodesworkError }           = require 'nodeswork-utils'


# Log request and errors.
handleRequest = (ctx, next) ->
  # TODO: move to request logger.
  logger.info "Request:", _.pick ctx.request, 'method', 'url', 'headers'

  try
    await next()
    logger.info 'Request successed', code: ctx.response.status
  catch e
    err                  = NodesworkError.fromError e
    logger.error 'Request failed:', err.toJSON()
    ctx.body             = _.omit err.toJSON(), 'stack'
    ctx.response.status  = err.meta?.responseCode ? 500


module.exports = {
  handleRequest
}
