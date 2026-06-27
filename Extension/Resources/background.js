const supportedResourceTypes = [
    "main_frame", "sub_frame", "stylesheet", "script", "image",
    "font", "xmlhttprequest", "ping", "media", "websocket", "other"
];

// Report to the native app as soon as the extension runs in Safari, before any
// page is visited and regardless of website-access permission. onInstalled fires
// when the extension is installed, enabled, or updated; onStartup fires when
// Safari launches with the extension enabled. This lets the app's onboarding mark
// "extension enabled" from just opening Safari, instead of waiting for a page
// load with website access (which the content-script path requires).
function reportEnabled() {
    browser.runtime.sendNativeMessage({function: "reportEnabled"}, null);
}
browser.runtime.onInstalled.addListener(reportEnabled);
browser.runtime.onStartup.addListener(reportEnabled);

// Register ua-override.js in the MAIN world. Safari exposes world:"MAIN" only via
// scripting.registerContentScripts, not the manifest content_scripts "world" key.
async function registerUserAgentOverride() {
    try {
        const existing = await browser.scripting.getRegisteredContentScripts({
            ids: ["unagent-ua-override"]
        });
        if (existing.length > 0) {
            return;
        }
        await browser.scripting.registerContentScripts([{
            id: "unagent-ua-override",
            js: ["ua-override.js"],
            // "*://*/*" not "<all_urls>": must stay within granted host_permissions.
            matches: ["*://*/*"],
            runAt: "document_start",
            allFrames: true,
            world: "MAIN"
        }]);
    } catch (error) {
        console.error("Failed to register user-agent override content script", error);
    }
}
browser.runtime.onInstalled.addListener(registerUserAgentOverride);
browser.runtime.onStartup.addListener(registerUserAgentOverride);
// Top-level call covers service-worker wakes, when neither event fires.
registerUserAgentOverride();

browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
    let currentSchemaVersion = 7;

    // This listener is triggered by the content script, which only runs once the
    // user has granted website access. Tell the native app so the main app's
    // onboarding can confirm the extension is fully set up.
    browser.runtime.sendNativeMessage({function: "reportActivation"}, null);

    browser.storage.local.get(["schemaVersion", "userAgent", "siteSettings"], (localStorage) => {
        let storedSchemaVersion = localStorage.schemaVersion;
        if (storedSchemaVersion == null || storedSchemaVersion < currentSchemaVersion) {
            console.log("Resetting all settings after schema version updated");
            resetAllSettings(currentSchemaVersion);
        }

        console.log("Extension asking native app whether it should update");
        browser.runtime.sendNativeMessage({function: "shouldExtensionUpdate"}, function (response) {
            if (response["shouldExtensionUpdate"] === true) {
                console.log("Extension updating settings from app");
                updateSettings();
                console.log("Extension telling native app settings were updated");
                browser.runtime.sendNativeMessage({function: "hasExtensionUpdated"}, null)
            } else {
                console.log("Extension will not update settings from app")
            }
        });
    });
    return true;
});

function resetAllSettings(currentSchemaVersion) {
    browser.declarativeNetRequest.getDynamicRules((rules) => {
        rules.forEach((rule) => {
            browser.declarativeNetRequest.updateDynamicRules({
                removeRuleIds: [rule.id],
            });
        });
    });
    browser.storage.local.set({schemaVersion: currentSchemaVersion});
}

function updateSettings() {
    // Read current state from storage.local (a bare global `localStorage` doesn't
    // exist in the MV3 background context and threw here before any setting applied).
    browser.storage.local.get(["userAgent", "globalViewport", "siteSettings"], function (stored) {
    browser.runtime.sendNativeMessage({function: "getSettings"}, function (response) {
        var hasConfigBeenUpdated = false;
        let currentUserAgent = stored.userAgent;
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
        let currentGlobalViewport = stored.globalViewport;
        if (currentGlobalViewport != null) {
            if ("globalViewport" in response) {
                if (currentGlobalViewport != response["globalViewport"]) {
                    setGlobalViewport(response["globalViewport"]);
                    hasConfigBeenUpdated = true;
                }
            }
        } else {
            if ("globalViewport" in response) {
                setGlobalViewport(response["globalViewport"]);
                hasConfigBeenUpdated = true;
            }
        }
        let currentSiteSettings = stored.siteSettings;
        if (currentSiteSettings != null) {
            if ("siteSettings" in response) {
                var siteSettingsFromNativeApp = JSON.parse(response["siteSettings"]);
                var siteSettingsRequiresUpdate = false;
                currentSiteSettings.forEach((currentSiteSetting) => {
                    if (!containsSiteSetting(currentSiteSetting, siteSettingsFromNativeApp)) {
                        siteSettingsRequiresUpdate = true;
                    }
                });
                siteSettingsFromNativeApp.forEach((siteSettingFromNativeApp) => {
                    if (!containsSiteSetting(siteSettingFromNativeApp, currentSiteSettings)) {
                        siteSettingsRequiresUpdate = true;
                    }
                });
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
        if (hasConfigBeenUpdated) {
            let autoRefreshEnabled = response["autoRefreshEnabled"] === "true";
            if (autoRefreshEnabled) {
                browser.tabs.getCurrent((tab) => {
                    setTimeout(() => {
                        browser.tabs.reload(tab.id);
                    }, 500);
                });
            }
        }
    });
    });
}

function setUserAgent(userAgent) {
    if (userAgent != "") {
        let rule = {
            id: 9999,
            priority: 1,
            condition: {
                urlFilter: "*",
                resourceTypes: supportedResourceTypes
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
        browser.declarativeNetRequest.updateDynamicRules({
            removeRuleIds: [9999]
        });
    }
    browser.storage.local.set({userAgent: userAgent});
}

function setGlobalViewport(viewport) {
    browser.storage.local.set({globalViewport: viewport});
}

function setSiteSettings(siteSettings) {
    var ruleId = 1;
    browser.declarativeNetRequest.getDynamicRules((rules) => {
        rules.forEach((rule) => {
            if (rule.id != 9999) {
                browser.declarativeNetRequest.updateDynamicRules({
                    removeRuleIds: [rule.id],
                });
            }
        });
        for (const siteSetting of siteSettings) {
            let rule = {
                id: ruleId,
                priority: ruleId + 1,
                condition: {
                    urlFilter: "||" + siteSetting.domain,
                    resourceTypes: supportedResourceTypes
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

            if (siteSetting.viewport) {
                setViewportForDomain(siteSetting.domain, siteSetting.viewport);
            }
            
            ruleId += 1;
        }
        browser.storage.local.set({siteSettings: siteSettings});
    });
}

function setViewportForDomain(domain, viewport) {
    browser.storage.local.get(["viewportSettings"], (result) => {
        let allViewportSettings = result.viewportSettings || {};
        allViewportSettings[domain] = viewport;
        browser.storage.local.set({viewportSettings: allViewportSettings});
    });
}

function containsSiteSetting(obj, list) {
    var i;
    for (i = 0; i < list.length; i++) {
        if (list[i].domain == obj.domain &&
            list[i].userAgent == obj.userAgent &&
            list[i].viewport == obj.viewport) {
            return true;
        }
    }
    return false;
}
