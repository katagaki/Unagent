# Unagent
A Safari extension to modify the user agent per website.

## Why I built this
There isn't currently any user agent changer per website on the App Store, and using a separate browser/app on iOS to do web searches was troublesome. 

Since Safari now supports the web extensions manifest, I decided to port [bing-chat-unblocker-chrome](https://github.com/ellisy0/bing-chat-unblocker-chrome) and build it for iOS and macOS.

Some tweaks have been made to the user agent to ensure compatibility with Safari on iOS and macOS.

## Development

### What works
- Basic user agent selection
- Per site settings
- Custom user agents

## Building

To build Unagent, open the project in Xcode and build it.

Follow the instructions to change the signing identity when necessary.
