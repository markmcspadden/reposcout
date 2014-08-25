// Copyright (c) 2014 Mark McSpadden.

// Global accessor that the popup uses.
var repos = {};
var selectedRepo = null;

var repoDetails = {};
var selectedRepoDetails = null;

var selectedId = null;


function fetchRepoHealthData(repo, tabId) {
  console.log('Fetch Repo Health');

  var url = 'http://reposcout.com/' + repo + '/health';
  var request = new XMLHttpRequest();

  request.open('GET', url, true);
  console.log(url);
  request.onreadystatechange = function (e) {
    console.log(request, e);
    if (request.readyState == 4) {
      if (request.status == 200) {
        var json = JSON.parse(request.responseText);

        console.log("JSON RESPONSE", json);

        repoDetails[repo] = json;
        selectedRepoDetails = repoDetails[repo];

        updateIcon(tabId, repo);
      } else {
        console.log('Unable to fetch health');
      }
    }
  };
  request.send(null);
}

function updateIcon(tabId, repo) {
  var iconPath;
  if(selectedRepoDetails) {
    console.log("THERE IS A SELECTED REPO FOR IMAGE", selectedRepoDetails);
    if(selectedRepoDetails["overall_health"] === "Great") {
      iconPath = "images/Great.png"
    }
    else if(selectedRepoDetails["overall_health"] === "Good") {
      iconPath = "images/Good.png"
    }
    else if(selectedRepoDetails["overall_health"] === "Meh") {
      iconPath = "images/Meh.png";
    }
    else if(selectedRepoDetails["overall_health"] === "Sad") {
      iconPath = "images/Sad.png";
    }
    else {
      iconPath = "images/Unknown.png"
    }    
  }

  chrome.pageAction.setIcon({"tabId":tabId,"path":iconPath}, function() {
    console.log("I set the icon?");
  });
}

function updateRepo(tabId) {
  console.log("UPDATING REPO");
  chrome.tabs.sendRequest(tabId, {}, function(repo) {
    repos[tabId] = repo;
    if (!repo) {
      chrome.pageAction.hide(tabId);
    } else {
      chrome.pageAction.show(tabId);
      //if (selectedId == tabId) {        
        updateSelected(tabId);
      //}
    }
  });
}

function updateSelected(tabId) {
  selectedRepo = repos[tabId];
  if (selectedRepo) {
    //updateAllTheThings(tabId, selectedRepo);
    fetchRepoHealthData(selectedRepo, tabId);
    selectedRepoDetails = repoDetails[selectedRepo];

    updateIcon(tabId, selectedRepo);
    
    chrome.pageAction.setTitle({tabId:tabId, title:selectedRepo});
  }
}

chrome.tabs.onUpdated.addListener(function(tabId, change, tab) {
  if (change.status == "complete") {
    updateRepo(tabId);
  }
});

chrome.tabs.onSelectionChanged.addListener(function(tabId, info) {
  selectedId = tabId;
  updateSelected(tabId);
});

// Ensure the current selected tab is set up.
chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
  if(tabs[0]) {
    updateRepo(tabs[0].id);  
  }
});
