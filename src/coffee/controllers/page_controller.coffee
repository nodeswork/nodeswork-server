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
      ]

    $scope.loginInfo = userType: 'EmailUser'
    $rootScope.user = UserResource.get()

    console.log $rootScope.user

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

  AccountsController: ($scope) ->

  HomeController: ($scope) ->

}
