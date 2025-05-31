#ifndef RAZER_DEVICE_MANAGER_H
#define RAZER_DEVICE_MANAGER_H

#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDManager.h>
#import <IOKit/hid/IOHIDDevice.h>
#include "RazerUSBProtocol.h"

@interface RazerDeviceManager : NSObject

@property (nonatomic, assign) IOHIDManagerRef hidManager;
@property (nonatomic, strong) NSMutableArray *connectedDevices;
@property (nonatomic, assign) IOHIDDeviceRef currentDevice;

// Singleton instance
+ (RazerDeviceManager *)sharedManager;

// Device management
- (BOOL)startDeviceDiscovery;
- (void)stopDeviceDiscovery;
- (NSArray *)getConnectedDevices;
- (BOOL)connectToDevice:(IOHIDDeviceRef)device;

// USB communication
- (BOOL)sendReport:(RazerReport *)report;
- (BOOL)sendReportAndGetResponse:(RazerReport *)request response:(RazerReport *)response;

// Device control functions
- (BOOL)setDPI:(uint16_t)dpi;
- (BOOL)setDPIXY:(uint16_t)dpiX dpiY:(uint16_t)dpiY;
- (NSDictionary *)getDPI;
- (BOOL)setPollingRate:(uint16_t)pollingRate;
- (NSNumber *)getPollingRate;
- (NSNumber *)getBatteryLevel;
- (BOOL)isCharging;
- (NSDictionary *)getDeviceInfo;

// Permission checking
- (BOOL)hasInputMonitoringPermission;

@end

#endif // RAZER_DEVICE_MANAGER_H 