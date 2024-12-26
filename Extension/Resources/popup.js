//
//  popup.js
//  Unagent
//
//  Created by シン・ジャスティン on 2024/12/27.
//

document.getElementById("btnResetRules").addEventListener("click", resetAllSettings);

function resetAllSettings() {
    const btnResetRules = document.getElementById("btnResetRules");
    btnResetRules.disabled = true;
    browser.declarativeNetRequest.getDynamicRules((rules) => {
        rules.forEach((rule) => {
            browser.declarativeNetRequest.updateDynamicRules({
                removeRuleIds: [rule.id],
            });
        });
    });
    browser.storage.local.set({ schemaVersion: -1 });
    browser.runtime.sendNativeMessage({ function: "forceExtensionReset" });
    if (btnResetRules) {
        const pRulesHaveBeenReset = document.createElement("p");
        pRulesHaveBeenReset.className = "success";
        pRulesHaveBeenReset.textContent = "Rules have been reset. Close and re-open the Unagent app to set up your rules again.";
        btnResetRules.parentNode.replaceChild(pRulesHaveBeenReset, btnResetRules);
    }
}
