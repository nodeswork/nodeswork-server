define ['directives/directive'], (Directive) -> new Directive {

  userAppletDirective: () ->
    restrict: 'E'
    templateUrl: '/views/applets/user-applet-directive.html'
    scope:
      applet: '=ngModel'

  appletDirective: () ->
    restrict: 'E'
    templateUrl: '/views/applets/applet-directive.html'
    scope:
      applet: '=ngModel'

  devAppletDirective: () ->
    restrict: 'E'
    templateUrl: '/views/dev/dev-applet-directive.html'
    scope:
      applet: '=ngModel'
}
