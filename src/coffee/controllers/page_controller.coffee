define [
  'controllers/controller'
], (Controller) -> new Controller {

  HeaderController: (
    $rootScope, $scope, $document, _, messageSocket, StateResource
  ) ->
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

    messageSocket.on 'state::change', (state) ->
      console.log 'changeMessageState', state
      $rootScope.state = state
      $scope.$apply()

    _.extend $rootScope, {
      changePageTitle: (title) ->
        titleElement.innerHTML = title

      changePageMode:  (mode) ->
        if $rootScope.pageMode != mode
          themeElement.href = themeLinks[mode]
          bodyElement.removeClass 'hide'
          $rootScope.pageMode = mode

      _

      state: StateResource.get()
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
    AccountResource
  ) ->
    _.extend $scope, {
      devices:    DeviceResource.query()
      userApplet: UserAppletResource.get(
        relationId: $routeParams.relationId
        () -> AccountResource.query (accounts) ->
          _.each accounts, (account) ->
            account.selected = account._id in $scope.userApplet.accounts
          $scope.accounts = accounts
      )
      timezones:  TimezoneResource.query {}, (timezones) ->
        $scope.timezones = ['default'].concat timezones
      saveUserApplet: () ->
        $scope.userApplet.$save()
      updateAccountSelect: () ->
        $scope.userApplet.accounts =
          _.chain $scope.accounts
            .filter (account) -> account.selected
            .map (account) -> account._id
            .value()
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
    AccountResource, AccountCategoryResource
  ) ->
    {accountId, accountType, category} = $routeParams

    account = switch
      when accountId
        AccountResource.get(
          accountId: accountId
          (account) -> $scope.accountType = account.category.name
        )
      when accountType == 'FifaFutAccount'
        platform:     'xone'
        accountType:  accountType
      when accountType == 'OAuthAccount'
        accountType:  accountType
        category:     AccountCategoryResource.get(
          categoryId: category
          (category) -> $scope.accountType = category.name
        )

    $editor = $document.find '#account-editor'

    _.extend $scope, {
      account:       account
    }

    updateEditor = () ->
      $scope.accountType ?= Case.capital account.accountType
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

  DeviceController: (_, $scope, $routeParams, $location, $document,
    DeviceResource, ExecutionResource
  ) ->
    _.extend $scope, {
      device: DeviceResource.get(deviceId: $routeParams.deviceId)

      saveDevice: () ->
        $scope.device.$save()
    }
    onTabChanged = (tab) ->
      switch tab
        when 'deployments'
          _.extend $scope, {
            executions: ExecutionResource.query {
              query:
                applet: '592a1b01051dbd2b6ac4568e'
            }
            show: {}
          }

    $document.find("a[href='##{$location.hash()}']").tab 'show'
    onTabChanged $location.hash()

    $document.find('a[data-toggle="pill"]').on 'shown.bs.tab', (e) ->
      hashStr = $(e.target).attr('href').substr(1)
      $location.hash hashStr
      onTabChanged hashStr
      $scope.$apply()

  MessagesController: (_, $scope, MessageResource, $routeParams, $location) ->
    _.extend $scope, {

      loadMessage: (page) ->
        $scope.current = page
        $scope.messages = MessageResource.query page: page, (resp, headers) ->
          $scope.totalPage = headers 'total_page'
          $scope.refreshCounters()

      changePage: (page) ->
        $location.search page: page
        $scope.loadMessage page

      refreshCounters: () ->
        $scope.unread = (
          _.countBy $scope.messages, (message) -> message.views
        )[0] ? 0
    }

    $scope.loadMessage parseInt $routeParams.page ? '0'

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
