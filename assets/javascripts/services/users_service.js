angular.module('ChatApp').service('userService', function($http, Dispatcher) {
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
