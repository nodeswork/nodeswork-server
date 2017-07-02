
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


NodesworkError.required = (target, key) ->
  unless target[key]?
    throw new NodesworkError "Missing parameter #{key}"

NodesworkError.unkownValue = ({key, value}) ->
  throw new NodesworkError "Unkown parameter #{key} with value #{value}"

NodesworkError.mongooseError = (e) ->
  switch
    when e.name == 'MongoError' and e.code == 11000
      throw new NodesworkError "Duplicate record detected."
    else throw new NodesworkError "Unknown MongoError"
