#!/usr/bin/swift
//  main.swift
//  nscolor
//
//  Created by Fabrizio FD. Destro on 28/12/18.
//  Copyright © 2018 Fabrizio FD. Destro. All rights reserved.
//

import Foundation
import AppKit

func hex(color: NSColor) -> String {
    return String(format: "#%02x%02x%02x", Int(color.redComponent * 0xFF), Int(color.greenComponent * 0xFF), Int(color.blueComponent * 0xFF))
}

func process_color(field: String, data: Data) {
    let color = NSKeyedUnarchiver.unarchiveObject(with: data) as! NSColor
    print("\(field) \(hex(color: color))");
}

func generate_conf_line(field: String, key: String, dictionary: NSDictionary){
    if let data = dictionary[key] {
        process_color(field: field, data: data as! Data)
    }
}

func process(filename: String) {
    let plist = NSDictionary(contentsOfFile: filename)!
    
    generate_conf_line(field: "background", key: "BackgroundColor", dictionary: plist)
    generate_conf_line(field: "foreground", key: "TextColor", dictionary: plist)
    generate_conf_line(field: "cursor", key: "CursorColor", dictionary: plist)
    generate_conf_line(field: "selection_background", key: "SelectionColor", dictionary: plist)
    generate_conf_line(field: "color0", key: "ANSIBlackColor", dictionary: plist)
    generate_conf_line(field: "color8", key: "ANSIBrightBlackColor", dictionary: plist)
    generate_conf_line(field: "color1", key: "ANSIRedColor", dictionary: plist)
    generate_conf_line(field: "color9", key: "ANSIBrightRedColor", dictionary: plist)
    generate_conf_line(field: "color2", key: "ANSIGreenColor", dictionary: plist)
    generate_conf_line(field: "color10", key: "ANSIBrightGreenColor", dictionary: plist)
    generate_conf_line(field: "color3", key: "ANSIYellowColor", dictionary: plist)
    generate_conf_line(field: "color11", key: "ANSIBrightYellowColor", dictionary: plist)
    generate_conf_line(field: "color4", key: "ANSIBlueColor", dictionary: plist)
    generate_conf_line(field: "color12", key: "ANSIBrightBlueColor", dictionary: plist)
    generate_conf_line(field: "color5", key: "ANSIMagentaColor", dictionary: plist)
    generate_conf_line(field: "color13", key: "ANSIBrightMagentaColor", dictionary: plist)
    generate_conf_line(field: "color6", key: "ANSICyanColor", dictionary: plist)
    generate_conf_line(field: "color14", key: "ANSIBrightCyanColor", dictionary: plist)
    generate_conf_line(field: "color7", key: "ANSIWhiteColor", dictionary: plist)
    generate_conf_line(field: "color15", key: "ANSIBrightWhiteColor", dictionary: plist)
}

if (CommandLine.argc == 2) {
    let filename = CommandLine.arguments[1]
    process(filename: filename)
} else {
    print("Missing plist's path.")
}
