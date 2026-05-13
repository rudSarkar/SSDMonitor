import Foundation
import IOKit

// Reads cumulative block storage I/O counters from IOKit and converts to MB/s.
final class DiskIOReader {

    private var prevRead:  UInt64 = 0
    private var prevWrite: UInt64 = 0
    private var prevTime:  Date   = .distantPast
    var diskName: String          = "—"

    func readSpeedsMBs() -> (read: Double, write: Double) {
        let now = Date()
        guard let (r2, w2, name) = fetchRawBytes() else { return (0, 0) }

        diskName = name

        let dt = now.timeIntervalSince(prevTime)
        defer { prevRead = r2; prevWrite = w2; prevTime = now }

        guard dt > 0.01, prevRead > 0 else { return (0, 0) }

        // Guard against counter wrap (extremely unlikely but safe)
        let deltR = r2 >= prevRead  ? r2 - prevRead  : 0
        let deltW = w2 >= prevWrite ? w2 - prevWrite : 0

        let readMBs  = Double(deltR) / dt / 1_048_576
        let writeMBs = Double(deltW) / dt / 1_048_576
        return (max(0, readMBs), max(0, writeMBs))
    }

    // Returns (totalBytesRead, totalBytesWritten, diskName) across all internal SSDs.
    private func fetchRawBytes() -> (UInt64, UInt64, String)? {
        var iterator: io_iterator_t = 0
        let ret = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOBlockStorageDriver"),
            &iterator
        )
        guard ret == kIOReturnSuccess else { return nil }
        defer { IOObjectRelease(iterator) }

        var totalRead:  UInt64 = 0
        var totalWrite: UInt64 = 0
        var foundName = "—"
        var foundAny  = false

        var service = IOIteratorNext(iterator)
        while service != IO_OBJECT_NULL {
            defer { IOObjectRelease(service); service = IOIteratorNext(iterator) }

            // Only count non-removable, non-ejectable drives (internal SSD)
            guard isInternalDrive(service) else { continue }

            guard let stats = IORegistryEntryCreateCFProperty(
                service,
                "Statistics" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue() as? [String: Any] else { continue }

            if let r = stats["Bytes (Read)"]  as? UInt64 { totalRead  += r }
            if let w = stats["Bytes (Write)"] as? UInt64 { totalWrite += w }

            if !foundAny {
                foundName = diskModelName(service)
                foundAny  = true
            }
        }

        return foundAny ? (totalRead, totalWrite, foundName) : nil
    }

    private func isInternalDrive(_ driver: io_object_t) -> Bool {
        // Walk the IORegistry children to find an IOMedia with Removable=false
        var childIterator: io_iterator_t = 0
        guard IORegistryEntryGetChildIterator(driver, kIOServicePlane, &childIterator) == kIOReturnSuccess else { return false }
        defer { IOObjectRelease(childIterator) }

        var child = IOIteratorNext(childIterator)
        while child != IO_OBJECT_NULL {
            defer { IOObjectRelease(child); child = IOIteratorNext(childIterator) }
            if let removable = IORegistryEntryCreateCFProperty(child, "Removable" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Bool,
               let ejectable = IORegistryEntryCreateCFProperty(child, "Ejectable" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Bool {
                if !removable && !ejectable { return true }
            }
        }
        return false
    }

    private func diskModelName(_ driver: io_object_t) -> String {
        // Try to get the product name from the parent IONVMeController or IOAHCIDevice
        var parentIterator: io_iterator_t = 0
        guard IORegistryEntryGetParentIterator(driver, kIOServicePlane, &parentIterator) == kIOReturnSuccess else { return "Internal SSD" }
        defer { IOObjectRelease(parentIterator) }

        var parent = IOIteratorNext(parentIterator)
        while parent != IO_OBJECT_NULL {
            defer { IOObjectRelease(parent); parent = IOIteratorNext(parentIterator) }
            if let name = IORegistryEntryCreateCFProperty(parent, "Model" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
                return name.trimmingCharacters(in: .whitespaces)
            }
            if let name = IORegistryEntryCreateCFProperty(parent, "Product" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
                return name.trimmingCharacters(in: CharacterSet.whitespaces)
            }
        }
        return "Internal SSD"
    }
}
