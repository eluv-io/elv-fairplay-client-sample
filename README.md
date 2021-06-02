# elv-fairplay-client-sample
This project contains sample HTML and iOS Swift clients for FairPlay content playback from the Eluvio Content Fabric. These examples are just minimal modifications of Apple's ["FairPlay Streaming Server SDK"](https://developer.apple.com/streaming/fps/). See the commit history or use `diff` to see the Eluvio-specific changes.


# HTML - FairPlay Streaming in Safari
    
This web page uses the HTML Encrypted Media Extensions (EME) support in WebKit to play FairPlay content on iOS and macOS.


# Swift - HLSCatalogWithFPS
    
This Swift application uses the `AVContentKeySession` APIs to play FairPlay content on iOS and tvOS (version 11+). It also demonstrates downloading streams for offline playback using the `AVAggregateAssetDownloadTask` API.
    
## Usage
### Prerequisites
You need to obtain an authorization token, and make an HTTP request for the live content object's offerings (options.json request) for the DRM and HLS URLs.
### Steps
1. Get the example:
```
git clone https://github.com/eluv-io/elv-fairplay-client-sample
git checkout live
```
2. Open the HLSCatalog app in Xcode
3. Set the authorization token in "HLSCatalogWithFPS/Shared/Managers/ContentKeyDelegate.swift":
```
// offerings response: hls-fairplay > properties > license_servers
let drmUrl: String = "https://host-66-220-3-86.contentfabric.io/ks/fps/"
let authToken: String = "ascsj_WZB..."
```
4. Set the playlist_url in "HLSCatalogWithFPS/Shared/Resources/Streams.plist" (use the Xcode editor):
`https://host-76-74-28-235.contentfabric.io/qlibs/ilib41eKdiVQC2LSzofJaqNwa8H3GM2G/q/hq__J5whVReRbLRn1iXYuNNmvd1SnaBC3f6NtF963fsZgp7GYW5pqtcRfEZ1S6dm8WC9RpFkZL4tyQ/rep/playout/default/hls-fairplay/playlist.m3u8?authorization=ascsj_WZB...`
5. Build and Run the app
