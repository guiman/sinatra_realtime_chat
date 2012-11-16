var eventSource = new EventSource("/stream");

eventSource.onmessage = function(e) {
  response = jQuery.parseJSON(e.data);
  switch(response.type)
  {
    case 0: $("#user_list").append("<li id='"+response.user_logged_in+"'><a href='#'>" +response.user_logged_in+ "</a></li>");
    break;
    
    case 1: $("#"+response.user_logged_out).remove();
    break;
    
    case 2: $("#chat").append("<p><strong>"+ response.owner +":  </strong>"+ response.body +"<span class='pull-right'>"+ response.created_at +"</span></p>");
    break;
  }
}

$("form").live("submit", function(e) {
    $.post('/say', {message: $('#message_input').val()});
    $('#message_input').val(''); $('#message_input').focus();
    e.preventDefault();
});