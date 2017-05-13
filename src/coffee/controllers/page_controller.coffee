define ['controllers/controller'], (Controller) -> new Controller {

  MenuController: ($rootScope, $scope, $route, UserResource) ->
    $rootScope.menu =
      active: 'request'
      title: 'Automation'
      items: [
        {
          name:      'Home'
          active:    true
          link:      '/'
        }
        {
          name:      'Accounts'
          active:    false
          link:      '/accounts'
        }
        {
          name:      'Applets'
          active:    false
          link:      '/applets'
        }
        {
          name:      'Devices'
          active:    false
          link:      '/devices'
        }
        {
          name:      'Explore'
          active:    false
          link:      '/explore'
        }
      ]

    $scope.loginInfo = userType: 'EmailUser'
    $rootScope.user = UserResource.get()

    console.log 'user', $rootScope.user

    $scope.login = () ->
      $rootScope.user = UserResource.login $scope.loginInfo

    $scope.logout = () ->
      $rootScope.user = UserResource.logout()

    activeMenu = (route) ->
      for item in $rootScope.menu.items
        item.active = item.name == route?.menu
        _.each item.subItems, (subItem) ->
          subItem.active = subItem.name == route?.subMenu

    $rootScope.$on '$locationChangeSuccess', (event, newUrl, oldUrl) ->
      activeMenu $route.current?.$$route


  AppletsController: ($scope) ->

  AccountsController: ($scope, AccountResource, $) ->
    console.log $
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

  HomeController: ($scope) ->

  DevicesController: ($scope) ->

  ExploreAppletController: ($scope, AppletResource) ->
    console.log 'applets', $scope.applets = AppletResource.query()

}
