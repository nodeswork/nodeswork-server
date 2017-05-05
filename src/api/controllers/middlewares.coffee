
exports.requireLogin = (ctx, next) ->
  unless ctx.user?._id? then ctx.response.status = 401
  else await next()
