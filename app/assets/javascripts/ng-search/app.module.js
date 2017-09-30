'use strict';

var clusterGxSettings = angular.module('clustergxSearch', ['ngRoute', 'components', 'directives', 'ngAnimate',
    'ui.bootstrap', 'ui.select', 'ngSanitize', 'ngTableResize', 'gxFilters', 'gxServices', 'gxUtils']);

clusterGxSettings.constant('ROUTES', {
    SEARCH_USERS: '/search/users',
    SEARCH_TEAMS: '/search/teams',
    SEARCH_CLUSTERS: '/search/clusters',

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

        $routeProvide.when(ROUTES.SEARCH_USERS, {
            template: '<users-search></users-search>',
            reloadOnSearch: false
        }).when(ROUTES.SEARCH_TEAMS, {
            template: '<teams-search></teams-search>',
            reloadOnSearch: false
        }).when(ROUTES.SEARCH_CLUSTERS, {
            template: '<clusters-search></clusters-search>',
            reloadOnSearch: false
        }).otherwise({
            template: '<h1>Page not found</h1>'
        });
    }
]);

