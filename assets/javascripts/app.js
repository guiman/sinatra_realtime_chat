var app = angular.module('ChatApp', ['Utils', 'luegg.directives', 'ngSanitize', 'giffy', 'keys']);

app.service('messagesService', function($http, Dispatcher) {
  var self = this;
  this.messages = [];
  this.source = new EventSource("/stream");
  Dispatcher.register(this);

  this.fetchMessages = function() {
    return $http.get('/messages').then(function(response) {
      return response.data;
    }).then(function(msgs) {
      msgs.forEach(function(entry) {
        self.messages.push(JSON.parse(entry));
      });
    });
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
    self.$broadcast('messages:updated');
  });
});

app.controller('ChatController', function($scope, messagesService) {
  $scope.messages = messagesService.messages;

  $scope.sendMessage = function() {
    messagesService.sendMessage($scope.message);
    $scope.message = '';
  };

  this.updateMessages = function() {
    $scope.$apply(function() {
      $scope.messages = messagesService.messages;
    });
  };

  messagesService.$on('messages:updated', this.updateMessages);
});

app.service('userService', function($http, Dispatcher) {
  var self = this;
  this.users = [];
  this.source = new EventSource("/stream");
  Dispatcher.register(this);

  this.fetchUsers = function() {
    return $http.get('/users').then(function(response) {
      return response.data;
    }).then(function(users) {
      users.forEach(function(entry) {
        self.users.push(JSON.parse(entry));
      });
    });
  };

  this.source.addEventListener("login", function(e) {
    response = JSON.parse(e.data);
    self.users.push({ username: response.user_logged_in.username });
    self.$broadcast('users:updated');
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
    self.$broadcast('users:updated');
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

  userService.$on('users:updated', this.updateUsers);
});
