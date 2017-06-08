requirejs.config
  baseUrl:                    '/js'
  waitSeconds:                20
  paths:
    angular:                  '../bower_components/angular/angular.min'
    angularMaterial:          '../bower_components/angular-material/angular-material.min'
    angularResource:          '../bower_components/angular-resource/angular-resource.min'
    angularRoute:             '../bower_components/angular-route/angular-route'
    angularStrap:             '../bower_components/angular-strap/dist/angular-strap.min'
    angularStrapTpl:          '../bower_components/angular-strap/dist/angular-strap.tpl.min'
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
    angularStrap:
      deps:                   [ 'angular' ]
    angularStrapTpl:
      deps:                   [ 'angular', 'angularStrap' ]
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
    'underscore', 'case', 'io', 'angularStrapTpl'

    'routes'

    'controllers/page_controller'

    'resources/nodeswork_resource'

    'directives/page_directives'
  ], (
    angular, angularRoute, angularResource, bootstrap, $, _, Case, io
    angularStrapTpl

    routes

    PageController

    NodesworkResource

    PageDirectives
  ) ->

    messageSocket = io '/message'

    messageSocket.on 'connect', () ->
      console.log 'message socket is connected.'

    app = angular.module 'nodesworkWeb', [
      'ngRoute', 'ngResource', 'mgcrea.ngStrap'
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
