
{ NodesworkError }  = require 'nodeswork-utils'


class ParameterValidationError extends NodesworkError

  constructor: (message, errorCode) ->
    super message, responseCode: errorCode


module.exports = {

  FUT_TWO_FACTOR_CODE_REQUIRED: 'FUT Two factor code required.'
  FUT_TWO_FACTOR_FUNCTION_NOT_FOUND: 'FUT Two factor function not found.'
  FUT_API_CLIENT_IS_NOT_AUTHORIZED: 'FUT client is not authorized.'

  NodesworkError: NodesworkError = (@message, @errorCode=422) ->

  ParameterValidationError
}
