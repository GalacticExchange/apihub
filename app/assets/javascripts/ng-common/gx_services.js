'use strict';

var gxServices = angular.module("gxServices", []);

gxServices.factory('messageEx', function () {

    var data = {
        message: undefined
    };

    return {
        getMessage: function () {
            return data.message;
        },
        setMessage: function (message) {
            data.message = message;
        }
    };
});

gxServices.factory('updateMdlComp', ['$timeout', function ($timeout) {
    return {
        upgradeDom: function () {
            $timeout(function () {
                componentHandler.upgradeDom();
            }, 500);
        },
        upgradeAllRegistered: function () {
            $timeout(function () {
                componentHandler.upgradeAllRegistered();
            }, 500);
        }
    };
}]);

gxServices.factory('paramsData', function() {
    var jsonData;
    return {
        setData: function(data) {
            jsonData = data;
        },
        getData: function() {
            return jsonData;
        }
    }
});