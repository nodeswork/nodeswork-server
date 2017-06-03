define ['controllers/controller'], (Controller) -> new Controller {

  HeaderController: ($rootScope, $document) ->
    titleElement = $document.find('title')[0]
    themeElement = $document[0].getElementById('theme-link')
    bodyElement  = $document.find('body')

    themeLinks = {
      # dev:    '/bower_components/bootstrap/dist/css/bootstrap.min.css'
      # normal: 'https://bootswatch.com/darkly/bootstrap.min.css'
      # dev:    'https://bootswatch.com/cosmo/bootstrap.min.css'
      dev:    'https://bootswatch.com/darkly/bootstrap.min.css'
      normal: 'https://bootswatch.com/sandstone/bootstrap.min.css'
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

  UserAppletController: (_, $, $scope, $routeParams, $location, $document
    UserAppletResource, DeviceResource, ExecutionResource, TimezoneResource
  ) ->
    _.extend $scope, {
      devices:    DeviceResource.query()
      userApplet: UserAppletResource.get(relationId: $routeParams.relationId)
      timezones:  TimezoneResource.query {}, (timezones) ->
        $scope.timezones = ['default'].concat timezones

      saveUserApplet: () ->
        $scope.userApplet.$save()
    }

    onTabChanged = (tab) ->
      switch tab
        when 'executions'
          $scope.userApplet.$promise.then () ->
            _.extend $scope, {
              executions: ExecutionResource.query {
                query:
                  applet: $scope.userApplet.applet._id
              }
            }

    $document.find("a[href='##{$location.hash()}']").tab 'show'
    onTabChanged $location.hash()

    $document.find('a[data-toggle="pill"]').on 'shown.bs.tab', (e) ->
      hashStr = $(e.target).attr('href').substr(1)
      $location.hash hashStr
      onTabChanged hashStr
      $scope.$apply()

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

  DevicesController: (_, $scope, DeviceResource, UserAppletResource) ->
    $scope.userApplets = UserAppletResource.query {}, () ->
      $scope.userAppletsDict = _.object _.map $scope.userApplets, (userApplet) ->
        [userApplet.applet._id, userApplet]

    $scope.devices = DeviceResource.query {}, () ->
      $scope.activeDevice = $scope.devices[0]

    _.extend $scope, {
      onlineApplets: (runningApplets) ->
        _.filter runningApplets, (applet) -> applet.status == 'online'
    }

  MessagesController: ($scope, MessageResource) ->
    $scope.messages = MessageResource.query()

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

  DevAppletEditController: ($scope, $routeParams, DevAppletResource
    AccountCategoryResource
  ) ->
    _.extend $scope, {
      devApplet: DevAppletResource.get(appletId: $routeParams.appletId)

      accountCategories: AccountCategoryResource.query()

      save: () ->
        $scope.devApplet.$save()

      editImage: () ->
        $scope.showImageEditor = !$scope.showImageEditor

      addAccount: () ->
        $scope.devApplet.requiredAccounts.push {
          optional:    false
          multiple:    false
          permission:  'READ'
          usage:       ''
        }
    }

  PreferencesController: (_, $scope, TimezoneResource) ->
    _.extend $scope, {
      timezones:       TimezoneResource.query()

      savePreferences:  () ->
        $scope.user.$savePreference()
    }
}
