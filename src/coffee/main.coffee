require.config
  baseUrl:                    '/js'
  waitSeconds:                20
  paths:
    angular:                  '../bower_components/angular/angular.min'
    angularMaterial:          '../bower_components/angular-material/angular-material.min'
    angularResource:          '../bower_components/angular-resource/angular-resource.min'
    angularRoute:             '../bower_components/angular-route/angular-route'
    underscore:               '../bower_components/underscore/underscore-min'
  shim:
    angular:
      exports:                'angular'
      deps:                   [  ]
    angularMaterial:
      deps:                   [ 'angular' ]
    angularResource:
      deps:                   [ 'angular' ]
    angularRoute:
      deps:                   [ 'angular' ]
    underscore:
      exports:                '_'

require [
  'angular', 'angularRoute', 'angularResource'

  'routes'

  'controllers/page_controller'

  'resources/nodeswork_resource'
], (
  angular, angularRoute, angularResource

  routes

  PageController

  NodesworkResource
) ->

  app = angular.module 'nodesworkWeb', [
    'ngRoute', 'ngResource'
  ]

  app.config routes

  NodesworkResource.export app
  PageController.export    app

  angular.bootstrap document, ['nodesworkWeb']
