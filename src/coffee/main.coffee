requirejs.config
  baseUrl:                    '/js'
  waitSeconds:                20
  paths:
    angular:                  '../bower_components/angular/angular.min'
    angularMaterial:          '../bower_components/angular-material/angular-material.min'
    angularResource:          '../bower_components/angular-resource/angular-resource.min'
    angularRoute:             '../bower_components/angular-route/angular-route'
    bootstrap:                '../bower_components/bootstrap/dist/js/bootstrap.min'
    case:                     '../bower_components/Case/dist/Case.min'
    io:                       '../bower_components/socket.io-client/dist/socket.io'
    jquery:                   '../bower_components/jquery/dist/jquery.min'
    underscore:               '../bower_components/underscore/underscore-min'
  shim:
    angular:
      exports:                'angular'
      deps:                   [ 'jquery' ]
    angularMaterial:
      deps:                   [ 'angular' ]
    angularResource:
      deps:                   [ 'angular' ]
    angularRoute:
      deps:                   [ 'angular' ]
    bootstrap:
      deps:                   [ 'angular', 'jquery' ]
    case:
      exports:                'Case'
    underscore:
      exports:                '_'

# somehow requirejs doesn't load jQuery in electron.
requirejs ['jquery'], ($) ->
  window.jQuery = $

  requirejs [
    'angular', 'angularRoute', 'angularResource', 'bootstrap', 'jquery'
    'underscore', 'case', 'io'

    'routes'

    'controllers/page_controller'

    'resources/nodeswork_resource'

    'directives/page_directives'
  ], (
    angular, angularRoute, angularResource, bootstrap, $, _, Case, io

    routes

    PageController

    NodesworkResource

    PageDirectives
  ) ->

    messageSocket = io '/message'

    socket.on 'connect', () ->
      console.log 'message socket is connected.'

    app = angular.module 'nodesworkWeb', [
      'ngRoute', 'ngResource'
    ]

    app.config routes

    app.factory 'messageSocket', () -> messageSocket
    app.factory '_', () -> _
    app.factory '$', () -> $
    app.factory 'Case', () -> Case

    app.filter 'numKeys', () ->
      (json) -> Object.keys(json).length

    NodesworkResource.export app
    PageController.export    app
    PageDirectives.export    app

    angular.bootstrap document, ['nodesworkWeb']
