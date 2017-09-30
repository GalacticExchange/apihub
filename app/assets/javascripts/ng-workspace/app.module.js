'use strict';

var clusterGxApp = angular.module('clustergxApp', ['ngRoute', 'components', 'directives', 'ngAnimate',
    'ui.bootstrap', 'ui.select', 'ngSanitize', 'ngTableResize', 'gxFilters', 'gxServices', 'gxUtils']);

//when add new Route you should add it to workspace-menu.js.erb
clusterGxApp.constant('ROUTES', {
    NODES: '/clusters/:clusterId/nodes',
    NODES_INFO: '/clusters/:clusterId/nodes/:nodeId',
    NODES_INFO_TEST: '/clusters/:clusterId/nodes_test/:nodeId',
    NODES_SETTINGS: '/clusters/:clusterId/nodes/:nodeId/settings',
    NODES_INST_CHOOSE_TYPE: '/clusters/:clusterId/nodes/install/choose',
    NODES_INST_APP_ONLY: '/clusters/:clusterId/nodes/install/app-only',
    NODES_INST_LOCAL: '/clusters/:clusterId/nodes/install/local',
    NODES_INST_AWS: '/clusters/:clusterId/nodes/install/aws',
    NODES_UNINST_LOCAL: '/clusters/:clusterId/nodes/uninstall/local',
    NODES_INST_REMOTE: '/clusters/:clusterId/nodes/install/remote',
    NODES_UNINST_REMOTE: '/clusters/:clusterId/nodes/uninstall/remote/:nodeId',
    CLUSTER_STATISTICS: '/clusters/:clusterId/statistics',
    NODES_STATISTICS: '/clusters/:clusterId/statistics/nodes/:nodeId',
    SHARES: '/clusters/:clusterId/shares',
    LOGS: '/clusters/:clusterId/logs',
    CONTAINERS: '/clusters/:clusterId/containers',
    CONTAINER_INFO: '/clusters/:clusterId/containers/:containerId',
    CONTAINER_SETTINGS: '/clusters/:clusterId/containers/:containerId/settings',
    CLUSTER_INFO: '/clusters/:clusterId',
    APPLICATIONS: '/clusters/:clusterId/applications',
    APPLICATION_INFO: '/clusters/:clusterId/applications/:applicationId',
    APPLICATION_SETTINGS: '/clusters/:clusterId/applications/:applicationId/settings',
    HDP_APP_SERVICES_BROWSER: '/clusters/:clusterId/hdp/:applicationId/services',
    APPLICATION_SERVICES_BROWSER: '/clusters/:clusterId/applications/:applicationId/services',
    APPLICATION_SERVICES_VIS_BROWSER: '/clusters/:clusterId/applications/:applicationId/services/visualize',
    APPLICATION_SERVICES_TRANS_BROWSER: '/clusters/:clusterId/applications/:applicationId/services/transform',
    LIBRARY_APP_LIST: '/clusters/:clusterId/apphub/applications',
    APPHUB_LIST: '/clusters/:clusterId/apphub/autobuilds',
    DEVELOPMENT_LIST: '/clusters/:clusterId/apphub/development',
    APPHUB_APP: '/clusters/:clusterId/apphub/autobuilds/:appId',
    APPHUB_APP_COMPOSE: '/clusters/:clusterId/apphub/compose/:appId',
    LIBRARY_APP_INFO: '/clusters/:clusterId/apphub/applications/:appName',
    LIBRARY_APP_INST: '/clusters/:clusterId/apphub/applications/:appName/install',


    getAddr: function (route) {
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

clusterGxApp.config(['$routeProvider', 'ROUTES', '$locationProvider',
    function ($routeProvide, ROUTES, $locationProvider) {
        $locationProvider.hashPrefix(''); //todo move to '!' prefix

        $routeProvide.when(ROUTES.NODES, {
            template: '<node-list></node-list>'
        }).when(ROUTES.NODES_INFO, {
            template: '<node-details></node-details>'
        }).when(ROUTES.NODES_INFO_TEST, {
            template: '<node-details-test></node-details-test>'
        }).when(ROUTES.NODES_SETTINGS, {
            template: '<node-edit></node-edit>'
        }).when(ROUTES.SHARES, {
            template: '<share-list></share-list>'
        }).when(ROUTES.LOGS, {
            template: '<log-list></log-list>',
            reloadOnSearch: false
        }).when(ROUTES.CONTAINERS, {
            template: '<container-list></container-list>'
        }).when(ROUTES.CONTAINER_INFO, {
            template: '<container-details></container-details>'
        }).when(ROUTES.CLUSTER_INFO, {
            template: '<cluster-details></cluster-details>'
        }).when(ROUTES.APPLICATIONS, {
            template: '<application-list></application-list>'
        }).when(ROUTES.APPLICATION_INFO, {
            template: '<application-details></application-details>'
        }).when(ROUTES.APPLICATION_SETTINGS, {
            template: '<application-edit></application-edit>'
        }).when(ROUTES.APPLICATION_SERVICES_BROWSER, {
            template: '<application-details></application-details>'
        }).when(ROUTES.APPLICATION_SERVICES_VIS_BROWSER, {
            template: '<application-services-browser></application-services-browser>'
        }).when(ROUTES.APPLICATION_SERVICES_TRANS_BROWSER, {
            template: '<application-services-browser></application-services-browser>'
        }).when(ROUTES.HDP_APP_SERVICES_BROWSER, {
            template: '<application-services-browser></application-services-browser>'
        }).when(ROUTES.LIBRARY_APP_LIST, {
            template: '<library-app-list></library-app-list>'
        }).when(ROUTES.APPHUB_LIST, {
            template: '<apphub-list></apphub-list>',
            reloadOnSearch: false
        }).when(ROUTES.APPHUB_APP, {
            template: '<apphub-app></apphub-app>'
        }).when(ROUTES.APPHUB_APP_COMPOSE, {
            template: '<apphub-app-compose></apphub-app-compose>'
        }).when(ROUTES.DEVELOPMENT_LIST, {
            template: '<development-list></development-list>'
        }).when(ROUTES.LIBRARY_APP_INFO, {
            template: '<library-app-details></library-app-details>'
        }).when(ROUTES.LIBRARY_APP_INST, {
            template: '<library-app-inst></library-app-inst>'
        }).when(ROUTES.CLUSTER_STATISTICS, {
            template: '<node-list-stat></node-list-stat>'
        }).when(ROUTES.NODES_STATISTICS, {
            template: '<node-stat></node-stat>'
        }).when(ROUTES.NODES_INST_CHOOSE_TYPE, {
            template: '<node-inst-choose-type></node-inst-choose-type>'
        }).when(ROUTES.NODES_INST_APP_ONLY, {
            template: '<node-inst-app-only></node-inst-app-only>'
        }).when(ROUTES.NODES_INST_LOCAL, {
            template: '<node-inst-local></node-inst-local>'
        }).when(ROUTES.NODES_INST_AWS, {
            template: '<nodes-inst-aws></nodes-inst-aws>'
        }).when(ROUTES.NODES_UNINST_LOCAL, {
            template: '<node-uninst-local></node-uninst-local>'
        }).when(ROUTES.NODES_INST_REMOTE, {
            template: '<nodes-inst-remote></nodes-inst-remote>'
        }).when(ROUTES.NODES_UNINST_REMOTE, {
            template: '<node-uninst-remote></node-uninst-remote>'
        }).otherwise({
            template: '<h1>Page not found</h1>'
        });
    }
]);