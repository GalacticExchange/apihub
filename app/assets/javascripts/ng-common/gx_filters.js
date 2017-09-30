'use strict';

var gxFilters = angular.module("gxFilters", []);

gxFilters.filter('dateTimeFormat', function () {
    return function (time, format) {
        return moment(time).format(format);
    };
});

gxFilters.filter('parseDateTime', function () {
    return function (time, format, strict) {
        return moment(time, format, strict);
    };
});

gxFilters.filter('toTrusted', ['$sce', function ($sce) {
    return function (text) {
        return $sce.trustAsHtml(text);
    }
}]);

gxFilters.filter('numKeys', function() {
    return function(json) {
        var keys = Object.keys(json);
        return keys.length;
    }
});