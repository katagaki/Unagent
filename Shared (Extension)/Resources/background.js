browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
    browser.storage.local.get("userAgent", (results) => {
        let currentUserAgent = results.userAgent;
        if (currentUserAgent != null) {
            console.log("currentUserAgent exists in localStorage.");
            browser.runtime.sendNativeMessage({}, function(response) {
                if (currentUserAgent != response["userAgent"]) {
                    setUserAgent(response["userAgent"]);
                }
            });
        } else {
            console.log("currentUserAgent does not exist in localStorage.");
            browser.runtime.sendNativeMessage({}, function(response) {
                setUserAgent(response["userAgent"]);
            });
        }
    });
    return true;
});

function setUserAgent(userAgent) {
    if (userAgent != "Don'tChange") {
        var rule = {
            id: 1,
            priority: 1,
            condition: {
                urlFilter: "*",
                resourceTypes: ["main_frame"]
            },
            action: {
                type: "modifyHeaders",
                requestHeaders: [
                    {
                        header: "User-Agent",
                        operation: "set",
                        value: userAgent
                    }
                ]
            }
        };
        browser.declarativeNetRequest.updateDynamicRules({
            removeRuleIds: [1],
            addRules: [rule]
        });
    } else {
        browser.declarativeNetRequest.updateDynamicRules({
            removeRuleIds: [1]
        });
    }
    browser.storage.local.set({userAgent: userAgent}, () => {
        console.log("New user agent set in localStorage.");
    });
    reloadTab();
    return;
}

function reloadTab() {
    browser.tabs.query({active: true, currentWindow: true}, (tabs) => {
        console.log("Reloading tab.");
        browser.tabs.reload(tabs[0].id);
    });
}
