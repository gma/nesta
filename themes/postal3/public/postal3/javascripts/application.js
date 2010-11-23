$(document).ready(function() {
  var heading = $("#logo a");
  var words = heading.text().split(" ");
  var span = "<span>" + words.slice(1, words.length).join(" ") + "</span>";
  heading.html(words[0] + " " + span);
});
