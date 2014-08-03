Sinatra Realtime Chat
---------------------

# WORK IN PROGRESS (3 Aug 2014), KEEP CALM AND DRINK ALE

Goals
-----

* Decent websocket chat with AngularJS frontend

Bootstrapping
------------

Easy things first: start your PostgreSQL server and create database `chatdb`.

Then clone this repo and run the following commands:

```
$ bundle install
$ npm install -g gulp bower
$ bower install
$ rackup
```

In a separate session run:

```
$ gulp
```

App will be available under link `http://0.0.0.0:9292`

Author(s)
------

[Alvaro F. Lara](http://alvarofernandolara.com.ar)
[Raf Szalanski](http://szalansky.com)
