var app = angular.module('ChatApp', []);

app.service('messagesService', function($http) {
  var self = this;
  this.messages = [];
  this.listeners = [];
  this.source = new EventSource("/stream");

  this.fetchMessages = function() {
    return $http.get('/messages').then(function(response) {
      return response.data;
    }).then(function(msgs) {
      msgs.forEach(function(entry) {
        self.messages.push(JSON.parse(entry));
      });
    });
  };

  this.registerListener = function(listener_callback) {
    this.listeners.push(listener_callback);
  };

  this.sendMessage = function(message) {
    $http({
      method: 'POST',
      url: '/say',
      data: $.param({ message: message }),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'}
    });
  }

  this.fetchMessages();

  this.source.addEventListener("say", function(e) {
    response = JSON.parse(e.data);
    self.messages.push({ owner: response.owner, body: response.body, created_at: response.created_at });
    self.listeners.forEach(function(update_messages_callback) {
      update_messages_callback.call();
    });
  });
});

app.controller('ChatController', function($scope, messagesService) {
  $scope.messages = messagesService.messages;

  $scope.sendMessage = function() {
    messagesService.sendMessage($scope.message);
  };

  this.updateMessages = function() {
    $scope.$apply(function() {
      $scope.messages = messagesService.messages;
      $scope.message = '';
    });
  };

  messagesService.registerListener(this.updateMessages);
});

app.service('userService', function($http) {
  var self = this;
  this.users = [];
  this.listeners = [];
  this.source = new EventSource("/stream");

  this.fetchUsers = function() {
    return $http.get('/users').then(function(response) {
      return response.data;
    }).then(function(users) {
      users.forEach(function(entry) {
        self.users.push(JSON.parse(entry));
      });
    });
  };

  this.registerListener = function(listener_callback) {
    this.listeners.push(listener_callback);
  };

  this.source.addEventListener("login", function(e) {
    response = JSON.parse(e.data);
    self.users.push({ username: response.user_logged_in.username });
    self.listeners.forEach(function(update_messages_callback) {
      update_messages_callback.call();
    });
  });

  this.source.addEventListener("logout", function(e) {
    response = JSON.parse(e.data);
    var i = 0;
    while(i < self.users.length) {
      if(self.users[i].username == response.user_logged_out.username) {
        self.users.splice(i, 1);
        break;
      }
      i++;
    }
    self.listeners.forEach(function(update_messages_callback) {
      update_messages_callback.call();
    });
  });

  this.fetchUsers();
});

app.controller('UserController', function($scope, userService) {
  $scope.users = userService.users;

  this.updateUsers = function() {
    $scope.$apply(function() {
      $scope.users = userService.users;
    });
  };

  userService.registerListener(this.updateUsers);
});
