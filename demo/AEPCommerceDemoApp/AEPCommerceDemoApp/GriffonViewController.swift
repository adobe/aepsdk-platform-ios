//
// Copyright 2020 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import ACPCore
import ACPGriffon
import Foundation
import UIKit

class GriffonViewController: UIViewController {

    @IBOutlet var griffonSessionURL: UITextField!
    @IBOutlet var appNameLbl: UILabel!

    var isConnected: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        appNameLbl.text = AEPDemoConstants.Strings.appName
    }

    @IBAction func griffonConnectBtn(_ sender: UIButton) {
        if !isConnected {
            guard let griffonURLText = griffonSessionURL.text else {
                return
            }
            if  griffonURLText.contains(AEPDemoConstants.Strings.griffonUrlValidationString) {
                if let url = URL(string: griffonURLText) {
                    isConnected = true
                    ACPGriffon.startSession(url)
                } else {
                    snackbar(message: AEPDemoConstants.Strings.griffonUrlInvalid)
                }
            } else {
                snackbar(message: AEPDemoConstants.Strings.griffonUrlInvalid)
            }
        } else {
            snackbar(message: AEPDemoConstants.Strings.griffonSessonActive)
        }
    }

    @IBAction func griffonDisconnectBtn(_ sender: UIButton) {
        if isConnected {
            ACPGriffon.endSession()
            snackbar(message: AEPDemoConstants.Strings.griffonSessionDisconnected)
            isConnected = false
        } else {
            snackbar(message: AEPDemoConstants.Strings.griffonSessionNotActive)
        }
    }
}
