define ['controllers/controller'], (Controller) -> new Controller {

  HeaderController: ($rootScope, $document) ->
    titleElement = $document.find('title')[0]
    themeElement = $document[0].getElementById('theme-link')
    bodyElement  = $document.find('body')

    themeLinks = {
      normal: 'https://bootswatch.com/darkly/bootstrap.min.css'
      dev:    'https://bootswatch.com/cosmo/bootstrap.min.css'
      # dev:    '/bower_components/bootstrap/dist/css/bootstrap.min.css'
    }

    _.extend $rootScope, {
      changePageTitle: (title) ->
        titleElement.innerHTML = title

      changePageMode:  (mode) ->
        if $rootScope.pageMode != mode
          themeElement.href = themeLinks[mode]
          bodyElement.removeClass 'hide'
          $rootScope.pageMode = mode
    }

  MenuController: ($rootScope, $scope, $route, $location, UserResource) ->
    _.extend $rootScope, {
      user: UserResource.get()

      isUserLogin: () -> $rootScope.user._id?
    }

    _.extend $scope, {
      loginInfo:
        userType: 'EmailUser'

      login: () ->
        $rootScope.user = UserResource.login $scope.loginInfo
        $location.path '/'

      logout: () ->
        $rootScope.user = UserResource.logout()
        $location.path '/register'
    }

    $rootScope.$on '$locationChangeSuccess', (event, newUrl, oldUrl) ->
      route        = $route.current.$$route
      return unless route?
      $scope.menu  = route.menu
      $rootScope.changePageTitle $scope.menu.title
      $rootScope.changePageMode  $scope.menu.mode

      $rootScope.user.$promise.then () ->
        if $scope.menu.requireLogin and not $rootScope.isUserLogin()
          $location.path route.menu.defaultLink

      for item in $scope.menu.items
        item.active = item.name == route.item
        _.each item.subItems, (subItem) ->
          subItem.active = subItem.name == route.subItem


  UsersAppletsController: ($scope, UserAppletResource) ->
    console.log 'applets', $scope.applets = UserAppletResource.query()

  UserAppletConfigController: ($scope, $routeParams, UserAppletResource
    DeviceResource
  ) ->
    _.extend $scope, {
      devices:    DeviceResource.query()
      userApplet: UserAppletResource.get(relationId: $routeParams.relationId)

      save: () ->
        $scope.userApplet.$save()
    }

  AccountsController: ($scope, AccountResource, $) ->
    console.log 'accounts', $scope.accounts = AccountResource.query()
    $scope.target = {}

    $scope.editAccount = (account) ->
      account.platform ?= 'xone'
      $scope.target = account

    $scope.saveTarget = () ->
      console.log $scope.target
      target = new AccountResource $scope.target
      target.accountType = 'FifaFutAccount'
      console.log target.$save () ->
        $scope.accounts = AccountResource.query()
      $('#FifaFutAccountModal').modal 'hide'

  AccountsEditController: ($scope, $routeParams, $document, $compile, Case,
    AccountResource
  ) ->
    {accountId, accountType} = $routeParams

    account = switch
      when accountId
        AccountResource.get(accountId: accountId)
      when accountType == 'FifaFutAccount'
        platform:     'xone'
        accountType:  accountType

    $editor = $document.find '#account-editor'

    _.extend $scope, {
      account:       account
    }

    updateEditor = () ->
      $scope.accountType = Case.capital account.accountType
      $editor.attr Case.kebab(account.accountType), ''
      $compile($editor) $scope

    if account.$promise? then account.$promise.then updateEditor
    else updateEditor()

  HomeController: ($scope) ->

  DevicesController: ($scope, DeviceResource) ->
    $scope.devices = DeviceResource.query()

  MessagesController: () ->

  ExploreAppletController: ($scope, AppletResource) ->
    console.log 'applets', $scope.applets = AppletResource.explore()

  RegisterController: ($location, $scope, UserResource) ->
    if $scope.isUserLogin() then $location.path '/'

    _.extend $scope, {
      loginInfo:
        userType: 'EmailUser'
      loginErrors: {}

      register: (loginInfo) ->
        switch
          when not loginInfo.email
            $scope.loginErrors = email: 'Email is required.'
          when not loginInfo.password
            $scope.loginErrors = password: 'Password is required.'
          when loginInfo.password != loginInfo.verifyPassword
            $scope.loginErrors = verifyPassword: 'Passwords are different.'
            loginInfo.password = loginInfo.verifyPassword = ''
          else
            UserResource.register(
              loginInfo
              (user) ->
                console.log 'user', user
              (err) ->
                if err?.data?.status == 'error' and err.data.message == 'Dumplite records detected.'
                  $scope.loginErrors = email: 'User already exists.'
                else
                  $scope.loginErrors = email: 'Server error, try again later.'
            )
    }

  DevHomeController: () ->

  DevAppletsController: ($scope, DevAppletResource) ->
    _.extend $scope, {
      devApplets: DevAppletResource.query()
    }

  DevAppletEditController: ($scope, $routeParams, DevAppletResource) ->
    _.extend $scope, {
      devApplet: DevAppletResource.get(appletId: $routeParams.appletId)

      save: () ->
        $scope.devApplet.$save()

      editImage: () ->
        $scope.showImageEditor = !$scope.showImageEditor
    }
}
