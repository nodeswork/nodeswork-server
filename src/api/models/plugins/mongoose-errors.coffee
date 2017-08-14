{ NodesworkError } = require '@nodeswork/utils'

HandleMongooseError = (schema, options) ->
  handleError = (err, res, next) ->
    switch
      when err?.name == 'MongoError' and err.code == 11000
        next new NodesworkError 'Duplicate record'
      when err?
        next err

  schema.post 'save', handleError
  schema.post 'update', handleError
  schema.post 'findOneAndUpdate', handleError
  schema.post 'insertMany', handleError


module.exports = {
  HandleMongooseError
}
