// Copyright (c) 2014 Mark McSpadden


// TODO: Y U NO HAVE JQUERY BUILT IN? :(
function getHealth() {
  var repo = chrome.extension.getBackgroundPage().selectedRepo;
  var repoDetails = chrome.extension.getBackgroundPage().selectedRepoDetails;
  if(repo) {
    //$('#repo-name').html(repo);
    document.getElementById("repo-name").innerHTML = repo;
    document.getElementById("overall-health").innerHTML = repoDetails["overall_health"];
    document.getElementById("details").innerHTML = repoDetails["last_7"].toString();
  }
  else {
    //$('#repo-name').html("[NOT FOUND]"); 
    document.getElementById("repo-name").innerHTML = "[NOT FOUND]";
  }
}

window.onload = getHealth;
