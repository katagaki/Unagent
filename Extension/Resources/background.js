browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
    let currentSchemaVersion = 2;
    var hasConfigBeenUpdated = false;
    browser.storage.local.get("schemaVersion", (results) => {
        let storedSchemaVersion = results.schemaVersion;
        if (storedSchemaVersion == null || storedSchemaVersion < currentSchemaVersion) {
            browser.declarativeNetRequest.getDynamicRules((rules) => {
                rules.forEach((rule) => {
                    browser.declarativeNetRequest.updateDynamicRules({
                    removeRuleIds: [rule.id],
                    });
                });
            });
            browser.storage.local.set({schemaVersion: currentSchemaVersion}, () => {
                console.log("Schema was reset in localStorage.");
            });
        } else {
            console.log("No schema update necessary.");
        }
    });
    browser.runtime.sendNativeMessage({}, function(response) {
        // Check and set global user agent
        browser.storage.local.get("userAgent", (results) => {
            let currentUserAgent = results.userAgent;
            if (currentUserAgent != null) {
                console.log("currentUserAgent exists in localStorage.");
                if (currentUserAgent != response["userAgent"]) {
                    setUserAgent(response["userAgent"]);
                    hasConfigBeenUpdated = true;
                }
            } else {
                console.log("currentUserAgent does not exist in localStorage.");
                setUserAgent(response["userAgent"]);
                hasConfigBeenUpdated = true;
            }
        });
        // Check and set site settings
        browser.storage.local.get("siteSettings", (results) => {
            let currentSiteSettings = results.siteSettings;
            if (currentSiteSettings != null) {
                console.log("currentSiteSettings exists in localStorage.");
                if (JSON.parse(currentSiteSettings) != JSON.parse(response["siteSettings"])) {
                    setSiteSettings(JSON.parse(response["siteSettings"]));
                    hasConfigBeenUpdated = true;
                }
            } else {
                console.log("currentSiteSettings does not exist in localStorage.");
                setSiteSettings(JSON.parse(response["siteSettings"]));
                hasConfigBeenUpdated = true;
            }
        });
    });
    // Reload tab if config was updated
    if (hasConfigBeenUpdated) {
        browser.tabs.query({active: true, currentWindow: true}, (tabs) => {
            console.log("Reloading tab.");
            browser.tabs.reload(tabs[0].id);
        });
    }
    return true;
});

function setUserAgent(userAgent) {
    if (userAgent != "") {
        // Set the global user agent
        let rule = {
            id: 9999,
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
            removeRuleIds: [9999],
            addRules: [rule]
        });
    } else {
        // Remove global user agent
        browser.declarativeNetRequest.updateDynamicRules({
            removeRuleIds: [9999]
        });
    }
    browser.storage.local.set({userAgent: userAgent}, () => {
        console.log("New user agent set in localStorage.");
    });
}

function setSiteSettings(siteSettings) {
    var ruleId = 1;
    // Remove all rules except 9999
    browser.declarativeNetRequest.getDynamicRules((rules) => {
        rules.forEach((rule) => {
            if (rule.id != 9999) {
                browser.declarativeNetRequest.updateDynamicRules({
                removeRuleIds: [rule.id],
                });
            }
        });
    });
    // Create new rules per site setting
    for (const siteSetting of siteSettings) {
        let rule = {
            id: ruleId,
            priority: ruleId + 1,
            condition: {
                urlFilter: "||" + siteSetting.domain,
                resourceTypes: ["main_frame"]
            },
            action: {
                type: "modifyHeaders",
                requestHeaders: [
                    {
                        header: "User-Agent",
                        operation: "set",
                        value: siteSetting.userAgent
                    }
                ]
            }
        };
        browser.declarativeNetRequest.updateDynamicRules({
            addRules: [rule]
        });
        ruleId += 1;
    }
    browser.storage.local.set({siteSettings: siteSettings}, () => {
        console.log("New site settings set in localStorage.");
    });
}
