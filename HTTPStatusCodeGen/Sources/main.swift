//
//  main.swift
//  HTTPStatusCodeGen
//
//  Created by Yuki Nagai on 7/10/16.
//  Copyright © 2016 Recruit Lifestyle Co., Ltd. All rights reserved.
//

import Foundation
import Kanna

final class StatusCode {
    let code: Int
    let name: String
    var desc: String
    
    init?(_ element: XMLElement) {
        guard element.tagName == "h3" else { return nil }
        let components = Array(
            element.text!.componentsSeparatedByString(" ").map { $0.componentsSeparatedByString("-") }.flatten()
        )
        guard let code = Int(components[1]) else { return nil }
        let name = (components[2..<components.count]).enumerate().map { index, value in
            if index == 0 { return value.lowercaseString }
            return value
        }.joinWithSeparator("")
        guard name != "(unused)" else { return nil }
        self.code = code
        self.name = name
        self.desc = ""
    }
}

let reserved = [
    "continue"
]

func main() {
    let html = Kanna.HTML(
        url: NSBundle.mainBundle().URLForResource("rfc2616-sec10", withExtension: "html")!,
        encoding: NSUTF8StringEncoding)!
    var current: StatusCode?
    var codes = [StatusCode]()
    let elements = Array(html.css("h3, p"))
    for (index, element) in elements.enumerate() {
        if let statusCode = current {
            if let text = element.text where !text.isEmpty {
                if statusCode.desc.isEmpty {
                    statusCode.desc += " "
                } else {
                    statusCode.desc += "\n "
                }
                statusCode.desc += text.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
            }
            if index + 1 < elements.count && elements[index + 1].tagName == "h3" {
                codes.append(statusCode)
                current = nil
            }
        } else {
            current = StatusCode(element)
            continue
        }
    }
    codes.forEach { statusCode in
        print("/**")
        print(statusCode.desc)
        print("*/")
        let name = reserved.contains(statusCode.name) ? "`\(statusCode.name)`" : statusCode.name
        print("case \(name) = \(statusCode.code)")
        print()
    }
}
main()
