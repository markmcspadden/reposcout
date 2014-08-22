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

  $('#last_7_link').click(function(e) {
    e.preventDefault();

    $('#last_30_link').removeClass('current');
    $('#last_7_link').addClass('current');
    $('#last_30_stats').hide();
    $('#last_7_stats').show();
  });

  $('#last_30_link').click(function(e) {
    e.preventDefault();

    $('#last_7_link').removeClass('current');
    $('#last_30_link').addClass('current');
    $('#last_7_stats').hide();
    $('#last_30_stats').show();
  });
});
