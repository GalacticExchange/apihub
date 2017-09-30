'use strict';

var cgxClusterManage = angular.module('cgxClustersManage', ['ngRoute', 'components', 'directives', 'ngAnimate',
    'ui.bootstrap', 'ui.select', 'ngSanitize', 'ngTableResize', 'gxFilters', 'gxServices', 'ngFileUpload', 'gxUtils']);

cgxClusterManage.constant('ROUTES', {
    CLUSTERS: '/clusters',
    CLUSTERS_SHARED: '/clusters-shared',
    CLUSTER_EDIT: '/clusters/:clusterId/settings',
    CLUSTERS_NEW_AWS: '/clusters/new/aws',
    CLUSTERS_NEW_ONPREM: '/clusters/new/onprem',
    CLUSTERS_NEW_WIZARD: '/clusters/new/wizard',
    CLUSTERS_NEW_COMPONENTS: '/clusters/new/components',
    CLUSTERS_WIZARD_WAIT: '/clusters/:clusterId/wizard/wait',

    KEYS: '/keys',

    TEAM_INVITATIONS: '/team/invitations',
    TEAM_EDIT: '/team/edit',
    TEAM_MEMBERS: '/team/members',
    TEAM_MEMBER_EDIT: '/team/members/:username/edit',

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

cgxClusterManage.config(['$routeProvider', 'ROUTES', '$locationProvider',
    function ($routeProvide, ROUTES, $locationProvider) {
        $locationProvider.hashPrefix(''); //todo move to '!' prefix

        $routeProvide.when(ROUTES.CLUSTERS, {
            template: '<clusters></clusters>'
        }).when(ROUTES.CLUSTERS_SHARED, {
            template: '<clusters-shared></clusters-shared>'
        }).when(ROUTES.CLUSTER_EDIT, {
            template: '<cluster-edit></cluster-edit>'
        }).when(ROUTES.CLUSTERS_NEW_AWS, {
            template: '<clusters-new-aws></clusters-new-aws>'
        }).when(ROUTES.CLUSTERS_NEW_ONPREM, {
            template: '<clusters-new-onprem></clusters-new-onprem>'
        }).when(ROUTES.CLUSTERS_NEW_WIZARD, {
            template: '<clusters-new-wizard></clusters-new-wizard>'
        }).when(ROUTES.CLUSTERS_NEW_COMPONENTS, {
            template: '<clusters-new-components></clusters-new-components>'
        }).when(ROUTES.CLUSTERS_WIZARD_WAIT, {
            template: '<clusters-wizard-wait></clusters-wizard-wait>'
        }).when(ROUTES.KEYS, {
            template: '<keys></keys>'
        }).when(ROUTES.TEAM_INVITATIONS, {
            template: '<team-invitations></team-invitations>'
        }).when(ROUTES.TEAM_MEMBERS, {
            template: '<team-members></team-members>'
        }).when(ROUTES.TEAM_MEMBER_EDIT, {
            template: '<team-member-edit></team-member-edit>'
        }).when(ROUTES.TEAM_EDIT, {
            template: '<team-edit></team-edit>'
        }).otherwise({
            template: '<h1>Page not found</h1>'
        });
    }
]);

