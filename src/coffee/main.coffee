require.config
  baseUrl:                    '/js'
  waitSeconds:                20
  paths:
    angular:                  '../bower_components/angular/angular.min'
    angularMaterial:          '../bower_components/angular-material/angular-material.min'
    angularResource:          '../bower_components/angular-resource/angular-resource.min'
    angularRoute:             '../bower_components/angular-route/angular-route'
    bootstrap:                '../bower_components/bootstrap/dist/js/bootstrap.min'
    jquery:                   '../bower_components/jquery/dist/jquery.min'
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
    bootstrap:
      deps:                   [ 'jquery' ]
      exports:                '$'
    underscore:
      exports:                '_'

require [
  'angular', 'angularRoute', 'angularResource', 'bootstrap', 'jquery', 'underscore'

  'routes'

  'controllers/page_controller'

  'resources/nodeswork_resource'
], (
  angular, angularRoute, angularResource, bootstrap, $, _

  routes

  PageController

  NodesworkResource
) ->

  app = angular.module 'nodesworkWeb', [
    'ngRoute', 'ngResource'
  ]

  app.config routes

  app.factory '_', () -> _
  app.factory '$', () -> $

  NodesworkResource.export app
  PageController.export    app

  angular.bootstrap document, ['nodesworkWeb']
