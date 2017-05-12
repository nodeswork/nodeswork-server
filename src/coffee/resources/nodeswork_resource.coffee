define ['resources/resource'], (Resource) ->

  class NodesworkResource extends Resource

    @UserResource: ($resource) ->
      UserResource = $resource '/api/v1/users/current', {}, {
        login:
          url: '/api/v1/users/login'
          method: 'POST'
        logout:
          url: '/api/v1/users/logout'
        register:
          url: '/api/v1/users/new'
          method: 'POST'
      }
      UserResource
