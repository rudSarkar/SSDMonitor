#!/usr/bin/swift
// Generates SSDMonitor.icns + individual PNG slices into AppIcon.appiconset
// Run from repo root:  swift scripts/make_icon.swift

import AppKit
import CoreGraphics

let outputDir = "SSDMonitor/Resources/Assets.xcassets/AppIcon.appiconset"

// All pixel sizes we need to produce
let slices: [(name: String, px: Int)] = [
    ("icon_16x16",       16),
    ("icon_16x16@2x",    32),
    ("icon_32x32",       32),
    ("icon_32x32@2x",    64),
    ("icon_128x128",    128),
    ("icon_128x128@2x", 256),
    ("icon_256x256",    256),
    ("icon_256x256@2x", 512),
    ("icon_512x512",    512),
    ("icon_512x512@2x",1024),
]

func makeIcon(size: Int) -> NSImage {
    let s  = CGFloat(size)
    let r  = s * 0.225          // corner radius (macOS icon squircle)
    let img = NSImage(size: NSSize(width: s, height: s))

    img.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        img.unlockFocus(); return img
    }

    // ── Background: deep navy → slate gradient ────────────────────────────
    let bgPath = CGMutablePath()
    bgPath.addRoundedRect(in: CGRect(x: 0, y: 0, width: s, height: s),
                          cornerWidth: r, cornerHeight: r)
    ctx.addPath(bgPath)
    ctx.clip()

    let colors  = [CGColor(red: 0.09, green: 0.11, blue: 0.18, alpha: 1),
                   CGColor(red: 0.04, green: 0.07, blue: 0.14, alpha: 1)] as CFArray
    let locs: [CGFloat] = [0, 1]
    if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                             colors: colors, locations: locs) {
        ctx.drawLinearGradient(grad,
                               start: CGPoint(x: s/2, y: s),
                               end:   CGPoint(x: s/2, y: 0),
                               options: [])
    }

    // ── Chip body ─────────────────────────────────────────────────────────
    let chipW  = s * 0.55
    let chipH  = s * 0.48
    let chipX  = (s - chipW) / 2
    let chipY  = s * 0.30
    let chipR  = s * 0.06

    // outer glow
    ctx.setShadow(offset: .zero, blur: s * 0.08,
                  color: CGColor(red: 0.20, green: 0.55, blue: 1.0, alpha: 0.45))
    let chipPath = CGMutablePath()
    chipPath.addRoundedRect(in: CGRect(x: chipX, y: chipY, width: chipW, height: chipH),
                            cornerWidth: chipR, cornerHeight: chipR)
    ctx.setFillColor(CGColor(red: 0.14, green: 0.17, blue: 0.26, alpha: 1))
    ctx.addPath(chipPath)
    ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)   // reset shadow

    // chip border
    ctx.setStrokeColor(CGColor(red: 0.25, green: 0.50, blue: 0.90, alpha: 0.60))
    ctx.setLineWidth(s * 0.012)
    ctx.addPath(chipPath)
    ctx.strokePath()

    // ── Circuit traces (decorative horizontal lines inside chip) ──────────
    ctx.setStrokeColor(CGColor(red: 0.20, green: 0.45, blue: 0.80, alpha: 0.25))
    ctx.setLineWidth(s * 0.008)
    let lineCount = 4
    for i in 0..<lineCount {
        let ly = chipY + chipH * (0.22 + CGFloat(i) * 0.18)
        let lx1 = chipX + chipW * 0.12
        let lx2 = chipX + chipW * 0.88
        ctx.move(to: CGPoint(x: lx1, y: ly))
        ctx.addLine(to: CGPoint(x: lx2, y: ly))
    }
    ctx.strokePath()

    // ── Thermometer bulb (bottom-center of chip) ──────────────────────────
    let thW  = s * 0.038
    let thH  = s * 0.20
    let thX  = s / 2 - thW / 2
    let thY  = chipY + chipH * 0.10
    let bulbR = s * 0.055

    // stem
    let stemPath = CGMutablePath()
    stemPath.addRoundedRect(in: CGRect(x: thX, y: thY + bulbR, width: thW, height: thH),
                            cornerWidth: thW/2, cornerHeight: thW/2)
    ctx.setFillColor(CGColor(red: 0.12, green: 0.15, blue: 0.23, alpha: 1))
    ctx.addPath(stemPath)
    ctx.fillPath()
    ctx.setStrokeColor(CGColor(red: 0.30, green: 0.60, blue: 1.0, alpha: 0.70))
    ctx.setLineWidth(s * 0.010)
    ctx.addPath(stemPath)
    ctx.strokePath()

    // mercury fill (~70% full → warm orange)
    let fillH = thH * 0.65
    let mercPath = CGMutablePath()
    mercPath.addRoundedRect(in: CGRect(x: thX + s*0.006,
                                       y: thY + bulbR + (thH - fillH),
                                       width: thW - s*0.012,
                                       height: fillH),
                            cornerWidth: (thW - s*0.012)/2,
                            cornerHeight: (thW - s*0.012)/2)
    ctx.setFillColor(CGColor(red: 0.15, green: 0.55, blue: 1.0, alpha: 1))
    ctx.addPath(mercPath)
    ctx.fillPath()

    // bulb
    let bulbCenter = CGPoint(x: s/2, y: thY + bulbR * 0.8)
    ctx.setFillColor(CGColor(red: 0.15, green: 0.55, blue: 1.0, alpha: 1))
    ctx.setShadow(offset: .zero, blur: s * 0.04,
                  color: CGColor(red: 0.20, green: 0.60, blue: 1.0, alpha: 0.80))
    ctx.addEllipse(in: CGRect(x: bulbCenter.x - bulbR, y: bulbCenter.y - bulbR,
                               width: bulbR*2, height: bulbR*2))
    ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)

    // ── Pin rows on chip sides ─────────────────────────────────────────────
    let pinW  = s * 0.035
    let pinH  = s * 0.055
    let pinR  = s * 0.010
    let pinCount = 4
    let pinSpacing = chipH / CGFloat(pinCount + 1)

    for i in 0..<pinCount {
        let py = chipY + pinSpacing * CGFloat(i + 1) - pinH / 2
        // left
        let lp = CGMutablePath()
        lp.addRoundedRect(in: CGRect(x: chipX - pinW, y: py, width: pinW, height: pinH),
                          cornerWidth: pinR, cornerHeight: pinR)
        ctx.setFillColor(CGColor(red: 0.25, green: 0.50, blue: 0.85, alpha: 0.70))
        ctx.addPath(lp); ctx.fillPath()
        // right
        let rp = CGMutablePath()
        rp.addRoundedRect(in: CGRect(x: chipX + chipW, y: py, width: pinW, height: pinH),
                          cornerWidth: pinR, cornerHeight: pinR)
        ctx.addPath(rp); ctx.fillPath()
    }

    // ── "SSD" label above chip ─────────────────────────────────────────────
    if size >= 64 {
        let labelSize = s * 0.11
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: labelSize, weight: .bold),
            .foregroundColor: NSColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 0.90),
        ]
        let str = NSAttributedString(string: "SSD", attributes: attrs)
        let bounds = str.boundingRect(with: NSSize(width: s, height: s), options: [])
        str.draw(at: NSPoint(x: (s - bounds.width) / 2,
                             y: chipY + chipH + s * 0.035))
    }

    img.unlockFocus()
    return img
}

func savePNG(_ image: NSImage, path: String) {
    guard let tiff   = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png    = bitmap.representation(using: .png, properties: [:]) else {
        print("❌  Failed to encode \(path)"); return
    }
    do {
        try png.write(to: URL(fileURLWithPath: path))
        print("✔  \(path)")
    } catch {
        print("❌  \(path): \(error)")
    }
}

for slice in slices {
    let icon = makeIcon(size: slice.px)
    savePNG(icon, path: "\(outputDir)/\(slice.name).png")
}

print("\nDone — \(slices.count) slices written to \(outputDir)")
