define [], () ->
  menus = {
    userMenu:
      title:         'Nodeswork'
      mode:          'normal'
      requireLogin:  true
      defaultLink:   '/register'
      items:    [
        {
          name:      'Home'
          link:      '/'
        }
        {
          name:      'Accounts'
          link:      '/accounts'
        }
        {
          name:      'My Applets'
          link:      '/my-applets'
        }
        {
          name:      'Devices'
          link:      '/devices'
        }
        {
          name:      'Explore'
          link:      '/explore'
        }
        {
          name:      'Messages'
          link:      '/messages'
          autohide:  true
        }
        {
          name:      'Preferences'
          link:      '/preferences'
          autohide:  true
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

      .when '/accounts/new', {
        name:         'Accounts'
        menu:         menus.userMenu
        item:         'Accounts'
        controller:   'AccountsEditController'
        templateUrl:  '/views/accounts/edit/index.html'
      }

      .when '/accounts/:accountId/edit', {
        name:         'Accounts'
        menu:         menus.userMenu
        item:         'Accounts'
        controller:   'AccountsEditController'
        templateUrl:  '/views/accounts/edit/index.html'
      }

      .when '/my-applets', {
        name:         'Applets'
        menu:         menus.userMenu
        item:         'My Applets'
        controller:   'UsersAppletsController'
        templateUrl:  '/views/applets/my-applets.html'
      }

      .when '/my-applets/:relationId', {
        name:            'Applets'
        menu:            menus.userMenu
        item:            'My Applets'
        controller:      'UserAppletController'
        templateUrl:     '/views/applets/user-applet.html'
        reloadOnSearch:  false
      }

      # .when '/my-applets/:relationId/config', {
        # name:         'Applets'
        # menu:         menus.userMenu
        # item:         'My Applets'
        # controller:   'UserAppletConfigController'
        # templateUrl:  '/views/applets/my-applet-config.html'
      # }

      .when '/devices', {
        name:         'Devices'
        menu:         menus.userMenu
        item:         'Devices'
        controller:   'DevicesController'
        templateUrl:  '/views/devices/index.html'
      }

      .when '/devices/:deviceId', {
        name:         'Devices'
        menu:         menus.userMenu
        item:         'Devices'
        controller:   'DeviceController'
        templateUrl:  '/views/devices/device.html'
      }

      .when '/messages', {
        name:            'Messages'
        menu:            menus.userMenu
        item:            'Messages'
        controller:      'MessagesController'
        templateUrl:     '/views/messages/index.html'
        reloadOnSearch:  false
      }

      .when '/explore', {
        name:         'Explore'
        menu:         menus.userMenu
        item:         'Explore'
        controller:   'ExploreAppletController'
        templateUrl:  '/views/explore/index.html'
      }

      .when '/preferences', {
        name:         'Preferences'
        menu:         menus.userMenu
        item:         'Preferences'
        controller:   'PreferencesController'
        templateUrl:  '/views/preferences/index.html'
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

      .when '/dev/applets/:appletId/edit', {
        name:         'Developer'
        menu:         menus.devMenu
        item:         'Applets'
        controller:   'DevAppletEditController'
        templateUrl:  '/views/dev/applet-edit.html'
      }

      .otherwise redirectTo: '/'

    $locationProvider.html5Mode {
      enabled:      true
      requireBase:  false
    }
