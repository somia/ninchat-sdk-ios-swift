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
                <meta charset='utf-16'>
                <style type="text/css">
                    @font-face {
                        font-family: 'SourceSansPro';
                        src: url('\(font.fontName).ttf')  format('truetype')
                    }
                    h1 {
                        font-family: 'SourceSansPro';
                        font-size: \(font.pointSize)px;
                        font-weight: normal;
                    }
                </style>
                <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'/>
            </head>
            <body>
                <h1>\(content)</h1>
            </body>
        </html>
        """

        self.loadHTMLString(htmlFormattedContent, baseURL: Bundle.SDKBundle!.bundleURL)
    }
}