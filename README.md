# BingMeUp
A Safari extension to modify the user agent per website.

Currently working on Bing to bypass the Microsoft Edge user agent check.

## Why I built this
There isn't currently any user agent changer per website on the App Store, and using a separate browser/app on iOS to do web searches was troublesome. 

Since Safari now supports the web extensions manifest, I decided to port [bing-chat-unblocker-chrome](https://github.com/ellisy0/bing-chat-unblocker-chrome) and build it for iOS and macOS.

Some tweaks have been made to the user agent to ensure compatibility with Safari on iOS and macOS.

## Development

### What works
- Bing Chat!

### What's planned
- Extending support for other websites
- Allowing arbitrary websites/user agents to be added/removed

## Building

To build BingMeUp, open the project in Xcode and build it.

Follow the instructions to change the signing identity when necessary.
