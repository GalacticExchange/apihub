'use strict';

var clusterGxSettings = angular.module('clustergxSettings', ['ngRoute', 'components', 'directives', 'ngAnimate',
    'ui.bootstrap', 'ui.select', 'ngSanitize', 'ngTableResize', 'gxFilters', 'gxServices', 'ngFileUpload', 'gxUtils']);

clusterGxSettings.constant('ROUTES', {
    USER_MAIN_INFO: '/users/:username/mainInfo',
    USER_AVATAR: '/users/:username/avatar',
    USER_PASSWORD: '/users/:username/password',

    getAddr: function (route) { //todo move to module
        var result = '#' + this[route];
        if (arguments.length > 1) {
            for (var i = 1; i < arguments.length; i++) {
                result = result.replace(/:\w+\/{0}/, arguments[i]);
            }
        }
        return result;
    },

    getNgAddr: function (route) {
        var result = this[route];
        if (arguments.length > 1) {
            for (var i = 1; i < arguments.length; i++) {
                result = result.replace(/:\w+\/{0}/, arguments[i]);
            }
        }
        return result;
    }
});

clusterGxSettings.config(['$routeProvider', 'ROUTES', '$locationProvider',
    function ($routeProvide, ROUTES , $locationProvider) {
        $locationProvider.hashPrefix(''); //todo move to '!' prefix

        $routeProvide.when(ROUTES.USER_MAIN_INFO, {
            template: '<user-main-info></user-main-info>'
        }).when(ROUTES.USER_AVATAR, {
            template: '<user-avatar></user-avatar>'
        }).when(ROUTES.USER_PASSWORD, {
            template: '<user-password></user-password>'
        }).when(ROUTES.TEAM_EDIT, {
            template: '<team-edit></team-edit>'
        }).otherwise({
            template: '<h1>Page not found</h1>'
        });
    }
]);

