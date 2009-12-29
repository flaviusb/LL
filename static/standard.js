function ShowLogin()
{
  $(".common-form").show("slow");
}

function actionise()
{
  $(".liveactions").sortable();
}

function make_action_container(type, data)
{
  return "<div><h3>" + type + "</h3>" + data + "</div>";
}

function addaction(type, data)
{
  $(".liveactions").append(make_action_container(type, data));
}
