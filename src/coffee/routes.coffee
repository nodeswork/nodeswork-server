define [], () ->

  ($routeProvider, $locationProvider) ->

    $routeProvider
      .when '/', {
        name:         'Home'
        menu:         'Home'
        controller:   'HomeController'
        templateUrl:  '/views/home/index.html'
      }
      .when '/accounts', {
        name:         'My Accounts'
        menu:         'Accounts'
        controller:   'AccountsController'
        templateUrl:  '/views/accounts/index.html'
      }
      .when '/applets', {
        name:         'My Applets'
        menu:         'Applets'
        controller:   'AppletsController'
        templateUrl:  '/views/applets/index.html'
      }
      .when '/devices', {
        name:         'My Devices'
        menu:         'Devices'
        controller:   'DevicesController'
        templateUrl:  '/views/devices/index.html'
      }
      .when '/explore', {
        name:         'Explore Applets'
        menu:         'Explore'
        controller:   'ExploreAppletController'
        templateUrl:  '/views/explore/index.html'
      }
      .when '/settings', {
        name:         'My Settings'
        menu:         'Settings'
        controller:   'SettingsController'
        templateUrl:  '/views/settings/index.html'
      }
      .otherwise redirectTo: '/'

    $locationProvider.html5Mode
      enabled: true
      requireBase: false
