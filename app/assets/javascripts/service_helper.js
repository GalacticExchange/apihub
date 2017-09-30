;(function () {
    'use strict';

    var GexServiceHelper = {};

    GexServiceHelper.baseServiceCheck = function (service) {
        if (!service.name) {
            GexUtils.showMessageDialog('Error', 'Service name is empty.');
            return false;
            //} else if (!service.protocol) {
            //    GexUtils.showMessageDialog('Error', service.name + ' service protocol is empty.');
            //    return false;
        } else if (!service.port) {
            GexUtils.showMessageDialog('Error', service.name + ' service port is empty.');
            return false;
        } else if (!(service.masterContainer || GexUtils.currentCluster.clusterType === 'aws') && !service.public_ip) {
            GexUtils.showMessageDialog('Error', service.name + ' service ip address is empty');
            return false;
        }
        return true;
    };

    GexServiceHelper.openNative = function (service, username, password) {
        if (!GexServiceHelper.baseServiceCheck(service)) {
            return;
        }

        if (service.protocol === 'http' || service.protocol === 'https') {
            GexUtils.electron.shell.openExternal(GexServiceHelper.getServiceUrl(service, username));
        } else if (service.protocol === 'ssh') {
            var command = 'gex ssh host --host=' + GexServiceHelper.getServiceSshHost(service)
                + ' --port=' + service.port + ' --username=' + username + ' --password=' + password;

            var proxy = service.socksProxy;
            if (proxy) {
                command += ' --proxy=' + proxy.host;
                command += proxy.user ? ' --proxyUsername=' + proxy.user + ' --proxyPassword=' + proxy.password : '';
            }
            GexUtils.exec(command, function (err) {
                if (err) {
                    GexUtils.showMessageDialog('Error', err.message);
                    return;
                }
            });
        }
    };

    GexServiceHelper.getServiceUrl = function (service, username) {
        if (service.protocol === 'http' || service.protocol === 'https') {
            var url = service.protocol + '://';
            if (service.masterContainer || GexUtils.currentCluster.clusterType === 'aws') {
                url += service.webProxy + '/setcookie?token=' + GexUtils.getToken() + '&u='
                    + encodeURIComponent(service.protocol + '://p' + service.port + '.' + service.webProxy);
            } else {
                url += service.public_ip + ':' + service.port;
            }

            var addUrl;
            if (service.name === 'hue') {
                addUrl = '/accounts/login/' + '?username=' + username + '&password=password';
            } else if (service.name === 'nifi') {
                addUrl = '/nifi';
            }
            if (addUrl) {
                url += service.masterContainer ? encodeURIComponent(addUrl) : addUrl;
            }

            return url;
        } else {
            return null;
        }
    };

    GexServiceHelper.getServiceSshHost = function (service) {
        return service.masterContainer || GexUtils.currentCluster.clusterType === 'aws' ? GexUtils.configProperties.proxy : service.public_ip;
    };

    GexServiceHelper.openNativeSsh = function () {
        var scope = angular.element(document.getElementById('serv-panels-container')).scope();
        scope.$apply(function () {
            scope.openNative();
        });
    };

    window.GexServiceHelper = GexServiceHelper;
}());
