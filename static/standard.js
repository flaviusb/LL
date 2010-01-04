function ShowLogin()
{
  $(".common-form").show("slow");
}

function actionise()
{
  $(".liveactions").sortable({
     update: function(event, ui) {
       var order = [];
       var divs = $(".liveactions").children();
       for (var i = 0; i < divs.length; i++)
       {
         order[i] = {ty: divs[i].getAttribute("type"), da: divs[i].getAttribute("data")};
       }
       $(".liveactions").html("");
       $(".deadactions").html("");
       var ostr = JSON.stringify(order);
       post_action_queue_to_server({aq: ostr});
     }
   });
}

function get_action_queue_from_server()
{
  $(".messagepane").html("");
  $.getJSON('http://localhost:8080/showactions',
    function(data){
      $.each(data['pastactions'], function(i,item){
        if (item.type)
          addpastaction(item.type, item.data);
      });
      $.each(data['futureactions'], function(i,item){
        if (item.type)
          addaction(item.type, item.data);
      });
    });
}

function post_action_queue_to_server(aq)
{
  $.getJSON('http://localhost:8080/submitactions', aq,
    function(data){
      $('.messagepane').html(data['message']);
      $.each(data['pastactions'], function(i,item){
        if (item.type)
          addpastaction(item.type, item.data);
      });
      $.each(data['futureactions'], function(i,item){
        if (item.type)
          addaction(item.type, item.data);
      });
    });
}

function make_action_container(type, data)
{
  return "<div type='" + type + "' data='" + data + "'><h3>" + type + "</h3>" + data + "</div>";
}

function addaction(type, data)
{
  $(".liveactions").append(make_action_container(type, data));
}

function addpastaction(type, data)
{
  $(".deadactions").append(make_action_container(type, data));
}
