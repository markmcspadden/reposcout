// Copyright (c) 2014 Mark McSpadden


// TODO: Y U NO HAVE JQUERY BUILT IN? :(
function getHealth() {
  var repo = chrome.extension.getBackgroundPage().selectedRepo;
  var repoDetails = chrome.extension.getBackgroundPage().selectedRepoDetails;
  if(repo) {
    // Content  
    document.getElementById("repo-name").innerHTML = repo;
    document.getElementById("overall-health").innerHTML = repoDetails["overall_health_score_100"];
    document.getElementById("overall-health-phrase").innerHTML = repoDetails["overall_health_phrase"];
    document.getElementById("repo-scout-link").href = "http://reposcout.com/search/" + repo;
  
    // Style
    document.getElementById("results").className = repoDetails["overall_health"];

    // Flag or Trophy
    var flag_or_trophy = "fa-flag";
    if(repoDetails["overall_health"] === "Great") {
      flag_or_trophy = "fa-trophy";
    }

    document.getElementById("icon").className = "fa " + flag_or_trophy;
  }
  else {
    //$('#repo-name').html("[NOT FOUND]"); 
    document.getElementById("repo-name").innerHTML = "[NOT FOUND]";
  }
}

window.onload = getHealth;
