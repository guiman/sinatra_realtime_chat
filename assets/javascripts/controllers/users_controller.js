angular.module('ChatApp').controller('UserController', function($scope, userService) {
  $scope.users = userService.users;

  this.updateUsers = function() {
    $scope.$apply(function() {
      $scope.users = userService.users;
    });
  };

  userService.$on('users:updated', this.updateUsers);
});
