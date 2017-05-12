define ['underscore'], (_) ->

  # Base class for Controller.
  class Controller

    constructor: (@controllers) ->

    # Export controllers provided by current class to application.  All class
    # methods which name ends with 'Controller' will be exported as angularjs
    # controllers.
    #
    # @param app [App] angularjs application
    export: (app) ->

      _.each @controllers, (controller, name) =>

        return if not name.endsWith 'Controller'

        app.controller name, controller
