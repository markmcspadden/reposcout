$(function(){
  

  if($('#repo').val() !== "") {
    fetchHealth();
  }

  $('form').submit(function(e) {
    e.preventDefault();

    fetchHealth();
  });
  $('button').click(function(e) {
    e.preventDefault();

    fetchHealth();
  });

  $('#learn-more').click(function(e) {
    e.preventDefault();
    $('#learn-more').hide();
    $('#project-more').show();
  });

  $('#learn-less').click(function(e) {
    e.preventDefault();
    $('#project-more').hide();
    $('#learn-more').show();
  });

  $('#last_30_link').click(function(e) {
    e.preventDefault();

    $('a.time_toggle').removeClass('current');
    $('#last_30_link').addClass('current');

    $('#details ul').hide();
    $('#last_30_stats').show();
  });

  $('#last_60_link').click(function(e) {
    e.preventDefault();

    $('a.time_toggle').removeClass('current');
    $('#last_60_link').addClass('current');

    $('#details ul').hide();
    $('#last_60_stats').show();
  });

  $('#last_90_link').click(function(e) {
    e.preventDefault();

    $('a.time_toggle').removeClass('current');
    $('#last_90_link').addClass('current');

    $('#details ul').hide();
    $('#last_90_stats').show();
  });

});
