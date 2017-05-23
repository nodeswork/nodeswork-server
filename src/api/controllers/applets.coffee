_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{
  requireLogin
  overrideUserToQuery
  overrideUserToDoc
}                           = require './middlewares'
{
  Applet
  UserApplet
}                           = require '../models'
params                      = require './params'
{ParameterValidationError}  = require '../errors'


exports.appletsRouter = appletsRouter = new KoaRouter prefix: '/my-applets'

appletsRouter

  .use requireLogin

  .get('/', overrideUserToQuery(), UserApplet.findMiddleware {
    populate: ['applet']
  })

  .get('/:relationId', overrideUserToQuery(), UserApplet.getMiddleware {
    field:    'relationId'
    populate: ['applet']
  })

  .post('/:relationId', overrideUserToQuery(), overrideUserToDoc()
    UserApplet.updateMiddleware {
      field: 'relationId'
      omits: ['user', 'applet', 'errMsg']
    }
  )

  # Load applet and verify the permission.
  .post('/'
    params(
      body:
        applet: [
          params.isRequired
          params.populateFromModel Applet
          (ctx, applet) ->
            unless await applet.avaiableTo ctx.user
              throw new ParameterValidationError 'Applet is not available.'
        ]
    )
    overrideUserToDoc()
    UserApplet.createMiddleware {
      fromExtend: false
      populate: ['applet']
    }
  )
