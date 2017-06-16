_                 = require 'underscore'
{
  NodesworkError
  validator
}                 = require 'nodeswork-utils'

{Device, User}    = require '../../models'


roles = {
  DEVELOPER: 'developer'
  DEVICE:    'device'
  USER:      'user'
}

# @nodoc
roleValues = _.values roles


# @private
# Detect duplicate users.
updateUserAndRole = (ctx, user) ->
  ctx.user = user unless ctx.user?._id?

  if user?._id?
    unless ctx.user._id.equals user._id
      throw new NodesworkError 'Duplicate users detected.'
    ctx.roles[roles.USER] = true
    ctx.roles[roles.DEVICE] = true if user?.attributes.developer


# Check and extract user as user role.
userRole = (ctx, next) ->
  ctx.roles ?= {}

  user =
    if ctx.session.userId? then await User.findById ctx.session.userId
    else {}

  updateUserAndRole ctx, user

  if user?.attributes?.developer then ctx.roles.developer = true

  await next()


# Check and extract user as device role.
deviceRole = (ctx, next) ->
  ctx.roles   ?= {}

  deviceToken  = ctx.request.headers['device-token']

  if deviceToken?
    ctx.device = await Device.findOne deviceToken: deviceToken
    ctx.roles[roles.DEVICE] = true if ctx.device?

  await next()


# Require any of the roles appear.
requireRoles = (requires...) ->
  (ctx, next) ->
    for role in requires
      validator.isRequired role
      validator.isIn role, roleValues
      return await next() if ctx.roles[role]
    ctx.response.status = 401
    throw new NodesworkError 'Unauthorized', meta: {
      roles:     ctx.roles
      requires:  requires
    }


module.exports = {
  deviceRole
  requireRoles
  roles
  userRole
}
