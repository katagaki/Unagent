browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
    let currentSchemaVersion = 3;
    browser.storage.local.get(["schemaVersion", "userAgent", "siteSettings"], (localStorage) => {
        let storedSchemaVersion = localStorage.schemaVersion;
        if (storedSchemaVersion == null || storedSchemaVersion < currentSchemaVersion) {
            browser.declarativeNetRequest.getDynamicRules((rules) => {
                rules.forEach((rule) => {
                    browser.declarativeNetRequest.updateDynamicRules({
                    removeRuleIds: [rule.id],
                    });
                });
            });
            browser.storage.local.set({schemaVersion: currentSchemaVersion});
        }
        browser.runtime.sendNativeMessage({}, function(response) {
            var hasConfigBeenUpdated = false;
            // Check and set global user agent
            let currentUserAgent = localStorage.userAgent;
            if (currentUserAgent != null) {
                if ("userAgent" in response) {
                    if (currentUserAgent != response["userAgent"]) {
                        setUserAgent(response["userAgent"]);
                        hasConfigBeenUpdated = true;
                    }
                }
            } else {
                if ("userAgent" in response) {
                    setUserAgent(response["userAgent"]);
                    hasConfigBeenUpdated = true;
                }
            }
            // Check and set site settings
            let currentSiteSettings = localStorage.siteSettings;
            if (currentSiteSettings != null) {
                if ("siteSettings" in response) {
                    var siteSettingsFromNativeApp = JSON.parse(response["siteSettings"]);
                    var siteSettingsRequiresUpdate = false;
                    // Check for new site settings
                    currentSiteSettings.forEach((currentSiteSetting) => {
                        if (!containsSiteSetting(currentSiteSetting, siteSettingsFromNativeApp)) {
                            siteSettingsRequiresUpdate = true;
                        }
                    });
                    // Check for deleted site settings
                    siteSettingsFromNativeApp.forEach((siteSettingFromNativeApp) => {
                        if (!containsSiteSetting(siteSettingFromNativeApp, currentSiteSettings)) {
                            siteSettingsRequiresUpdate = true;
                        }
                    });
                    // Update the entire site settings object if anything requires an update
                    if (siteSettingsRequiresUpdate) {
                        if (currentSiteSettings != JSON.parse(response["siteSettings"])) {
                            setSiteSettings(JSON.parse(response["siteSettings"]));
                            hasConfigBeenUpdated = true;
                        }
                    }
                }
            } else {
                if ("siteSettings" in response) {
                    setSiteSettings(JSON.parse(response["siteSettings"]));
                    hasConfigBeenUpdated = true;
                }
            }
            // Reload tab if config was updated
            if (hasConfigBeenUpdated) {
                browser.tabs.getCurrent((tab) => {
                    setTimeout(() => {
                        browser.tabs.reload(tab.id);
                    }, 500);
                });
            }
        });
    });
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
            resourceTypes: [
                                    "main_frame", "sub_frame", "stylesheet", "script", "image",
                                    "object", "xmlhttprequest", "ping", "csp_report", "media",
                                    "websocket", "other"
                                ]
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
    browser.storage.local.set({userAgent: userAgent});
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
        // Create new rules per site setting
        for (const siteSetting of siteSettings) {
            let rule = {
                id: ruleId,
                priority: ruleId + 1,
                condition: {
                    urlFilter: "||" + siteSetting.domain,
                resourceTypes: [
                                    "main_frame", "sub_frame", "stylesheet", "script", "image",
                                    "object", "xmlhttprequest", "ping", "csp_report", "media",
                                    "websocket", "other"
                                ]
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
        browser.storage.local.set({siteSettings: siteSettings});
    });
}

function containsSiteSetting(obj, list) {
    var i;
    for (i = 0; i < list.length; i++) {
        if (list[i].domain == obj.domain &&
            list[i].userAgent == obj.userAgent) {
            return true;
        }
    }
    return false;
}
