#!/usr/bin/swift
import Foundation
import Cocoa
import CoreGraphics.CGWindow

let windows : NSArray = CGWindowListCopyWindowInfo(CGWindowListOption.excludeDesktopElements, kCGNullWindowID)! as NSArray

let search_for_app = CommandLine.arguments[1]
let search_for_win = CommandLine.arguments[2]

for window in windows {
    let window = window as! NSDictionary
    
    let app_name = window[kCGWindowOwnerName] as! String
    let window_name = window[kCGWindowName] as? String
    
    if app_name == search_for_app && window_name == search_for_win {
        print("\(window[kCGWindowNumber]!)")
    }
}
