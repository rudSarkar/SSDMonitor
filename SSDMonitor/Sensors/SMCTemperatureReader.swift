import Foundation
import IOKit

// Reads NVMe/SSD temperature from the System Management Controller.
// Used on Intel Macs. On Apple Silicon, HIDTemperatureReader is used instead.
final class SMCTemperatureReader: TemperatureReader {

    private var connection: io_connect_t = 0
    private var isOpen = false

    // NVMe/NAND temperature key candidates — tried in order
    // Apple Silicon: NAND die sensors (TN = NAND), SSD proximity (Ts0S)
    private static let appleSliliconKeys = ["TN0C", "TN0D", "TN1C", "TN1D", "Ts0S", "TH0a", "TH1a"]
    // Intel: NVMe controller die (TP), embedded controller SATA (TE, TH)
    private static let intelKeys         = ["TP0D", "TE0T", "TH0A", "Ts0S", "THSP"]

    private var keysToTry: [String] {
        var cpu: Int = 0
        var size = MemoryLayout<Int>.size
        sysctlbyname("hw.cputype", &cpu, &size, nil, 0)
        // CPU type 12 = ARM (Apple Silicon), 7 = x86 (Intel)
        return cpu == 12 ? Self.appleSliliconKeys : Self.intelKeys
    }

    init() { open() }
    deinit { close() }

    private func open() {
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("AppleSMC"),
            &iterator
        )
        guard result == kIOReturnSuccess else { return }
        defer { IOObjectRelease(iterator) }

        let service = IOIteratorNext(iterator)
        guard service != IO_OBJECT_NULL else { return }
        defer { IOObjectRelease(service) }

        let ret = IOServiceOpen(service, mach_task_self_, 0, &connection)
        isOpen = ret == kIOReturnSuccess
    }

    private func close() {
        if isOpen { IOServiceClose(connection) }
    }

    func readTemperatureCelsius() -> Double? {
        guard isOpen else { return nil }
        for key in keysToTry {
            if let temp = readKey(key) { return temp }
        }
        return nil
    }

    private func readKey(_ keyString: String) -> Double? {
        var inputStruct  = SMCKeyData_t()
        var outputStruct = SMCKeyData_t()

        // Pack 4-char ASCII key into big-endian UInt32
        let bytes = Array(keyString.utf8)
        guard bytes.count == 4 else { return nil }
        inputStruct.key = UInt32(bytes[0]) << 24
                        | UInt32(bytes[1]) << 16
                        | UInt32(bytes[2]) << 8
                        | UInt32(bytes[3])
        inputStruct.data8 = UInt8(kSMCReadKey)

        var inSize  = MemoryLayout<SMCKeyData_t>.size
        var outSize = MemoryLayout<SMCKeyData_t>.size

        let ret = IOConnectCallStructMethod(
            connection,
            UInt32(kSMCReadKey),
            &inputStruct,  inSize,
            &outputStruct, &outSize
        )
        guard ret == kIOReturnSuccess, outputStruct.result == 0 else { return nil }

        // Decode sp78 fixed-point type: byte[0] is integer part, byte[1]/256 is fractional
        let raw = UInt16(outputStruct.bytes.0) << 8 | UInt16(outputStruct.bytes.1)
        let temp = Double(Int16(bitPattern: raw)) / 256.0
        guard temp > 0, temp < 120 else { return nil }
        return temp
    }
}
