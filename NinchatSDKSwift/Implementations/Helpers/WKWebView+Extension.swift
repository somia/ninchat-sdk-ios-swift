//
// Copyright (c) 22.5.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation
import WebKit

extension WKWebView {
    func loadHTML(content: String, font: UIFont) {
        let htmlFormattedContent =
        """
        <html>
            <head>
                <meta charset='utf-8'>
                <meta name='viewport' content='viewport-fit=cover width=device-width, initial-scale=0.9, maximum-scale=1.0, user-scalable=no shrink-to-fit=yes'/>
                <style type="text/css">
                    @font-face {
                        font-family: 'SourceSansPro';
                        src: url('\(font.fontName).ttf')  format('truetype')
                    }
                    body {
                        font-family: 'SourceSansPro';
                        font-size: \(font.pointSize)px;
                        font-weight: normal;
                    }
                </style>
            </head>
            <body>
                \(content)
            </body>
        </html>
        """

        self.loadHTMLString(htmlFormattedContent, baseURL: Bundle.SDKBundle!.bundleURL)
    }
}
