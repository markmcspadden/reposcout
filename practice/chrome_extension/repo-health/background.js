// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Global accessor that the popup uses.
var repos = {};
var selectedRepo = null;
var selectedId = null;

function updateIcon(tabId, repo) {
  var iconPath;
  if(repo === "technoweenie/attachment_fu") {
    iconPath = "marker-upsidedown.png"
  }
  else {
    iconPath = "marker.png";
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
      // TODO: I think I don't _really_ need this here, but I'm not sure
      updateIcon(tabId, repo);
      chrome.pageAction.show(tabId);
      if (selectedId == tabId) {        
        updateSelected(tabId);
      }
    }
  });
}

function updateSelected(tabId) {
  selectedRepo = repos[tabId];
  if (selectedRepo) {
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
  updateRepo(tabs[0].id);
});


// var addresses = {};
// var selectedAddress = null;
// var selectedId = null;

// function updateAddress(tabId) {
//   chrome.tabs.sendRequest(tabId, {}, function(address) {
//     addresses[tabId] = address;
//     if (!address) {
//       chrome.pageAction.hide(tabId);
//     } else {
//       chrome.pageAction.show(tabId);
//       if (selectedId == tabId) {
//         updateSelected(tabId);
//       }
//     }
//   });
// }

// function updateSelected(tabId) {
//   selectedAddress = addresses[tabId];
//   if (selectedAddress)
//     chrome.pageAction.setTitle({tabId:tabId, title:selectedAddress});
// }

// chrome.tabs.onUpdated.addListener(function(tabId, change, tab) {
//   if (change.status == "complete") {
//     updateAddress(tabId);
//   }
// });

// chrome.tabs.onSelectionChanged.addListener(function(tabId, info) {
//   selectedId = tabId;
//   updateSelected(tabId);
// });

// // Ensure the current selected tab is set up.
// chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
//   updateAddress(tabs[0].id);
// });