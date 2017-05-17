models     = require './models'
{router}   = require './controllers'
{attachIO} = require './sockets'


module.exports = {
  models:   models
  router:   router
  attachIO: attachIO
}
