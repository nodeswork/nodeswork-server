define [], () ->
  menus = {
    userMenu:
      title:         'Nodeswork'
      mode:          'normal'
      requireLogin:  true
      defaultLink:   '/register'
      items:    [
        {
          name: 'Home'
          link: '/'
        }
        {
          name: 'Accounts'
          link: '/accounts'
        }
        {
          name: 'My Applets'
          link: '/my-applets'
        }
        {
          name: 'Devices'
          link: '/devices'
        }
        {
          name: 'Explore'
          link: '/explore'
        }
      ]

    publicMenu:
      title:         'Nodeswork'
      mode:          'normal'
      requireLogin:  false
      defaultLink:   '/register'
      items:    [
        {
          name: 'Register'
          link: '/register'
        }
        {
          name: 'Explore'
          link: '/explore'
        }
      ]

    devMenu:
      title:         'Nodeswork Developer'
      mode:          'dev'
      requireLogin:  true
      defaultLink:   '/register'
      items:    [
        {
          name: 'Home'
          link: '/dev'
        }
        {
          name: 'Applets'
          link: '/dev/applets'
        }
      ]
  }

  ($routeProvider, $locationProvider) ->
    $routeProvider

      .when '/', {
        name:         'Home'
        menu:         menus.userMenu
        item:         'Home'
        controller:   'HomeController'
        templateUrl:  '/views/home/index.html'
      }

      .when '/accounts', {
        name:         'Accounts'
        menu:         menus.userMenu
        item:         'Accounts'
        controller:   'AccountsController'
        templateUrl:  '/views/accounts/index.html'
      }

      .when '/my-applets', {
        name:         'Applets'
        menu:         menus.userMenu
        item:         'My Applets'
        controller:   'AppletsController'
        templateUrl:  '/views/applets/index.html'
      }

      .when '/devices', {
        name:         'Devices'
        menu:         menus.userMenu
        item:         'Devices'
        controller:   'DevicesController'
        templateUrl:  '/views/devices/index.html'
      }

      .when '/explore', {
        name:         'Explore'
        menu:         menus.userMenu
        item:         'Explore'
        controller:   'ExploreAppletController'
        templateUrl:  '/views/explore/index.html'
      }

      .when '/settings', {
        name:         'My Settings'
        menu:         menus.userMenu
        item:         'Settings'
        controller:   'SettingsController'
        templateUrl:  '/views/settings/index.html'
      }

      .when '/register', {
        name:         'Register'
        menu:         menus.publicMenu
        item:         'Register'
        controller:   'RegisterController'
        templateUrl:  '/views/auth/register.html'
      }

      .when '/dev', {
        name:         'Developer'
        menu:         menus.devMenu
        item:         'Home'
        controller:   'DevHomeController'
        templateUrl:  '/views/dev/index.html'
      }

      .when '/dev/applets', {
        name:         'Developer'
        menu:         menus.devMenu
        item:         'Applets'
        controller:   'DevAppletsController'
        templateUrl:  '/views/dev/applets.html'
      }

      .otherwise redirectTo: '/'

    $locationProvider.html5Mode {
      enabled:      true
      requireBase:  false
    }
