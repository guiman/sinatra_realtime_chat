var eventSource = new EventSource("/stream");

eventSource.onmessage = function(e) {
  response = jQuery.parseJSON(e.data);
  console.log(response);
  switch(response.type)
  {
    case 0: $("#user_list").append("<li id='"+response.message.user_logged_in.username+"'><a href='#'>" +response.message.user_logged_in.username+ "</a></li>");
    break;
    
    case 1: $("#"+response.message.user_logged_out.username).remove();
    break;
    
    case 2: $("#chat").append("<p><strong>"+ response.message.owner +":  </strong>"+ response.message.body +"<span class='pull-right'>"+ response.message.created_at +"</span></p>");
    $("#chat").animate({ scrollTop: $(document).height() }, "slow");
		break;
  }
}

$("form").live("submit", function(e) {
    $.post('/say', {message: $('#message_input').val()});
    $('#message_input').val(''); $('#message_input').focus();
		$("#chat").animate({ scrollTop: $(document).height() }, "slow");    
		e.preventDefault();
});