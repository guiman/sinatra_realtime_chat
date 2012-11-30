Sinatra Realtime Chat
---------------------

A little chat app using sinatra streaming!

You can try it online [Sinatra realtime app](http://sinatra-realtime-chat.herokuapp.com)

What could you spect from this repo
-----------------------------------

So this is just a pet project I started to learn about:

* sinatra: Looking forward to building simpler and faster apps
* Caching: Investigating about how http and browsers handle caching and be able to improve perfomance this way. I found this article about [different ways of caching](http://betterexplained.com/articles/how-to-optimize-your-site-with-http-caching/)
* SSE (Server Sent Events): This is why I started with sinatra, I'm trying to build more realtime interaction apps with ruby and found out that It's already built in with this framework
* Integration testing: I've been looking for a project to make integration testing with Capybara.

Dependencies
------------

Main:

* sinatra
* data_mapper
* thin (seems like Webrick just is not able to handle connections)
* pg (Postgress db access)

Testing:

* capybara
* poltergeist
* rake
* xpath

Author
------

[Alvaro F. Lara](http://alvarofernandolara.com.ar)