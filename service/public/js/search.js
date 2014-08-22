function renderScore(repo, data) {
  //$('#health_result #score_in_words').html(data["overall_health"]);
  $('#health_result #score_in_words').html(data["overall_health_score_100"]);
  $('#health_result #score_phrase').html(data["overall_health_phrase"]);

  // Flag or Trophy
  var flag_or_trophy = "fa-flag";
  if(data["overall_health"] == "Great") {
    flag_or_trophy = "fa-trophy";
  }
  $('#health_result i').removeClass();
  $('#health_result i').addClass("fa");
  $('#health_result i').addClass(flag_or_trophy);

  $('#health_result').removeClass();
  $('#health_result').addClass(data["overall_health"]);
  $('#search-repo-label').html(repo);

  // TODO: Probably need to handlebar this 
  $('#last_7_stats li:nth-of-type(1) p:first').html(data["last_7"]["watch_counts"]);
  $('#last_7_stats li:nth-of-type(2) p:first').html(data["last_7"]["fork_counts"]);
  $('#last_7_stats li:nth-of-type(3) p:first').html(data["last_7"]["issue_counts"]);
  $('#last_7_stats li:nth-of-type(4) p:first').html(data["last_7"]["pr_counts"]);
  $('#last_7_stats li:nth-of-type(5) p:first').html(data["last_7"]["push_counts"]);

  $('#last_30_stats li:nth-of-type(1) p:first').html(data["last_30"]["watch_counts"]);
  $('#last_30_stats li:nth-of-type(2) p:first').html(data["last_30"]["fork_counts"]);
  $('#last_30_stats li:nth-of-type(3) p:first').html(data["last_30"]["issue_counts"]);
  $('#last_30_stats li:nth-of-type(4) p:first').html(data["last_30"]["pr_counts"]);
  $('#last_30_stats li:nth-of-type(5) p:first').html(data["last_30"]["push_counts"]);


  $('#results').show();
}

function fetchHealth() {
  // TODO: Do some validation
  var repo = $('#repo').val();

  $('#repo').blur();

  // Do some spinner stuff

  // Request health
  $.ajax("/" + repo + "/health", {
    dataType: "json",
    success: function(data) {
      console.log(data);
      
      renderScore(repo, data);

      // Update url!
    }
  });
}
