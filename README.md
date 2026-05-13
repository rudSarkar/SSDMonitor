# SSDMonitor

A native macOS menu bar app that shows your SSD temperature, read speed, and write speed in real time — with no background daemons, no subprocess calls, and no App Store limitations.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5-orange) ![Architecture](https://img.shields.io/badge/arch-Apple%20Silicon%20%7C%20Intel-green)

---

## Features

- **Live SSD temperature** — reads directly from the NVMe thermal sensor via IOKit
- **Real-time read/write speeds** — separate R/W throughput in MB/s, updated on your chosen interval
- **Menu bar display** — compact monospaced readout: `42°C  R:1.4M  W:0.3M`
- **Popover dashboard** — animated arc gauge, speed bars, disk model name, and settings
- **°C / °F toggle** — persisted across launches
- **Configurable refresh interval** — 1 s / 2 s / 5 s / 10 s
- **Apple Silicon + Intel** — separate sensor backends, auto-selected at compile time
- **No sandbox** — direct IOKit access, no helper processes

---

## Screenshots

> _Click the menu bar icon to open the dashboard._

| Menu bar | Popover |
|----------|---------|
| `42°C  R:1.4M  W:0.3M` | Arc gauge · Speed bars · Settings |

---

## Requirements

| | |
|---|---|
| macOS | 13 Ventura or later |
| Architecture | Apple Silicon (M1/M2/M3/M4) or Intel |
| Xcode | 15 or later (to build from source) |
| Sandbox | **Disabled** — required for IOKit sensor access |

---

## Build from Source

```bash
git clone https://github.com/rudSarkar/SSDMonitor.git
cd SSDMonitor

xcodebuild \
  -project SSDMonitor.xcodeproj \
  -scheme SSDMonitor \
  -configuration Release \
  build

# The app lands here:
open ~/Library/Developer/Xcode/DerivedData/SSDMonitor-*/Build/Products/Release/SSDMonitor.app
```

No CocoaPods, no SPM dependencies, no external tools required.

---

## How It Works

### Temperature — Apple Silicon

Apple Silicon exposes NVMe temperature through a private `IOHIDEventSystem` API. The app loads three private symbols at runtime via `dlsym` to avoid a link-time dependency:

| Symbol | Purpose |
|--------|---------|
| `IOHIDEventSystemClientCreate(allocator, 0)` | Creates a full monitor client (type 0) |
| `IOHIDServiceClientCopyEvent(service, 15, 0)` | Reads the current temperature event (type 15) |
| `IOHIDEventGetFloatValue(event, (15<<16)\|0)` | Extracts the °C value as a `Double` |

Service discovery uses public IOKit APIs: `IOHIDEventSystemClientCopyServices` enumerates all 100+ HID services; `IOHIDServiceClientConformsTo(svc, 0xFF00, 5)` filters to thermal sensors; the one with `Product` containing `"NAND"` is the NVMe sensor.

### Temperature — Intel

Uses the System Management Controller (SMC) via `IOConnectCallStructMethod` with selector 5. Tries keys `TP0D` → `TE0T` → `TH0A` → `Ts0S` in order, decoding the `sp78` fixed-point format.

### Disk I/O Speed

Reads cumulative byte counters from `IOBlockStorageDriver` statistics via `IORegistryEntryCreateCFProperty("Statistics")`. Delta-over-time gives separate read and write throughput in MB/s — no `iostat`, no subprocesses, no shell parsing.

```
IOBlockStorageDriver
  └─ Statistics["Bytes (Read)"]   → UInt64
  └─ Statistics["Bytes (Write)"]  → UInt64
```

Internal drives are identified by walking to the child `IOMedia` node and checking `Removable=false` + `Ejectable=false`.

---

## Project Structure

```
SSDMonitor/
├── App/
│   ├── AppDelegate.swift          # NSStatusItem + NSPopover setup
│   └── SSDMonitorApp.swift        # SwiftUI entry point (LSUIElement, no dock icon)
├── Core/
│   ├── MonitorService.swift       # @MainActor ObservableObject, timer, Combine wiring
│   ├── DiskIOReader.swift         # IOBlockStorageDriver → MB/s
│   └── UserSettings.swift         # UserDefaults persistence (unit, interval)
├── Sensors/
│   ├── TemperatureReader.swift    # Protocol
│   ├── HIDTemperatureReader.swift # Apple Silicon — private IOHIDEventSystem dlsym
│   ├── SMCTemperatureReader.swift # Intel — SMC struct method
│   └── SMCBridge.h                # C structs for SMC key data
├── Models/
│   └── SSDStats.swift             # Data model + formatting helpers
└── UI/
    ├── StatusBarController.swift  # Menu bar text rendering
    ├── PopoverContentView.swift   # Root popover layout
    ├── TemperatureGaugeView.swift # Animated arc gauge (green/yellow/red)
    ├── SpeedRowView.swift         # R/W progress bars
    └── SettingsMenuView.swift     # Interval + unit pickers, Quit button
```

---

## Architecture

```
AppDelegate
    └── StatusBarController          (NSStatusItem, Combine subscriber)
    └── PopoverContentView           (SwiftUI, 280pt wide)
            └── MonitorService       (@MainActor ObservableObject)
                    ├── HIDTemperatureReader  (Apple Silicon)
                    │       └── dlsym → IOHIDEventSystem private API
                    ├── SMCTemperatureReader  (Intel)
                    │       └── IOConnectCallStructMethod → AppleSMC
                    └── DiskIOReader
                            └── IORegistryEntryCreateCFProperty → Statistics
```

`MonitorService` publishes `@Published var stats: SSDStats` on every tick. Both `StatusBarController` and `PopoverContentView` observe it via Combine / `@ObservedObject`.

---

## Privacy & Security

- **No network access** — entirely local IOKit calls
- **No sudo / root required** — runs as a normal user process
- **App Sandbox disabled** — required to open `/dev/` IOKit connections; the app makes no file system writes outside of `UserDefaults`
- **No private frameworks linked** — private symbols are loaded at runtime via `dlsym`; the binary has no hard dependency on undocumented APIs

---

## Limitations

- Temperature requires macOS to expose the NVMe HID service. If the sensor is unavailable (e.g. permissions change in a future OS update), the gauge shows **Unavailable** gracefully.
- Intel SMC key availability varies by Mac model; the app tries four common keys.
- External USB/Thunderbolt drives are intentionally excluded from I/O stats.

---

## License

MIT — see [LICENSE](LICENSE).
