var charsheet = null, charsheetadjusted = null;
var loginshowing = false;

$(document).ready(function() {
  var toggle = function(direction, display) {
    return function() {
      var self = this;
      var ul = $("ul", this);
      if( ul.css("display") == display && !self["block" + direction] ) {
        self["block" + direction] = true;
        ul["slide" + direction]("slow", function() {
          self["block" + direction] = false;
        });
      }
    };
  }
  $("li.menu").hover(toggle("Down", "none"), toggle("Up", "block"));
  $("li.menu ul").hide();
});

function initialise_charsheet()
{
  $.getJSON('/csjson',
    function(data){
      charsheet = JSON.parse(JSON.stringify(data)).charsheet;
      charsheetadjusted = JSON.parse(JSON.stringify(data)).orange;
    }); 
}

function path_walker(root, path)
{
  if (path && path.length > 0)
  {
    var foo = path.shift();
    return path_walker(root[foo], path);
  }
  return root;
}

function path_set(root, path, value)
{
  switch (path.length)
  {
    case 0:
      root = value;
      break;
    case 1:
      root[path[0]] = value;
      break;
    case 2:
      root[path[0]][path[1]] = value;
      break;
  }
  return root;
}

function path_get(root, path)
{
  switch (path.length)
  {
    case 0:
      return root;
      break;
    case 1:
      return root[path[0]];
      break;
    case 2:
      return root[path[0]][path[1]];
      break;
  }
  return null;
}


function cd_action(name, value)
{
  var path = name.split("/");
  //alert(JSON.stringify(path));
  var base = parseInt(path_get(charsheet, path));
  var adj  = parseInt(path_get(charsheetadjusted, path));
  //alert(JSON.stringify(charsheetadjusted));
  var extent = (adj < value) ? value : adj;
  //alert("Value: " + value + ", Extent: " + extent + "Base: " + base);
  if (adj == value)
  {
    // In this case, toggle
    value--;
  }
  //if (value <= base)
  //  charsheetadjusted = path_set(charsheetadjusted, path, base);
  //else
  charsheetadjusted = path_set(charsheetadjusted, path, value);
  //alert(JSON.stringify(charsheetadjusted));
  for (var i = base + 1; i <= extent; i++)
  {
    //alert(name + "/" + i);
    if (i <= value)
    {
      if (createAction(name, i))
      {
        document.getElementById(name + '/' + i).src = 's/o.png';
      }
    } else {
      if (removeAction(name, i))
      {
        document.getElementById(name + '/' + i).src = 's/w.png';
      }
    }
  }
}

function cd_direct(name, value)
{
  var path = name.split("/");
  //alert(JSON.stringify(path));
  var base = parseInt(path_get(charsheet, path));
  //alert(JSON.stringify(charsheetadjusted));
  var extent = (base < value) ? value : base;
  //alert("Value: " + value + ", Extent: " + extent + "Base: " + base);
  if (base == value)
  {
    // In this case, toggle
    value--;
  }
  //if (value <= base)
  //  charsheetadjusted = path_set(charsheetadjusted, path, base);
  //else
  charsheet = path_set(charsheet, path, value);
  //alert(JSON.stringify(charsheet));
  for (var i = 1; i <= extent; i++)
  {
    //alert(name + "/" + i);
    if (i <= value)
    {
      document.getElementById(name + '/' + i).src = 's/b.png';
      if (i == value)
      {
        $.getJSON('/submitcharsheet', {cs: JSON.stringify(charsheet)});
      }
    } else {
      document.getElementById(name + '/' + i).src = 's/w.png';
    }
  }
}


function ShowLogin()
{
  loginshowing = !loginshowing;
  if(loginshowing)
    $("#signin_menu").show("slow");
  else
    $("#signin_menu").hide("slow");
}

var showing = {};
function ShowID(id)
{
  if (!showing[id])
    $('#' + id).show('fast');
  showing[id] = true;
}
function HideID(id)
{
  if (showing[id])
    $('#' + id).hide('fast');
  showing[id] = false;
}

function get_aq_structure_from_server()
{
}

function pull_from_server()
{
}

function push_to_server()
{
}

function openlongpoll()
{

}
function newAction(name, num)
{
  return {ty: "XP Spend", da: name + "/" + num};
}
function createAction(name, num)
{
  $.getJSON('/addaction', newAction(name, num));
  return true;
}
function removeAction(name, num)
{
  $.getJSON('/removeaction', newAction(name, num));
  return true;
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
  $.getJSON('/showactions',
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
  $.getJSON('/submitactions', aq,
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
