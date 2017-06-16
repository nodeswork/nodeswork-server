_                            = require 'underscore'
{logger}                     = require 'nodeswork-logger'
{NodesworkError}             = require 'nodeswork-utils'


# Log request and errors.
handleRequest = (ctx, next) ->
  # TODO: move to request logger.
  logger.info "Request:", _.pick ctx.request, 'method', 'url', 'headers'

  try
    await next()
    logger.info 'Request successed', code: ctx.response.status
  catch e
    logger.error 'Request failed:', e
    err                  = NodesworkError.fromError e
    ctx.body             = err.toJSON()
    ctx.response.status  = err.meta?.responseCode ? 500


module.exports = {
  handleRequest
}
