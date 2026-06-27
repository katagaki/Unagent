// MAIN world, document_start (Safari only exposes world:"MAIN" via
// scripting.registerContentScripts). Redefines navigator.userAgent to the value
// ua-state.js bridges in on the data-unagent-ua attribute, read lazily each access.
(function () {
    const ATTR = "data-unagent-ua";
    const realUserAgent = navigator.userAgent;
    const realAppVersion = navigator.appVersion;

    function overrideValue() {
        return document.documentElement.getAttribute(ATTR);
    }

    try {
        Object.defineProperty(navigator, "userAgent", {
            configurable: true,
            get: function () {
                return overrideValue() || realUserAgent;
            }
        });
        // appVersion is the UA minus the leading "Mozilla/"; keep them consistent.
        Object.defineProperty(navigator, "appVersion", {
            configurable: true,
            get: function () {
                const ua = overrideValue();
                return ua ? ua.replace(/^Mozilla\//, "") : realAppVersion;
            }
        });
    } catch (error) {}
})();
