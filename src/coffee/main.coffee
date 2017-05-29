require.config
  baseUrl:                    '/js'
  waitSeconds:                20
  paths:
    angular:                  '../bower_components/angular/angular.min'
    angularMaterial:          '../bower_components/angular-material/angular-material.min'
    angularResource:          '../bower_components/angular-resource/angular-resource.min'
    angularRoute:             '../bower_components/angular-route/angular-route'
    bootstrap:                '../bower_components/bootstrap/dist/js/bootstrap.min'
    case:                     '../bower_components/Case/dist/Case.min'
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
      deps:                   [ 'angular' ]
      exports:                '$'
    case:
      exports:                'Case'
    underscore:
      exports:                '_'

require [
  'angular', 'angularRoute', 'angularResource', 'bootstrap'
  'underscore', 'case'

  'routes'

  'controllers/page_controller'

  'resources/nodeswork_resource'

  'directives/page_directives'
], (
  angular, angularRoute, angularResource, bootstrap, _, Case

  routes

  PageController

  NodesworkResource

  PageDirectives
) ->

  app = angular.module 'nodesworkWeb', [
    'ngRoute', 'ngResource'
  ]

  app.config routes

  app.factory '_', () -> _
  # app.factory '$', () -> $
  app.factory 'Case', () -> Case

  app.filter 'numKeys', () ->
    (json) -> Object.keys(json).length

  NodesworkResource.export app
  PageController.export    app
  PageDirectives.export    app

  angular.bootstrap document, ['nodesworkWeb']
