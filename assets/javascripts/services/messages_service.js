angular.module('ChatApp').service('messagesService', function(socketsService, GlobalDispatcher) {
  var self = this;
  GlobalDispatcher.register(this);

  this.messages = [];
  this.subscribers = [];

  this.fetchMessages = function() {
    socketsService.send({ method: 'messages' });
  };

  this.fetchedMessages = function(event, data) {
    data.body.forEach(function(entry) {
      self.messages.push(JSON.parse(entry));
    });

    self.notify();
  };

  this.newMessage = function(event, data) {
    self.messages.push(data.body);

    self.notify();
  };

  this.sendMessage = function(message) {
    socketsService.send({ method: 'message', body: { message: message, owner: 'foo'} });
  };

  this.subscribe = function(callback) {
    self.subscribers.push(callback);
  };

  this.notify = function() {
    self.subscribers.forEach(function(callback) {
      callback.call();
    });
  };

  this.$on('sockets:ready', this.fetchMessages);
  this.$on('sockets:messages', this.fetchedMessages);
  this.$on('sockets:message', this.newMessage);;
  socketsService.initializeConnection();

  return this;
});
