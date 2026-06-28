// MAIN world, document_start. Patches the JS surface to match the spoofed UA per
// the engine profile in localStorage __unagentEngine (written by ua-state.js):
// "chromium", "webkit" (desktop Safari) or "gecko" (Firefox). The engine is still
// really WebKit, so this only defeats client-side checks. Absent => no-op.
(function () {
    "use strict";

    var profile;
    try {
        var raw = window.localStorage.getItem("__unagentEngine");
        if (!raw) { return; }
        profile = JSON.parse(raw);
    } catch (error) {
        return;
    }
    var KNOWN = { chromium: 1, webkit: 1, gecko: 1 };
    if (!profile || !KNOWN[profile.engine]) { return; }
    var p = profile;

    // Anti-self-detection: route Function.prototype.toString through a guard so
    // our fakes report "[native code]" even via toString.call(fn).
    var fakes = new WeakSet();
    var realFnToString = Function.prototype.toString;
    function nativeString(name) {
        return "function " + (name || "") + "() { [native code] }";
    }
    function markNative(fn, name) {
        try { Object.defineProperty(fn, "name", { value: name, configurable: true }); } catch (e) {}
        fakes.add(fn);
        return fn;
    }
    var fakeToString = function toString() {
        if (fakes.has(this)) { return nativeString(this.name); }
        return realFnToString.call(this);
    };
    markNative(fakeToString, "toString");
    try {
        Object.defineProperty(Function.prototype, "toString", {
            value: fakeToString, configurable: true, writable: true
        });
    } catch (e) {}

    // Harden ua-override.js's userAgent/appVersion getters under the same guard.
    ["userAgent", "appVersion"].forEach(function (prop) {
        try {
            var desc = Object.getOwnPropertyDescriptor(navigator, prop);
            if (desc && typeof desc.get === "function") { markNative(desc.get, "get " + prop); }
        } catch (e) {}
    });

    var NavProto = (window.Navigator && window.Navigator.prototype)
        || Object.getPrototypeOf(navigator);

    // Accessor on the prototype (where the genuine property lives), native getter.
    function defineGetter(target, prop, getter) {
        markNative(getter, "get " + prop);
        try {
            Object.defineProperty(target, prop, {
                get: getter, configurable: true, enumerable: true
            });
        } catch (e) {}
    }

    // Hide the iOS-only device-class signals a desktop preset shouldn't have.
    // Balanced mode keeps TouchEvent/ontouchstart so touch input still works.
    function flattenDeviceClass() {
        try { delete NavProto.standalone; } catch (e) {}
        try { delete navigator.standalone; } catch (e) {}
        if ("standalone" in navigator) {
            defineGetter(NavProto, "standalone", function () { return undefined; });
        }
        ["orientation", "onorientationchange"].forEach(function (prop) {
            try { delete window[prop]; } catch (e) {}
        });
    }

    // ---- Desktop Safari: engine already matches, just flatten device-class tells ----
    if (p.engine === "webkit") {
        defineGetter(NavProto, "platform", function () { return p.navPlatform; });
        defineGetter(NavProto, "maxTouchPoints", function () { return p.maxTouchPoints; });
        flattenDeviceClass();
        return;
    }

    // ---- Firefox (Gecko): Firefox-only navigator props + device-class flatten ----
    if (p.engine === "gecko") {
        defineGetter(NavProto, "platform", function () { return p.navPlatform; });
        defineGetter(NavProto, "maxTouchPoints", function () { return p.maxTouchPoints; });
        defineGetter(NavProto, "vendor", function () { return ""; });               // Firefox: empty
        defineGetter(NavProto, "productSub", function () { return "20100101"; });    // Firefox value
        defineGetter(NavProto, "oscpu", function () { return p.oscpu; });            // Firefox-only
        defineGetter(NavProto, "buildID", function () { return "20181001000000"; }); // Firefox frozen
        if (!p.mobile) { flattenDeviceClass(); }
        return;
    }

    // ---- navigator scalar surface ----
    defineGetter(NavProto, "vendor", function () { return p.vendor; });               // "Google Inc."
    defineGetter(NavProto, "platform", function () { return p.navPlatform; });        // "Win32" / "MacIntel" / ...
    defineGetter(NavProto, "hardwareConcurrency", function () { return p.hardwareConcurrency; });
    defineGetter(NavProto, "deviceMemory", function () { return p.deviceMemory; });   // absent on WebKit; Chrome has it
    defineGetter(NavProto, "maxTouchPoints", function () { return p.maxTouchPoints; });
    defineGetter(NavProto, "pdfViewerEnabled", function () { return !p.mobile; });

    // ---- navigator.userAgentData (one stable object, fields from the profile) ----
    function cloneBrands(list) {
        return list.map(function (b) { return { brand: b.brand, version: b.version }; });
    }
    var getHighEntropyValues = markNative(function getHighEntropyValues(hints) {
        var full = {
            architecture: p.architecture,
            bitness: p.bitness,
            brands: cloneBrands(p.brands),
            fullVersionList: cloneBrands(p.fullVersionList),
            mobile: !!p.mobile,
            model: p.model,
            platform: p.platform,
            platformVersion: p.platformVersion,
            uaFullVersion: p.uaFullVersion,
            wow64: !!p.wow64
        };
        // Chrome always returns the low-entropy trio plus any requested hints.
        var out = { brands: cloneBrands(p.brands), mobile: !!p.mobile, platform: p.platform };
        (hints || []).forEach(function (hint) {
            if (Object.prototype.hasOwnProperty.call(full, hint)) { out[hint] = full[hint]; }
        });
        return Promise.resolve(out);
    }, "getHighEntropyValues");
    var toJSON = markNative(function toJSON() {
        return { brands: cloneBrands(p.brands), mobile: !!p.mobile, platform: p.platform };
    }, "toJSON");

    var uaData = {};
    Object.defineProperties(uaData, {
        brands: { get: markNative(function () { return cloneBrands(p.brands); }, "get brands"), enumerable: true, configurable: true },
        mobile: { get: markNative(function () { return !!p.mobile; }, "get mobile"), enumerable: true, configurable: true },
        platform: { get: markNative(function () { return p.platform; }, "get platform"), enumerable: true, configurable: true },
        getHighEntropyValues: { value: getHighEntropyValues, enumerable: true, writable: true, configurable: true },
        toJSON: { value: toJSON, enumerable: true, writable: true, configurable: true }
    });
    defineGetter(NavProto, "userAgentData", function () { return uaData; });

    // ---- window.chrome (desktop Chromium only) ----
    if (p.windowChrome) {
        var chromeStub = {
            app: {
                isInstalled: false,
                InstallState: { DISABLED: "disabled", INSTALLED: "installed", NOT_INSTALLED: "not_installed" },
                RunningState: { CANNOT_RUN: "cannot_run", READY_TO_RUN: "ready_to_run", RUNNING: "running" }
            },
            csi: markNative(function csi() {
                return { startE: Date.now(), onloadT: Date.now(), pageT: performance.now(), tran: 15 };
            }, "csi"),
            loadTimes: markNative(function loadTimes() {
                var t = Date.now() / 1000;
                return {
                    requestTime: t, startLoadTime: t, commitLoadTime: t,
                    finishDocumentLoadTime: t, finishLoadTime: t,
                    firstPaintTime: t, firstPaintAfterLoadTime: 0,
                    navigationType: "Other", wasFetchedViaSpdy: true,
                    wasNpnNegotiated: true, npnNegotiatedProtocol: "h2",
                    wasAlternateProtocolAvailable: false, connectionInfo: "h2"
                };
            }, "loadTimes")
            // No chrome.runtime: undefined on real Chrome web pages; faking it is a trap.
        };
        try {
            Object.defineProperty(window, "chrome", {
                value: chromeStub, configurable: true, writable: true, enumerable: true
            });
        } catch (e) {}
    }

    // ---- WebGL ANGLE renderer strings (P1, inert unless profile.webgl is set) ----
    // Swaps only the UNMASKED vendor/renderer strings; pixels still hash as Apple.
    if (p.webgl) {
        var patchGetParameter = function (proto) {
            if (!proto || !proto.getParameter) { return; }
            var real = proto.getParameter;
            var wrapped = markNative(function getParameter(param) {
                if (param === 0x9245) { return p.webgl.vendor; }   // UNMASKED_VENDOR_WEBGL
                if (param === 0x9246) { return p.webgl.renderer; } // UNMASKED_RENDERER_WEBGL
                return real.call(this, param);
            }, "getParameter");
            try { proto.getParameter = wrapped; } catch (e) {}
        };
        patchGetParameter(window.WebGLRenderingContext && window.WebGLRenderingContext.prototype);
        patchGetParameter(window.WebGL2RenderingContext && window.WebGL2RenderingContext.prototype);
    }
})();
