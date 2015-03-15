angular.module('ChatApp').controller('ChatController', function($scope, messagesService) {
  $scope.messages = messagesService.messages;
  $scope.message = '';

  $scope.sendMessage = function() {
    messagesService.sendMessage($scope.message);
    $scope.message = '';
  };

  this.updateMessages = function() {
    $scope.$apply(function() {
      $scope.messages = messagesService.messages;
    });
  };

  messagesService.subscribe(this.updateMessages);
});
