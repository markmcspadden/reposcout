// Copyright (c) 2014 Mark McSpadden.

// The background page is asking us to find the repo on the page.
if (window == top) {
  chrome.extension.onRequest.addListener(function(req, sender, sendResponse) {
    sendResponse(findRepo());
  });
}

// Get the owner and repo name
// TODO: HANDLE ERRORS!
var findRepo = function() {
  console.log("Window Location", window.location);

  var pathParts = window.location.pathname.split("/");
  var owner = pathParts[1];
  var repo_name = pathParts[2];
  var repo = owner + "/" + repo_name;

  console.log("Repo", repo);

  if(owner && repo_name) {
    return repo;  
  }
  else {
    return null;
  }
  
}
