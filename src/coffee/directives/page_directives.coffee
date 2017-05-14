define ['directives/directive'], (Directive) -> new Directive {

  appletDirective: () ->
    restrict: 'E'
    templateUrl: '/views/applets/applet.html'
    scope:
      applet: '=ngModel'
}
