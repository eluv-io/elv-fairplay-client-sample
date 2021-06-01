/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 `ContentKeyDelegate` is a class that implements the `AVContentKeySessionDelegate` protocol to respond to content key
 requests using FairPlay Streaming.
 */

import AVFoundation

class ContentKeyDelegate: NSObject, AVContentKeySessionDelegate {
    
    // MARK: Types
    
    enum ProgramError: Error {
        case missingApplicationCertificate
        case noCKCReturnedByKSM
    }
    
    // MARK: Properties
    
    /// The directory that is used to save persistable content keys.
    lazy var contentKeyDirectory: URL = {
        guard let documentPath =
            NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
                fatalError("Unable to determine library URL")
        }
        
        let documentURL = URL(fileURLWithPath: documentPath)
        
        let contentKeyDirectory = documentURL.appendingPathComponent(".keys", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: contentKeyDirectory.path, isDirectory: nil) {
            do {
                try FileManager.default.createDirectory(at: contentKeyDirectory,
                                                    withIntermediateDirectories: false,
                                                    attributes: nil)
            } catch {
                fatalError("Unable to create directory for content keys at path: \(contentKeyDirectory.path)")
            }
        }
        
        return contentKeyDirectory
    }()
    
    /// A set containing the currently pending content key identifiers associated with persistable content key requests that have not been completed.
    var pendingPersistableContentKeyIdentifiers = Set<String>()
    
    /// A dictionary mapping content key identifiers to their associated stream name.
    var contentKeyToStreamNameMap = [String: String]()
    
    func requestApplicationCertificate() throws -> Data {
        print("ContentKeyDelegate.requestApplicationCertificate")
        let cert64: String = "MIIExzCCA6+gAwIBAgIIHyfkXhxLHC4wDQYJKoZIhvcNAQEFBQAwfzELMAkGA1UEBhMCVVMxEzARBgNVBAoMCkFwcGxlIEluYy4xJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MTMwMQYDVQQDDCpBcHBsZSBLZXkgU2VydmljZXMgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMjAwOTEyMDMzMjI0WhcNMjIwOTEzMDMzMjI0WjBgMQswCQYDVQQGEwJVUzETMBEGA1UECgwKRWx1dmlvIEluYzETMBEGA1UECwwKMktIOEtDM01NWDEnMCUGA1UEAwweRmFpclBsYXkgU3RyZWFtaW5nOiBFbHV2aW8gSW5jMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDslbBURB6gj07g7VrS7Ojixe7FNZOupomcZt+mtMvyavjg7X7/T4RccmKUQxOoMLKCJcQ6WrdHhIpN8+bciq7lr0mNzaN467zREiUNYOpkVPi13sJLieY2m2MEPOQTbIl52Cu1YyH+4/g1dKPmeguSnzZRo36jsCGHlJBjHq0jkQIDAQABo4IB6DCCAeQwDAYDVR0TAQH/BAIwADAfBgNVHSMEGDAWgBRj5EdUy4VxWUYsg6zMRDFkZwMsvjCB4gYDVR0gBIHaMIHXMIHUBgkqhkiG92NkBQEwgcYwgcMGCCsGAQUFBwICMIG2DIGzUmVsaWFuY2Ugb24gdGhpcyBjZXJ0aWZpY2F0ZSBieSBhbnkgcGFydHkgYXNzdW1lcyBhY2NlcHRhbmNlIG9mIHRoZSB0aGVuIGFwcGxpY2FibGUgc3RhbmRhcmQgdGVybXMgYW5kIGNvbmRpdGlvbnMgb2YgdXNlLCBjZXJ0aWZpY2F0ZSBwb2xpY3kgYW5kIGNlcnRpZmljYXRpb24gcHJhY3RpY2Ugc3RhdGVtZW50cy4wNQYDVR0fBC4wLDAqoCigJoYkaHR0cDovL2NybC5hcHBsZS5jb20va2V5c2VydmljZXMuY3JsMB0GA1UdDgQWBBR4jerseBHEUDC7mU+NQuIzZqHRFDAOBgNVHQ8BAf8EBAMCBSAwOAYLKoZIhvdjZAYNAQMBAf8EJgFuNnNkbHQ2OXFuc3l6eXp5bWFzdmdudGthbWd2bGE1Y212YzdpMC4GCyqGSIb3Y2QGDQEEAQH/BBwBd252bHhlbGV1Y3Vpb2JyZW4yeHZlZmV6N2Y5MA0GCSqGSIb3DQEBBQUAA4IBAQBM17YYquw0soDPAadr1aIM6iC6BQ/kOGYu3y/6AlrwYgAQNFy8DjsQUoqlQWFuA0sigp57bTUymkXEBf9yhUmXXiPafGjbxzsPF5SPFLIciolWbxRCB153L1a/Vh2wg3rhf4IvAZuJpnml6SSg5SjD19bN+gD7zrtp3yWKBKuarLSjDvVIB1SoxEToBs3glAEqoBiA2eZjikBA0aBlbvjUF2gqOmZjZJ7dmG1Tos2Zd4SdGL6ltSpKUeSGSxyv41aqF83vNpymNJmey2t2kPPtC7mt0LM32Ift3AkAl8Za9JbV/pOnc95oAfPhVTOGOI+u2BuB2qaKWjqHwkfqCz4A"
        let applicationCertificate: Data? = Data(base64Encoded: cert64)
        guard applicationCertificate != nil else {
            throw ProgramError.missingApplicationCertificate
        }
        return applicationCertificate!
    }
    
    // TODO load this from Streams.plist
    //let drmUrl: String = "https://host-209-51-161-245.contentfabric.io/ks/fps/"
    let drmUrl: String = "https://host-66-220-3-86.contentfabric.io/ks/fps/"
    let authToken: String = "ascsj_WZBpFkvBFWafEUkRT5xNvVcm9gg3qQNCdwujNePZ8mEzQ7pWBuLwb26h1h92SHrszifa6v46YQB1KQULo8ydwyPdcycvt3EW5NQAqP4oL5MbnDFxyhH9Y5NFT4dco1ohLr9YrHokrXnZEA1VwZce8hiUJMfJhBi8VTRBtFM4Pp3TYT2nzvSBTRmLxXbS8BxLqzQg9zP4rxScQAhNskP6AZ1RbcxGQqSHX4y1PSn2kCk2a375pvRWmgTL518HjXni7DHQurN1x8TGkTjfU2AqYtqZ5rZZ9Hx6as4oB8JH4itgMjNPuS1bLRZ2NyriP2pBBtR34imUnaTykkmS7L8eNz5xVAGprErXqXsgKk3KbHoh37QofswVVUYYxFQaVfeBPdbuRxTWCrgQz9GS1a3EDrKucqfcFzQkFm4FxkhKYQpmePwSSkmsGCpoWV8RFDNPWgKzXHe2djg7HShbmjXUpfmQNXK11aL6VE5gh2BaTBek1TNWQJ93sQrGNSKFcDZNm1HhRQwLNBCvixJi6du3CquAVxJfzYrRTrM9P73gW34BHQwp17bTJTr1oHKRdPWX9bw8rqKxSjgzZ5gytRb77XFVGJPeG4G9ygMFjEirJ6mCTRStdUXbVCW6vgPzuy5rLm2DEixg24PtYS97NaLfAAotuBvdQHgjypBuu3fSUSxRXDn9fHpT2wdfa3GJJBtZfQUXGgSE1cjL34x2HGYDheE32LNiHdH8xZLYhEH6mYukSkihVaZMjbFjcRBvYxwQzxhf6pAp2AkyRpJgQjJeQxYGAvfkfCuepPgFgKN8gSsdopq3f21nqrHbNoKWGtdpNHYVw8GUUGsUKY6FuFEzxYA1LSUYWGjDHHqZTsL8QnHNg1xoNoZJPi8fAWQ7xKFGMVB4WymSvsak6SLTz7Q4rmoxN3stmEd7vwfzYhzomgvsqq9L6AABAMkeEBv5AtkuA4e93tTLCBHyov3yMhrBXopLVXUV8xJAqhVjQGUrAuqgwx5xKtbTiRbDe8ByFPR5k9bGJVuqU8UjJXg64LXTfkuCeaqFBye4Z2gFJt91H9GHsJz6xq4SCyta3c5c7MZXMhEd8au6PV6Zi38CxtykEfSB2GV8G.RVMyNTZLX0Y4ZEM0d2toZDVtTGZZVnJOQUxzWjhDRVp3TnB2dWZQOTF6a1l3djhwVmhWUFpRUVlhN2k1VURjWk41eEdhQnM4U3lYcDdKRmRpc3RkOGUxdXdlTTlaaHJh"
    func requestContentKeyFromKeySecurityModule(spcData: Data, assetID: String) throws -> Data {
        print("ContentKeyDelegate.requestContentKeyFromKeySecurityModule assetID " + assetID)
        
        var ckcData: Data? = nil
        let semaphore = DispatchSemaphore(value: 0)
        let postString = "{\"spc\":\"\(spcData.base64EncodedString())\",\"assetId\":\"\(assetID)\"}"
        if let postData = postString.data(using: .ascii, allowLossyConversion: true), let drmServerUrl = URL(string: self.drmUrl) {
            var request = URLRequest(url: drmServerUrl)
            request.httpMethod = "POST"
            request.setValue(String(postData.count), forHTTPHeaderField: "Content-Length")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = postData
            
            URLSession.shared.dataTask(with: request) { (data, _, error) in
                if let data = data, var responseString = String(data: data, encoding: .utf8) {
                    responseString = responseString.replacingOccurrences(of: "<ckc>", with: "").replacingOccurrences(of: "</ckc>", with: "")
                    ckcData = Data(base64Encoded: responseString)
                } else {
                    print("Error encountered while fetching FairPlay license for URL: \(self.drmUrl), \(error?.localizedDescription ?? "Unknown error")")
                }
                
                semaphore.signal()
                }.resume()
        } else {
            fatalError("Invalid post data")
        }
        semaphore.wait()
        
        guard ckcData != nil else {
            throw ProgramError.noCKCReturnedByKSM
        }
        return ckcData!
    }

    /// Preloads all the content keys associated with an Asset for persisting on disk.
    ///
    /// It is recommended you use AVContentKeySession to initiate the key loading process
    /// for online keys too. Key loading time can be a significant portion of your playback
    /// startup time because applications normally load keys when they receive an on-demand
    /// key request. You can improve the playback startup experience for your users if you
    /// load keys even before the user has picked something to play. AVContentKeySession allows
    /// you to initiate a key loading process and then use the key request you get to load the
    /// keys independent of the playback session. This is called key preloading. After loading
    /// the keys you can request playback, so during playback you don't have to load any keys,
    /// and the playback decryption can start immediately.
    ///
    /// In this sample use the Streams.plist to specify your own content key identifiers to use
    /// for loading content keys for your media. See the README document for more information.
    ///
    /// - Parameter asset: The `Asset` to preload keys for.
    func requestPersistableContentKeys(forAsset asset: Asset) {
        print("ContentKeyDelegate.requestPersistableContentKeys forAsset " + asset.stream.name)
        for identifier in asset.stream.contentKeyIDList ?? [] {
            
            guard let contentKeyIdentifierURL = URL(string: identifier), let assetIDString = contentKeyIdentifierURL.host else { continue }
            print("assetIDString=" + assetIDString)
            
            pendingPersistableContentKeyIdentifiers.insert(assetIDString)
            contentKeyToStreamNameMap[assetIDString] = asset.stream.name
            
            ContentKeyManager.shared.contentKeySession.processContentKeyRequest(withIdentifier: identifier, initializationData: nil, options: nil)
        }
    }
    
    /// Returns whether or not a content key should be persistable on disk.
    ///
    /// - Parameter identifier: The asset ID associated with the content key request.
    /// - Returns: `true` if the content key request should be persistable, `false` otherwise.
    func shouldRequestPersistableContentKey(withIdentifier identifier: String) -> Bool {
        print("ContentKeyDelegate.shouldRequestPersistableContentKey withIdentifier " + identifier)
        return pendingPersistableContentKeyIdentifiers.contains(identifier)
    }
    
    // MARK: AVContentKeySessionDelegate Methods
    
    /*
     The following delegate callback gets called when the client initiates a key request or AVFoundation
     determines that the content is encrypted based on the playlist the client provided when it requests playback.
     */
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) {
        print("ContentKeyDelegate.contentKeySession didProvide keyRequest")
        handleStreamingContentKeyRequest(keyRequest: keyRequest)
    }
    
    /*
     Provides the receiver with a new content key request representing a renewal of an existing content key.
     Will be invoked by an AVContentKeySession as the result of a call to -renewExpiringResponseDataForContentKeyRequest:.
     */
    func contentKeySession(_ session: AVContentKeySession, didProvideRenewingContentKeyRequest keyRequest: AVContentKeyRequest) {
        print("ContentKeyDelegate.contentKeySession didProvideRenewingContentKeyRequest")
        handleStreamingContentKeyRequest(keyRequest: keyRequest)
    }
    
    /*
     Provides the receiver a content key request that should be retried because a previous content key request failed.
     Will be invoked by an AVContentKeySession when a content key request should be retried. The reason for failure of
     previous content key request is specified. The receiver can decide if it wants to request AVContentKeySession to
     retry this key request based on the reason. If the receiver returns YES, AVContentKeySession would restart the
     key request process. If the receiver returns NO or if it does not implement this delegate method, the content key
     request would fail and AVContentKeySession would let the receiver know through
     -contentKeySession:contentKeyRequest:didFailWithError:.
     */
    func contentKeySession(_ session: AVContentKeySession, shouldRetry keyRequest: AVContentKeyRequest,
                           reason retryReason: AVContentKeyRequest.RetryReason) -> Bool {
        print("ContentKeyDelegate.contentKeySession shouldRetry")
        var shouldRetry = false
        
        switch retryReason {
            /*
             Indicates that the content key request should be retried because the key response was not set soon enough either
             due the initial request/response was taking too long, or a lease was expiring in the meantime.
             */
        case AVContentKeyRequest.RetryReason.timedOut:
            shouldRetry = true
            
            /*
             Indicates that the content key request should be retried because a key response with expired lease was set on the
             previous content key request.
             */
        case AVContentKeyRequest.RetryReason.receivedResponseWithExpiredLease:
            shouldRetry = true
            
            /*
             Indicates that the content key request should be retried because an obsolete key response was set on the previous
             content key request.
             */
        case AVContentKeyRequest.RetryReason.receivedObsoleteContentKey:
            shouldRetry = true
            
        default:
            break
        }
        
        return shouldRetry
    }
    
    // Informs the receiver a content key request has failed.
    func contentKeySession(_ session: AVContentKeySession,
                           contentKeyRequest keyRequest: AVContentKeyRequest,
                           didFailWithError err: Error) {
        print("ContentKeyDelegate.contentKeySession contentKeyRequest \(keyRequest.identifier ?? "?") didFailWithError \(err.localizedDescription)")
    }
    
    func contentKeySession(
        _ session: AVContentKeySession,
        contentKeyRequestDidSucceed keyRequest: AVContentKeyRequest)
    {
        print("ContentKeyDelegate.contentKeySession contentKeyRequestDidSucceed \(keyRequest.identifier ?? "?")")
    }
    
    func contentKeySessionContentProtectionSessionIdentifierDidChange(
        _ session: AVContentKeySession)
    {
        print("ContentKeyDelegate.contentKeySession contentKeySessionContentProtectionSessionIdentifierDidChange \(session.contentProtectionSessionIdentifier ?? Data())")
    }
    
    func contentKeySessionDidGenerateExpiredSessionReport(
        _ session: AVContentKeySession)
    {
        print("ContentKeyDelegate.contentKeySession contentKeySessionDidGenerateExpiredSessionReport")
    }
    
    // MARK: API
    
    func handleStreamingContentKeyRequest(keyRequest: AVContentKeyRequest) {
        guard let contentKeyIdentifierString = keyRequest.identifier as? String,
            let contentKeyIdentifierURL = URL(string: contentKeyIdentifierString),
            let assetIDString = contentKeyIdentifierURL.host,
            let assetIDData = assetIDString.data(using: .utf8)
            else {
                print("Failed to retrieve the assetID from the keyRequest!")
                return
        }
        print("ContentKeyDelegate.handleStreamingContentKeyRequest " + assetIDString)

        let provideOnlinekey: () -> Void = { () -> Void in
            print("ContentKeyDelegate.handleStreamingContentKeyRequest provideOnlinekey")
            do {
                let applicationCertificate = try self.requestApplicationCertificate()

                let completionHandler = { [weak self] (spcData: Data?, error: Error?) in
                    print("ContentKeyDelegate.handleStreamingContentKeyRequest completionHandler")
                    guard let strongSelf = self else { return }
                    if let error = error {
                        keyRequest.processContentKeyResponseError(error)
                        return
                    }

                    guard let spcData = spcData else { return }

                    do {
                        // Send SPC to Key Server and obtain CKC
                        let ckcData = try strongSelf.requestContentKeyFromKeySecurityModule(spcData: spcData, assetID: assetIDString)

                        /*
                         AVContentKeyResponse is used to represent the data returned from the key server when requesting a key for
                         decrypting content.
                         */
                        let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: ckcData)

                        /*
                         Provide the content key response to make protected content available for processing.
                         */
                        keyRequest.processContentKeyResponse(keyResponse)
                    } catch {
                        keyRequest.processContentKeyResponseError(error)
                    }
                }

                keyRequest.makeStreamingContentKeyRequestData(forApp: applicationCertificate,
                                                              contentIdentifier: assetIDData,
                                                              options: [AVContentKeyRequestProtocolVersionsKey: [1]],
                                                              completionHandler: completionHandler)
            } catch {
                keyRequest.processContentKeyResponseError(error)
            }
        }

        #if os(iOS)
            /*
             When you receive an AVContentKeyRequest via -contentKeySession:didProvideContentKeyRequest:
             and you want the resulting key response to produce a key that can persist across multiple
             playback sessions, you must invoke -respondByRequestingPersistableContentKeyRequest on that
             AVContentKeyRequest in order to signal that you want to process an AVPersistableContentKeyRequest
             instead. If the underlying protocol supports persistable content keys, in response your
             delegate will receive an AVPersistableContentKeyRequest via -contentKeySession:didProvidePersistableContentKeyRequest:.
             */
            if shouldRequestPersistableContentKey(withIdentifier: assetIDString) ||
                persistableContentKeyExistsOnDisk(withContentKeyIdentifier: assetIDString) {
                
                // Request a Persistable Key Request.
                do {
                    print("ContentKeyDelegate.handleStreamingContentKeyRequest respondByRequestingPersistableContentKeyRequestAndReturnError")
                    try keyRequest.respondByRequestingPersistableContentKeyRequestAndReturnError()
                } catch {

                    /*
                    This case will occur when the client gets a key loading request from an AirPlay Session.
                    You should answer the key request using an online key from your key server.
                    */
                    provideOnlinekey()
                }
                
                return
            }
        #endif
        
        provideOnlinekey()
    }
}
