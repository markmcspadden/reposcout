function renderScore(repo, data) {
  //$('#health_result #score_in_words').html(data["overall_health"]);
  $('#health_result #score_in_words').html(data["overall_health_score_100"]);
  $('#health_result #score_phrase').html(data["overall_health_phrase"]);

  $('#result-github-link').attr("href","http://github.com/" + repo + "/pulse")

  // Flag or Trophy
  var flag_or_trophy = "fa-flag";
  if(data["overall_health"] === "Great") {
    flag_or_trophy = "fa-trophy";
  }
  $('#health_result i').removeClass();
  $('#health_result i').addClass("fa");
  $('#health_result i').addClass(flag_or_trophy);

  $('#health_result').removeClass();
  $('#health_result').addClass(data["overall_health"]);
  $('#search-repo-label').html(repo);

  // TODO: Probably need to handlebar this
  console.log("last 30", data["last_30"]);
  console.log("last 30", data["last_30"]["watch_counts"]);

  $('#last_30_stats li:nth-of-type(1) p:first').html(data["last_30"]["watch_count"]);
  $('#last_30_stats li:nth-of-type(2) p:first').html(data["last_30"]["fork_count"]);
  $('#last_30_stats li:nth-of-type(3) p:first').html(data["last_30"]["issue_count"]);
  $('#last_30_stats li:nth-of-type(4) p:first').html(data["last_30"]["pull_request_count"]);
  $('#last_30_stats li:nth-of-type(5) p:first').html(data["last_30"]["push_count"]);

  $('#last_60_stats li:nth-of-type(1) p:first').html(data["last_60"]["watch_count"]);
  $('#last_60_stats li:nth-of-type(2) p:first').html(data["last_60"]["fork_count"]);
  $('#last_60_stats li:nth-of-type(3) p:first').html(data["last_60"]["issue_count"]);
  $('#last_60_stats li:nth-of-type(4) p:first').html(data["last_60"]["pull_request_count"]);
  $('#last_60_stats li:nth-of-type(5) p:first').html(data["last_60"]["push_count"]);

  $('#last_90_stats li:nth-of-type(1) p:first').html(data["last_90"]["watch_count"]);
  $('#last_90_stats li:nth-of-type(2) p:first').html(data["last_90"]["fork_count"]);
  $('#last_90_stats li:nth-of-type(3) p:first').html(data["last_90"]["issue_count"]);
  $('#last_90_stats li:nth-of-type(4) p:first').html(data["last_90"]["pull_request_count"]);
  $('#last_90_stats li:nth-of-type(5) p:first').html(data["last_90"]["push_count"]);


  $('#spinner').hide();
  $('#error').hide();
  $('#results').show();
}

function renderError() {
  $('#spinner').hide();
  $('#results').hide(); 
  $('#error').show();
}

function fetchHealth() {
  // TODO: Do some validation
  var repo = $('#repo').val();

  $('#repo').blur();

  // Do some spinner stuff

  // Request health
  $.ajax("/" + repo + "/health?src=site", {
    dataType: "json",
    beforeSend: function() {
      $('#spinner').show();
      $('#error').hide();
      $('#results').hide();
      return true;
    },
    success: function(data) {
      console.log(data);
      
      renderScore(repo, data);

      // Update url!
    },
    error: function() {
      renderError();
    }
  });
}
