#import "../include/RazerDeviceManager.h"
#import <IOKit/IOKitLib.h>
#import <IOKit/usb/IOUSBLib.h>

@implementation RazerDeviceManager

static RazerDeviceManager *sharedInstance = nil;

+ (RazerDeviceManager *)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RazerDeviceManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.connectedDevices = [NSMutableArray array];
        self.currentDevice = NULL;
    }
    return self;
}

// Device discovery callback
static void deviceDiscoveredCallback(void *context, IOReturn result, void *sender, IOHIDDeviceRef device) {
    RazerDeviceManager *manager = (__bridge RazerDeviceManager *)context;
    
    NSNumber *vendorID = (__bridge NSNumber *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVendorIDKey));
    NSNumber *productID = (__bridge NSNumber *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductIDKey));
    
    if ([vendorID intValue] == RAZER_VENDOR_ID && [productID intValue] == RAZER_BASILISK_X_HYPERSPEED_PID) {
        NSLog(@"Found Razer Basilisk X HyperSpeed!");
        [manager.connectedDevices addObject:(__bridge id)device];
        
        // Auto-connect to first device found
        if (manager.currentDevice == NULL) {
            [manager connectToDevice:device];
        }
    }
}

// Device removal callback
static void deviceRemovedCallback(void *context, IOReturn result, void *sender, IOHIDDeviceRef device) {
    RazerDeviceManager *manager = (__bridge RazerDeviceManager *)context;
    
    [manager.connectedDevices removeObject:(__bridge id)device];
    
    if (manager.currentDevice == device) {
        manager.currentDevice = NULL;
        NSLog(@"Current device disconnected");
    }
}

- (BOOL)startDeviceDiscovery {
    self.hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    
    if (!self.hidManager) {
        NSLog(@"Failed to create HID Manager");
        return NO;
    }
    
    // Set up device matching
    NSDictionary *matchingDict = @{
        @(kIOHIDVendorIDKey): @(RAZER_VENDOR_ID),
        @(kIOHIDProductIDKey): @(RAZER_BASILISK_X_HYPERSPEED_PID)
    };
    
    IOHIDManagerSetDeviceMatching(self.hidManager, (__bridge CFDictionaryRef)matchingDict);
    
    // Set up callbacks
    IOHIDManagerRegisterDeviceMatchingCallback(self.hidManager, deviceDiscoveredCallback, (__bridge void *)self);
    IOHIDManagerRegisterDeviceRemovalCallback(self.hidManager, deviceRemovedCallback, (__bridge void *)self);
    
    // Schedule with run loop
    IOHIDManagerScheduleWithRunLoop(self.hidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    
    // Open HID Manager
    IOReturn ret = IOHIDManagerOpen(self.hidManager, kIOHIDOptionsTypeNone);
    if (ret != kIOReturnSuccess) {
        NSLog(@"Failed to open HID Manager: 0x%x", ret);
        return NO;
    }
    
    NSLog(@"Device discovery started");
    return YES;
}

- (void)stopDeviceDiscovery {
    if (self.hidManager) {
        IOHIDManagerClose(self.hidManager, kIOHIDOptionsTypeNone);
        CFRelease(self.hidManager);
        self.hidManager = NULL;
    }
}

- (NSArray *)getConnectedDevices {
    return [self.connectedDevices copy];
}

- (BOOL)connectToDevice:(IOHIDDeviceRef)device {
    if (!device) return NO;
    
    IOReturn ret = IOHIDDeviceOpen(device, kIOHIDOptionsTypeNone);
    if (ret != kIOReturnSuccess) {
        NSLog(@"Failed to open device: 0x%x", ret);
        return NO;
    }
    
    self.currentDevice = device;
    NSLog(@"Connected to device");
    return YES;
}

- (BOOL)sendReport:(RazerReport *)report {
    if (!self.currentDevice || !report) return NO;
    
    IOReturn ret = IOHIDDeviceSetReport(self.currentDevice, 
                                        kIOHIDReportTypeFeature, 
                                        0,  // Report ID
                                        (uint8_t *)report, 
                                        RAZER_USB_REPORT_LEN);
    
    if (ret != kIOReturnSuccess) {
        NSLog(@"Failed to send report: 0x%x", ret);
        return NO;
    }
    
    return YES;
}

- (BOOL)sendReportAndGetResponse:(RazerReport *)request response:(RazerReport *)response {
    if (![self sendReport:request]) {
        return NO;
    }
    
    // Wait a bit for device to process
    usleep(10000);  // 10ms
    
    CFIndex reportSize = RAZER_USB_REPORT_LEN;
    IOReturn ret = IOHIDDeviceGetReport(self.currentDevice,
                                        kIOHIDReportTypeFeature,
                                        0,  // Report ID
                                        (uint8_t *)response,
                                        &reportSize);
    
    if (ret != kIOReturnSuccess) {
        NSLog(@"Failed to get report: 0x%x", ret);
        return NO;
    }
    
    // Check if response is valid
    if (response->status == RAZER_CMD_SUCCESSFUL) {
        return YES;
    } else {
        NSLog(@"Command failed with status: 0x%02x", response->status);
        return NO;
    }
}

// Device control functions
- (BOOL)setDPI:(uint16_t)dpi {
    return [self setDPIXY:dpi dpiY:dpi];
}

- (BOOL)setDPIXY:(uint16_t)dpiX dpiY:(uint16_t)dpiY {
    RazerReport request = razer_set_dpi_xy(VARSTORE, dpiX, dpiY);
    RazerReport response = {0};
    
    BOOL success = [self sendReportAndGetResponse:&request response:&response];
    if (success) {
        NSLog(@"DPI set to X:%d Y:%d", dpiX, dpiY);
    }
    return success;
}

- (NSDictionary *)getDPI {
    RazerReport request = razer_get_dpi_xy(VARSTORE);
    RazerReport response = {0};
    
    if ([self sendReportAndGetResponse:&request response:&response]) {
        uint16_t dpiX = (response.arguments[1] << 8) | response.arguments[2];
        uint16_t dpiY = (response.arguments[3] << 8) | response.arguments[4];
        
        return @{
            @"dpiX": @(dpiX),
            @"dpiY": @(dpiY)
        };
    }
    
    return nil;
}

- (BOOL)setPollingRate:(uint16_t)pollingRate {
    RazerReport request = razer_set_polling_rate(pollingRate);
    RazerReport response = {0};
    
    BOOL success = [self sendReportAndGetResponse:&request response:&response];
    if (success) {
        NSLog(@"Polling rate set to %dHz", pollingRate);
    }
    return success;
}

- (NSNumber *)getPollingRate {
    RazerReport request = razer_get_polling_rate();
    RazerReport response = {0};
    
    if ([self sendReportAndGetResponse:&request response:&response]) {
        uint16_t rate = 500;  // Default
        
        switch (response.arguments[0]) {
            case 0x01:
                rate = 1000;
                break;
            case 0x02:
                rate = 500;
                break;
            case 0x08:
                rate = 125;
                break;
        }
        
        return @(rate);
    }
    
    return nil;
}

- (NSNumber *)getBatteryLevel {
    RazerReport request = razer_get_battery_level();
    RazerReport response = {0};
    
    if ([self sendReportAndGetResponse:&request response:&response]) {
        uint8_t batteryLevel = response.arguments[1];  // Battery percentage
        return @(batteryLevel);
    }
    
    return nil;
}

- (BOOL)isCharging {
    RazerReport request = razer_get_charging_status();
    RazerReport response = {0};
    
    if ([self sendReportAndGetResponse:&request response:&response]) {
        return response.arguments[1] != 0;  // Non-zero means charging
    }
    
    return NO;
}

- (NSDictionary *)getDeviceInfo {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    // Get firmware version
    RazerReport fwRequest = razer_get_firmware_version();
    RazerReport fwResponse = {0};
    
    if ([self sendReportAndGetResponse:&fwRequest response:&fwResponse]) {
        NSString *firmware = [NSString stringWithFormat:@"%d.%d", 
                              fwResponse.arguments[0], 
                              fwResponse.arguments[1]];
        info[@"firmware"] = firmware;
    }
    
    // Get serial number
    RazerReport serialRequest = razer_get_serial();
    RazerReport serialResponse = {0};
    
    if ([self sendReportAndGetResponse:&serialRequest response:&serialResponse]) {
        NSString *serial = [[NSString alloc] initWithBytes:serialResponse.arguments 
                                                     length:22 
                                                   encoding:NSUTF8StringEncoding];
        info[@"serial"] = serial ?: @"Unknown";
    }
    
    // Add device name
    info[@"name"] = @"Razer Basilisk X HyperSpeed";
    info[@"vendorId"] = @(RAZER_VENDOR_ID);
    info[@"productId"] = @(RAZER_BASILISK_X_HYPERSPEED_PID);
    
    return [info copy];
}

- (BOOL)hasInputMonitoringPermission {
    // Check if we have Input Monitoring permission
    // On macOS, we can try to create an IOHIDManager and see if it fails with permission error
    IOHIDManagerRef testManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDManagerOptionNone);
    
    if (!testManager) {
        return NO;
    }
    
    // Try to open the manager - this will fail if we don't have permissions
    IOReturn result = IOHIDManagerOpen(testManager, kIOHIDManagerOptionNone);
    
    if (testManager) {
        CFRelease(testManager);
    }
    
    // kIOReturnNotPermitted = 0xe00002e2
    return (result == kIOReturnSuccess);
}

@end 