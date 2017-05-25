define ['directives/directive'], (Directive) -> new Directive {

  userAppletDirective: () ->
    restrict:     'E'
    templateUrl:  '/views/applets/user-applet-directive.html'
    scope:
      applet:     '=ngModel'

  appletDirective: () ->
    restrict:     'E'
    templateUrl:  '/views/applets/applet-directive.html'
    scope:
      applet:     '=ngModel'

  devAppletDirective: () ->
    restrict:     'E'
    templateUrl:  '/views/dev/dev-applet-directive.html'
    scope:
      applet:     '=ngModel'

  accountDirective: () ->
    restrict:     'E'
    templateUrl:  '/views/accounts/account-directive.html'
    scope:
      account:    '=ngModel'

  fifaFutAccountDirective: (_, $location, AccountResource) ->
    restrict:     'A'
    templateUrl:  '/views/accounts/edit/fifa-fut-account-directive.html'
    scope:
      account:    '=ngModel'
      backUrl:    '='
    link: (scope, element) ->
      _.extend scope, {
        showPassword:  false

        showPasswordChange:  () ->
          element.find("#fifa-fut-password")[0].type = (
            if scope.showPassword then 'text' else 'password'
          )

        saveAccount: () ->
          unless scope.account._id
            scope.account = new AccountResource scope.account
          scope.account.$save(
            () ->
            (error) ->
              console.error error
          )

        cancel: () ->
          $location.path scope.backUrl ? '/accounts'
      }

      scope.$watch(
        "account",
        (newValue, oldValue) ->
          unless JSON.stringify(oldValue) == JSON.stringify(newValue)
            scope.formChanged = true
        true
      )
}
