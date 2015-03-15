angular.module('Utils', [])
  .filter('dateify', function() {
    return function(timeString) {
      return Date.parse(timeString);
    }
  })
  .factory('Dispatcher', function($rootScope) {
    var $scope = $rootScope.$new(true);
    this.$scope = $scope;
    this.services = [];

    this.generateId = function() {
      function s4() {
        return Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
      }

      return s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4();
    };

    $scope.register = function(service) {
      if (this.services.indexOf(service) > -1) return;
      service.__serviceId__ = this.generateId();

      service.$on = function(name, listener) {
        return $scope.$on(service.__serviceId__ + ':' + name, listener);
      };

      service.$broadcast = function(name, args) {
        return $scope.$broadcast(service.__serviceId__ + ':' + name, args);
      };

      this.services.push(service);
    }.bind(this);

    return $scope;
  })
  .factory('GlobalDispatcher', function($rootScope) {
    var $scope = $rootScope.$new(true);
    this.$scope = $scope;
    this.services = [];

    $scope.register = function(service) {
      if (this.services.indexOf(service) > -1) return;

      service.$on = function(name, listener) {
        return $scope.$on(name, listener);
      };

      service.$broadcast = function(name, args) {
        return $scope.$broadcast(name, args);
      };

      this.services.push(service);
    }.bind(this);

    return $scope;
  });
