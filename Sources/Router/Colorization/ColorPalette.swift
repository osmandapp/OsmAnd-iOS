//
//  ColorPalette.swift
//  OsmAnd
//
//  Created by Skalii on 26.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class ColorPalette: NSObject {

    @objc
    @objcMembers
    class ColorValue: NSObject {
        let r: Int
        let g: Int
        let b: Int
        let a: Int
        let clr: Int
        var val: Double
        
        override var description: String {
            "ColorValue [r=\(r), g=\(g), b=\(b), a=\(a), val=\(val)]"
        }
        
        init(val: Double, r: Int, g: Int, b: Int, a: Int) {
            self.r = r
            self.g = g
            self.b = b
            self.a = a
            self.clr = ColorPalette.rgbaToDecimal(r: r, g: g, b: b, a: a)
            self.val = val
        }
        
        init(clr: Int) {
            self.r = ColorPalette.red(clr)
            self.g = ColorPalette.green(clr)
            self.b = ColorPalette.blue(clr)
            self.a = ColorPalette.alpha(clr)
            self.clr = clr
            self.val = 0
        }
        
        init(val: Double, clr: Int) {
            self.r = ColorPalette.red(clr)
            self.g = ColorPalette.green(clr)
            self.b = ColorPalette.blue(clr)
            self.a = ColorPalette.alpha(clr)
            self.clr = clr
            self.val = val
        }
        
        static func rgba(val: Double, r: Int, g: Int, b: Int, a: Int) -> ColorValue {
            ColorValue(val: val, r: r, g: g, b: b, a: a)
        }
        
        func setValue(_ val: Double) {
            self.val = val
        }
    }

    static let darkGrey: Int = rgbaToDecimal(r: 92, g: 92, b: 92, a: 255)
    static let lightGrey = rgbaToDecimal(r: 200, g: 200, b: 200, a: 255)
    static let green = rgbaToDecimal(r: 90, g: 220, b: 95, a: 255)
    static let yellow = rgbaToDecimal(r: 212, g: 239, b: 50, a: 255)
    static let red = rgbaToDecimal(r: 243, g: 55, b: 77, a: 255)
    static let blueSlope = rgbaToDecimal(r: 0, g: 0, b: 255, a: 255)
    static let cyanSlope = rgbaToDecimal(r: 0, g: 255, b: 255, a: 255)
    static let greenSlope = rgbaToDecimal(r: 46, g: 185, b: 0, a: 255)
    static let white = rgbaToDecimal(r: 255, g: 255, b: 255, a: 255)
    static let yellowSlope = rgbaToDecimal(r: 255, g: 222, b: 2, a: 255)
    static let redSlope = rgbaToDecimal(r: 255, g: 1, b: 1, a: 255)
    static let purpleSlope = rgbaToDecimal(r: 130, g: 1, b: 255, a: 255)
    
    static let colors: [Int] = [green, yellow, red]
    static let slopeColors: [Int] = [cyanSlope, greenSlope, lightGrey, yellowSlope, redSlope]
    
    static let slopeMinValue: Double = -1.00
    static let slopeMaxValue: Double = 1.0
    
    static let slopePalette = parsePalette([
        [slopeMinValue, Double(blueSlope)],
        [-0.15, Double(cyanSlope)],
        [-0.05, Double(greenSlope)],
        [0.0, Double(lightGrey)],
        [0.05, Double(yellowSlope)],
        [0.15, Double(redSlope)],
        [slopeMaxValue, Double(purpleSlope)]
    ])

    static let minMaxPalette = parsePalette([[0, Double(green)], [0.5, Double(yellow)], [1, Double(red)]])
    
    private(set) var colorValues: [ColorValue] = []
    
    override var description: String {
        writeColorPalette()
    }

    var lastModified: Date?
    
    private override init() {}
    
    init(_ colorPalette: ColorPalette, minVal: Double, maxVal: Double) {
        for cv in colorPalette.colorValues {
            let val = cv.val * (maxVal - minVal) + minVal
            colorValues.append(ColorValue(val: val, clr: cv.clr))
        }
    }
    
    static func rgbaToDecimal(r: Int, g: Int, b: Int, a: Int) -> Int {
        ((a & 0xFF) << 24) | ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF)
    }
    
    static func parsePalette(_ values: [[Double]]) -> ColorPalette {
        let palette = ColorPalette()
        for v in values {
            let c: ColorValue?
            switch v.count {
            case 2:
                c = ColorValue(val: v[0], clr: Int(v[1]))
            case 4:
                c = ColorValue(val: v[0], r: Int(v[1]), g: Int(v[2]), b: Int(v[3]), a: 255)
            case 5...:
                c = ColorValue(val: v[0], r: Int(v[1]), g: Int(v[2]), b: Int(v[3]), a: Int(v[4]))
            default:
                c = nil
            }
            if let c = c {
                palette.colorValues.append(c)
            }
        }
        palette.sortPalette()
        return palette
    }
    
    static func parseColorPalette(from filePath: String) throws -> ColorPalette {
        return try parseColorPalette(from: filePath, shouldSort: true)
    }

    static func parseColorPalette(from filePath: String, shouldSort: Bool) throws -> ColorPalette {
        let palette = ColorPalette()
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
            palette.lastModified = attributes[.modificationDate] as? Date
        }
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.starts(with: "#") {
                continue
            }
            let values = t.split(separator: ",").map { String($0) }
            if values.count >= 4 {
                if let val = Double(values[0]),
                   let r = Int(values[1]),
                   let g = Int(values[2]),
                   let b = Int(values[3]) {
                    let a = values.count >= 5 ? Int(values[4]) ?? 255 : 255
                    let rgba = ColorValue.rgba(val: val, r: r, g: g, b: b, a: a)
                    palette.colorValues.append(rgba)
                }
            }
        }
        if shouldSort {
            palette.sortPalette()
        }
        return palette
    }
    
    static func getTransparentColor() -> Int {
        rgbaToDecimal(r: 0, g: 0, b: 0, a: 0)
    }
    
    static func getIntermediateColor(min: Int, max: Int, percent: Double) -> Int {
        let r = Double(red(min)) + percent * Double(red(max) - red(min))
        let g = Double(green(min)) + percent * Double(green(max) - green(min))
        let b = Double(blue(min)) + percent * Double(blue(max) - blue(min))
        let a = Double(alpha(min)) + percent * Double(alpha(max) - alpha(min))
        return rgbaToDecimal(r: Int(r), g: Int(g), b: Int(b), a: Int(a))
    }
    
    static func writeColorPalette(colors: [ColorValue]) -> String {
        var bld = ""
        for v in colors {
            bld += "\(v.val),\(v.r),\(v.g),\(v.b),\(v.a)\n"
        }
        return bld.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func red(_ value: Int) -> Int {
        (value >> 16) & 0xFF
    }
    
    private static func green(_ value: Int) -> Int {
        (value >> 8) & 0xFF
    }
    
    private static func blue(_ value: Int) -> Int {
        value & 0xFF
    }
    
    private static func alpha(_ value: Int) -> Int {
        (value >> 24) & 0xFF
    }
    
    func getColorByValue(_ value: Double) -> Int {
        if value.isNaN {
            return Self.lightGrey
        }
        for i in 0..<colorValues.count - 1 {
            let min = colorValues[i]
            let max = colorValues[i + 1]
            if value == min.val {
                return min.clr
            }
            if value >= min.val && value <= max.val {
                let percent = (value - min.val) / (max.val - min.val)
                return getIntermediateColor(min: min, max: max, percent: percent)
            }
        }
        if value <= colorValues[0].val {
            return colorValues[0].clr
        } else if value >= colorValues[colorValues.count - 1].val {
            return colorValues[colorValues.count - 1].clr
        }
        return Self.getTransparentColor()
    }
    
    func writeColorPalette() -> String {
        Self.writeColorPalette(colors: colorValues)
    }

    private func getIntermediateColor(min: ColorValue, max: ColorValue, percent: Double) -> Int {
        let r = Double(min.r) + percent * Double(max.r - min.r)
        let g = Double(min.g) + percent * Double(max.g - min.g)
        let b = Double(min.b) + percent * Double(max.b - min.b)
        let a = Double(min.a) + percent * Double(max.a - min.a)
        return Self.rgbaToDecimal(r: Int(r), g: Int(g), b: Int(b), a: Int(a))
    }

    private func sortPalette() {
        colorValues.sort { $0.val < $1.val }
    }
}
