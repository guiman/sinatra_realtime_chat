var eventSource = new EventSource("/stream");

$(document).ready(function(){
  
  $(document).bind("logout", function(event, response) { $("#"+response.message.user_logged_out.username).remove(); });
  $(document).bind("login",  function(event, response) { $("#user_list").append("<li id='"+response.message.user_logged_in.username+"'><a href='#'>" +response.message.user_logged_in.username+ "</a></li>"); });
  $(document).bind("update", function(event, response) {
    $("#chat").append("<p><strong>"+ response.message.owner +":  </strong>"+ response.message.body +"<span class='pull-right'>"+ response.message.created_at +"</span></p>");
    $("#chat").animate({ scrollTop: $(document).height() }, "slow");
  });
  
  eventSource.addEventListener("message", function(e) {
    $(document).trigger("")
    
    response = jQuery.parseJSON(e.data);
    
    switch(response.type)
    {
      case 0: $(document).trigger("login", response);
      break;
    
      case 1: $(document).trigger("logout", response);
      break;
    
      case 2: $(document).trigger("update", response);
  		break;
    }
  });

  $("form").live("submit", function(e) {
      $.post('/say', {message: $('#message_input').val()});
      $('#message_input').val(''); $('#message_input').focus();
  		$("#chat").animate({ scrollTop: $(document).height() }, "slow");    
  		e.preventDefault();
  });
});