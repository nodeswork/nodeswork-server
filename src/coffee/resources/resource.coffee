define ['underscore'], (_) ->

  # Base class for Resource.
  class Resource

    # Export resources provided by current class to koa application.  All class
    # methods which ends with Resource will be exported as angularjs resources.
    #
    # @param app [App] angularjs application
    @export: (app) ->

      _.each Object.getOwnPropertyNames(@), (name) =>

        return if not name.endsWith 'Resource'

        app.factory name, @[name]
