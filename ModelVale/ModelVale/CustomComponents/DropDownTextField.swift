//
//  DropDownTextField.swift
//  ModelVale
//
//  Created by Chaytan Inman on 7/17/22.
//

import UIKit
import iOSDropDown

// Source: https://github.com/jriosdev/iOSDropDown
@objc class DropDownTextField: DropDown {

    @objc func initProperties(options: [String]) {
        self.optionArray = options
        self.isSearchEnable = true
        self.didSelect{(selectedText , index ,id) in
            print("Selected String: \(selectedText) \n index: \(index)")
        }
    }
    
    @objc func wasTapped() {
        self.showList();
    }
    
    @objc func labelChanged(allData: [ModelData]) {
        self.didSelect{(selectedText , index ,id) in
            for d in allData {
                d.label = selectedText
            }
        }
    }


}
