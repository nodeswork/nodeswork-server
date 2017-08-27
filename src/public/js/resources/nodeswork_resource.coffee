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

        savePreference:
          url:     '/api/v1/users/preferences'
          method:  'POST'
      }
      UserResource

    @TimezoneResource: ($resource) ->
      TimezoneResource = $resource '/api/v1/users/timezones', {}

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
        reset:
          url:     '/api/v1/accounts/:accountId/reset'
          method:  'POST'
      }

    @AccountCategoryResource: ($resource) ->
      AccountCategoryResource = $resource '/api/v1/resources/account-categories/:categoryId', {
        categoryId: '@_id'
      }

    @UserAppletResource: ($resource) ->
      UserAppletResource = $resource '/api/v1/my-applets/:relationId', {
        relationId:  '@_id'
      }, {
        run:
          url:       '/api/v1/my-applets/:relationId/run'
          method:    'POST'
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
      DeviceResource = $resource '/api/v1/my-devices/:deviceId', {
        deviceId: '@_id'
        appletId: '@applet'
        version:  '@version'
      }, {
        applets:
          url:          '/api/v1/my-devices/:deviceId/applets'
          method:       'GET'
          isArray:      true
        save:
          url:          '/api/v1/my-devices'
          method:       'POST'
        runApplet:
          url:          '/api/v1/my-devices/:deviceId/applets/:appletId/:version/process'
          method:       'POST'
        restartApplet:
          url:          '/api/v1/my-devices/:deviceId/applets/:appletId/:version/restart'
          method:       'POST'
      }

    @DevAppletResource: ($resource) ->
      DevAppletResource = $resource '/api/v1/dev/applets/:appletId', {
        appletId: '@_id'
      }, {
      }

    @MessageResource: ($resource) ->
      MessageResource = $resource '/api/v1/messages/:messageId', {
        messageId: '@_id'
      }, {
        view:
          url:     '/api/v1/messages/:messageId/view'
          method:  'POST'
      }

    @ExecutionResource: ($resource) ->
      ExecutionResource = $resource '/api/v1/executions/:executionId', {
        executionId: '@_id'
      }

    @StateResource: ($resource) ->
      StateResource = $resource '/api/v1/users/state', {}
