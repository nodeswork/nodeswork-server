define ['underscore'], (_) ->

  # Base class for Directive.
  class Directive

    constructor: (@directives) ->

    # Export controllers provided by current class to application.  All class
    # methods which name ends with 'Controller' will be exported as angularjs
    # controllers.
    #
    # @param app [App] angularjs application
    export: (app) ->

      _.each @directives, (directive, name) =>

        return if not name.endsWith 'Directive'

        app.directive name.substring(0, name.length - 9), directive
