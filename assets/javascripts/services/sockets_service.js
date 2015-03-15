angular.module('ChatApp').service('socketsService', function(GlobalDispatcher) {
  var self = this;
  GlobalDispatcher.register(this);

  this.initializeConnection = function() {
    ws = new WebSocket('ws://localhost:9292/socket');
    ws.onopen = function() {
      self.$broadcast('sockets:ready');
    };

    ws.onmessage = function(e) {
      data = JSON.parse(e.data);
      self.$broadcast('sockets:' + data.method, data);
    };

    self.socket = ws;
  };

  this.send = function(payload) {
    self.socket.send(JSON.stringify(payload));
  };

  return this;
});
