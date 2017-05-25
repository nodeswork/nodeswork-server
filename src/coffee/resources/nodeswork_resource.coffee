define ['resources/resource'], (Resource) ->

  class NodesworkResource extends Resource

    @UserResource: ($resource) ->
      UserResource = $resource '/api/v1/users/current', {}, {
        login:
          url:     '/api/v1/users/login'
          method:  'POST'
        logout:
          url:     '/api/v1/users/logout'
        register:
          url:     '/api/v1/users/new'
          method:  'POST'
      }
      UserResource


    @AccountResource: ($resource) ->
      AccountResource = $resource '/api/v1/accounts/:accountId', {
        accountId: '@_id'
      }, {
        authorize:
          url:     '/api/v1/accounts/:accountId/authorize'
          method:  'POST'
        twoFactorAuthorize:
          url:     '/api/v1/accounts/:accountId/two-factor-authorize'
          method:  'POST'
      }

    @UserAppletResource: ($resource) ->
      UserAppletResource = $resource '/api/v1/my-applets/:relationId', {
        relationId: '@_id'
      }

    @AppletResource: ($resource) ->
      AppletResource = $resource '/api/v1/applets/:appletId', {
        appletId: '@_id'
      }, {
        explore:
          url:      '/api/v1/explore'
          method:   'GET'
          isArray:  true
      }

    @DeviceResource: ($resource) ->
      DeviceResource = $resource '/api/v1/devices/:deviceId', {
        deviceId: '@_id'
      }, {
        applets:
          url:      '/api/v1/devices/:deviceId/applets'
          method:   'GET'
          isArray:  true
      }


    @DevAppletResource: ($resource) ->
      DevAppletResource = $resource '/api/v1/dev/applets/:appletId', {
        appletId: '@_id'
      }, {
      }
