define ['directives/directive'], (Directive) -> new Directive {

  userAppletDirective: (_) ->
    restrict:     'E'
    templateUrl:  '/views/applets/user-applet-directive.html'
    scope:
      applet:     '=ngModel'
    link: (scope) ->
      _.extend scope, {
        run: () ->
          scope.applet.$run(
            {},
            (resp) ->
              console.log "Execution success.", resp
            (e) ->
              console.error "Execution failed.", e
          )
      }

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
      if $location.hash() == 'account-verify' and scope.account.$promise?
        element.find('#account-form').removeClass 'active'
        element.find('#account-verify').addClass 'active'
        element.find('.nav-pills').find('a:last').tab 'show'

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
              $location.path "/accounts/#{scope.account._id}/edit#verify-account"

            (resp) ->
              scope.errors = resp.data
          )

        cancel: () ->
          $location.path scope.backUrl ? '/accounts'

        step:   1

        verify: () ->
          scope.verifyError = false
          AccountResource.authorize(
            _id: scope.account._id
            (account) ->
              scope.account        = account
              scope.verifySuccess  = true
            (resp) ->
              console.log resp.data
              if resp.data.message == 'FUT Two factor code required.'
                scope.step = 2
              else
                scope.verifyError = true
                handleResponse resp.data
          )

        sendCode: () ->
          AccountResource.twoFactorAuthorize(
            _id:        scope.account._id
            code:       scope.code
            (account) ->
              scope.account         = account
              scope.verifySuccess   = true
            (resp) ->
              console.log resp.data
              scope.verifyError = true
              scope.step = 1
              handleResponse resp.data
          )
      }

      handleResponse = (error) ->
        if error.details?.code == "403"
          scope.reason = "Your account needs to login on console first."
        if error.details?.code == "500"
          scope.reason = "Your account has been banned."

      scope.$watch(
        "account",
        (newValue, oldValue) ->
          unless JSON.stringify(oldValue) == JSON.stringify(newValue)
            scope.formChanged = true
        true
      )

  messageDirective: () ->
    restrict:     'E'
    templateUrl:  '/views/messages/message-directive.html'
    scope:
      message:    '=ngModel'
}
