import Foundation
import IOKit
import IOKit.hid

// Reads NAND/NVMe temperature on Apple Silicon using private IOHIDEventSystem APIs
// loaded at runtime via dlsym to avoid link-time dependency on private symbols.
final class HIDTemperatureReader: TemperatureReader {

    // MARK: - Private function pointer types

    // IOHIDEventSystemClientCreate(allocator, type) -> IOHIDEventSystemClientRef
    private typealias CreateClientFn  = @convention(c) (CFAllocator?, Int32) -> AnyObject?
    // IOHIDServiceClientCopyEvent(service, type, options) -> IOHIDEventRef
    private typealias CopyEventFn     = @convention(c) (AnyObject, Int32, Int32) -> AnyObject?
    // IOHIDEventGetFloatValue(event, field) -> Double
    private typealias GetFloatValueFn = @convention(c) (AnyObject, Int32) -> Double

    // kIOHIDEventTypeTemperature = 15
    private static let kTempEventType: Int32 = 15
    // temperature field: (kIOHIDEventTypeTemperature << 16) | 0
    private static let kTempField:     Int32 = (15 << 16) | 0

    // MARK: - Loaded symbols

    private var createClient:  CreateClientFn?
    private var copyEvent:     CopyEventFn?
    private var getFloatValue: GetFloatValueFn?

    // Keep the event system client alive — services are owned by their client
    private var eventSystemClient: AnyObject?
    // The cached NAND service ref (IOHIDServiceClientRef is toll-free bridged to AnyObject)
    private var nandService: AnyObject?

    // MARK: - Init

    init() {
        loadSymbols()
        findNANDService()
    }

    // MARK: - Symbol loading

    private func loadSymbols() {
        guard let handle = dlopen(
            "/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY
        ) else { return }

        if let sym = dlsym(handle, "IOHIDEventSystemClientCreate") {
            createClient = unsafeBitCast(sym, to: CreateClientFn.self)
        }
        if let sym = dlsym(handle, "IOHIDServiceClientCopyEvent") {
            copyEvent = unsafeBitCast(sym, to: CopyEventFn.self)
        }
        if let sym = dlsym(handle, "IOHIDEventGetFloatValue") {
            getFloatValue = unsafeBitCast(sym, to: GetFloatValueFn.self)
        }
    }

    // MARK: - NAND service discovery

    private func findNANDService() {
        guard let createClient else { return }

        // type 0 = kIOHIDEventSystemClientTypeMonitor (full client)
        guard let client = createClient(kCFAllocatorDefault, 0) else { return }

        // Retain the client for the lifetime of this object — service refs depend on it
        eventSystemClient = client

        guard let cfServices = IOHIDEventSystemClientCopyServices(
            client as! IOHIDEventSystemClient
        ) else { return }

        // CFArray → [AnyObject] via toll-free bridging (unconditional cast, never fails)
        let services = cfServices as [AnyObject]

        for service in services {
            guard IOHIDServiceClientConformsTo(
                service as! IOHIDServiceClient, 0xFF00, 5
            ) != 0 else { continue }

            if let product = IOHIDServiceClientCopyProperty(
                service as! IOHIDServiceClient,
                "Product" as CFString
            ) as? String,
               product.contains("NAND") {
                nandService = service
                return
            }
        }
    }

    // MARK: - TemperatureReader

    func readTemperatureCelsius() -> Double? {
        guard let nandService,
              let copyEvent,
              let getFloatValue else { return nil }

        guard let event = copyEvent(nandService, Self.kTempEventType, 0) else { return nil }

        let temp = getFloatValue(event, Self.kTempField)
        guard temp > 0, temp < 150 else { return nil }
        return temp
    }
}
