var eventSource = new EventSource("/stream");

eventSource.addEventListener("login", function(e) {
  response = jQuery.parseJSON(e.data);
  $("#user_list").append("<li id='"+response.user_logged_in.username+"'><a href='#'>" +response.user_logged_in.username+ "</a></li>"); 
});

eventSource.addEventListener("logout", function(e) {
  response = jQuery.parseJSON(e.data);
  $("#"+response.user_logged_out.username).remove();
});

eventSource.addEventListener("say", function(e) {
  response = jQuery.parseJSON(e.data);
  $("#chat").append("<p><strong>"+ response.owner +":  </strong>"+ response.body +"<span class='pull-right'>"+ response.created_at +"</span></p>");
  $("#chat").animate({ scrollTop: $(document).height() }, "slow");
});

$(document).ready(function(){  
  $("form").on("submit", function(e) {
      $.post('/say', {message: $('#message_input').val()});
      $('#message_input').val(''); $('#message_input').focus();
  		$("#chat").animate({ scrollTop: $(document).height() }, "slow");    
  		e.preventDefault();
  });
});