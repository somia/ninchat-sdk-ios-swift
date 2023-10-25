//
//  JitsiVideoWebView.swift
//  AnyCodable-FlightSchool
//
//  Created by Andrei Sadovnicov on 11.10.2023.
//

import UIKit
import WebKit

protocol JitsiVideoWebViewEventsDelegate: AnyObject {
    func readyToClose()
}

class JitsiVideoWebView: UIView {

    // MARK: - PROPERTIES
    
    // MARK: - Web view
    private var webView: WKWebView!
    
    // MARK: - Delegate
    var eventsDelegate: JitsiVideoWebViewEventsDelegate?
    
    // MARK: - Debug mode
    private var isDebugMode = false
    
    // MARK: - INITIALIZERS
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.addWebView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = .clear
        self.addWebView()
    }
}

// MARK: - WKWebView setup
extension JitsiVideoWebView {
    private func addWebView() {
        // Initialize WKWebView with configuration
        let webConfig = WKWebViewConfiguration()
        webConfig.allowsInlineMediaPlayback = true
        webConfig.mediaTypesRequiringUserActionForPlayback = []
        if #available(iOS 13.0, *) {
            webConfig.defaultWebpagePreferences.preferredContentMode = .mobile // this setting is necessary for iPad
        }
        // webConfig.preferences.setValue(true, forKey: "developerExtrasEnabled") // uncomment this if you want to debug using the web inspector
        
        // Enable JavaScript messaging
        let contentController = WKUserContentController()
        contentController.add(self, name: "videoConferenceJoined")
        contentController.add(self, name: "videoConferenceLeft")
        webConfig.userContentController = contentController
        
        self.webView = WKWebView(frame: .zero, configuration: webConfig)
        
        // Use black background for the web view while it loads Jitsy video
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        
        // Set a custom non-iPhone user agent, otherwise Jitsi might not load
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"
        
        // Set navigation delegate
        webView.navigationDelegate = self
        
        // Add web view
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: self.topAnchor),
            webView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
}

// MARK: - Loading Jitsi
extension JitsiVideoWebView {
    func loadJitsiMeeting(for urlRequest: URLRequest) {
        if isDebugMode {
            let htmlContent = getJitsiVideoWebViewHtml(for: urlRequest)
            webView.loadHTMLString(htmlContent, baseURL: nil)
        } else {
            webView.load(urlRequest)
        }
    }
}

// MARK: - Finishing a Jitsi meeting
extension JitsiVideoWebView {
    func hangUp() {
        webView.evaluateJavaScript("hangUpConference();")
    }
}

// MARK: - WKNavigationDelegate
extension JitsiVideoWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // debugger("WebView error: \(error.localizedDescription)")
    }
}

// MARK: - WKScriptMessageHandler
extension JitsiVideoWebView: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "videoConferenceLeft":
            eventsDelegate?.readyToClose()
        default:
            break
        }
    }
}

// MARK: - Debugging
extension JitsiVideoWebView {
    func getJitsiVideoWebViewHtml(for urlRequest: URLRequest) -> String {
        let url = urlRequest.url!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let domain = components.queryItems?.first(where: { $0.name == "domain" })?.value ?? ""
        let roomName = components.queryItems?.first(where: { $0.name == "roomName" })?.value ?? ""
        let jwt = components.queryItems?.first(where: { $0.name == "jwt" })?.value ?? ""
        let lang = components.queryItems?.first(where: { $0.name == "lang" })?.value ?? "en"
        
        let htmlContent = """
        <!DOCTYPE html>
        <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <script src="https://jitsi-www.ninchat.com/libs/external_api.min.js"></script>
            </head>
            <body style="margin: 0;">
                <div id="jitsi-meet" style="height: 100vh; overflow-y: hidden;"></div>
                <script>
                    const domain = '\(domain)';
                    const roomName = '\(roomName)';
                    const jwt = '\(jwt)';
                    const lang = '\(lang)';

                    const options = {
                        roomName: roomName,
                        jwt: jwt,
                        lang: lang,
                        width: '100%',
                        height: '100%',
                        parentNode: document.querySelector("#jitsi-meet"),
                        configOverwrite: {
                            "prejoinConfig.enabled": true,
                            "disableInviteFunctions": true,
                            "disableThirdPartyRequests": true,
                            "startWithVideoMuted": false,
                            "disableAudioLevels": true,
                            "disableRemoteMute": false,
                            "startWithAudioMuted": false,
                            "startSilent": false
                        },
                        interfaceConfigOverwrite: {
                            // Add any interface config options here
                        }
                    };

                    var api = new JitsiMeetExternalAPI(domain, options);

                    // Add event listeners
                    api.addEventListener('videoConferenceJoined', function(event) {
                        window.webkit.messageHandlers.videoConferenceJoined.postMessage(event);
                    });

                    api.addEventListener('videoConferenceLeft', function(event) {
                        window.webkit.messageHandlers.videoConferenceLeft.postMessage(event);
                    });

                    // Function to hang up the conference
                    function hangUpConference() {
                        api.executeCommand('hangup');
                    }
                </script>
            </body>
        </html>
        """
        
        return htmlContent
    }
}
