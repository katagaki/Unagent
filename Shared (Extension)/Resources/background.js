browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
    browser.runtime.sendNativeMessage({}, function(response) {
        if (response["userAgent"] != "Don'tChange") {
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
                            value: response["userAgent"]
                        }
                    ]
                }
            };
            
            console.log(response);
            browser.declarativeNetRequest.updateDynamicRules({
                removeRuleIds: [1],
                addRules: [rule]
            })
        } else {
            browser.declarativeNetRequest.updateDynamicRules({
                removeRuleIds: [1]
            })
        }
    });
    return true;
});
