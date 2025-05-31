#import <Foundation/Foundation.h>
#import "../include/RazerDeviceManager.h"

void printUsage() {
    printf("razerctl - Command line tool for Razer Basilisk X HyperSpeed\n\n");
    printf("Usage:\n");
    printf("  razerctl dpi <value>       Set DPI (100-16000)\n");
    printf("  razerctl polling <rate>    Set polling rate (125, 500, 1000)\n");
    printf("  razerctl battery           Get battery level\n");
    printf("  razerctl info              Get device information\n");
    printf("  razerctl status            Get current settings\n");
    printf("\nExamples:\n");
    printf("  razerctl dpi 1600\n");
    printf("  razerctl polling 1000\n");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            printUsage();
            return 1;
        }
        
        // Initialize device manager
        RazerDeviceManager *manager = [RazerDeviceManager sharedManager];
        [manager startDeviceDiscovery];
        
        // Wait a bit for device discovery
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        
        if (!manager.currentDevice) {
            fprintf(stderr, "Error: No Razer Basilisk X HyperSpeed found\n");
            return 1;
        }
        
        NSString *command = [NSString stringWithUTF8String:argv[1]];
        
        if ([command isEqualToString:@"dpi"]) {
            if (argc < 3) {
                fprintf(stderr, "Error: DPI value required\n");
                return 1;
            }
            
            int dpi = atoi(argv[2]);
            if (dpi < 100 || dpi > 16000) {
                fprintf(stderr, "Error: DPI must be between 100 and 16000\n");
                return 1;
            }
            
            if ([manager setDPI:dpi]) {
                printf("DPI set to %d\n", dpi);
            } else {
                fprintf(stderr, "Error: Failed to set DPI\n");
                return 1;
            }
        }
        else if ([command isEqualToString:@"polling"]) {
            if (argc < 3) {
                fprintf(stderr, "Error: Polling rate required\n");
                return 1;
            }
            
            int rate = atoi(argv[2]);
            if (rate != 125 && rate != 500 && rate != 1000) {
                fprintf(stderr, "Error: Polling rate must be 125, 500, or 1000\n");
                return 1;
            }
            
            if ([manager setPollingRate:rate]) {
                printf("Polling rate set to %d Hz\n", rate);
            } else {
                fprintf(stderr, "Error: Failed to set polling rate\n");
                return 1;
            }
        }
        else if ([command isEqualToString:@"battery"]) {
            NSNumber *battery = [manager getBatteryLevel];
            if (battery) {
                BOOL charging = [manager isCharging];
                printf("Battery: %d%% %s\n", [battery intValue], charging ? "(Charging)" : "");
            } else {
                fprintf(stderr, "Error: Failed to get battery level\n");
                return 1;
            }
        }
        else if ([command isEqualToString:@"info"]) {
            NSDictionary *info = [manager getDeviceInfo];
            if (info) {
                printf("Device Information:\n");
                printf("  Name:     %s\n", [[info objectForKey:@"name"] UTF8String] ?: "Unknown");
                printf("  Firmware: %s\n", [[info objectForKey:@"firmware"] UTF8String] ?: "Unknown");
                printf("  Serial:   %s\n", [[info objectForKey:@"serial"] UTF8String] ?: "Unknown");
                printf("  VID:PID:  %04x:%04x\n", 
                       [[info objectForKey:@"vendorId"] intValue],
                       [[info objectForKey:@"productId"] intValue]);
            } else {
                fprintf(stderr, "Error: Failed to get device info\n");
                return 1;
            }
        }
        else if ([command isEqualToString:@"status"]) {
            printf("Current Settings:\n");
            
            // Get DPI
            NSDictionary *dpiInfo = [manager getDPI];
            if (dpiInfo) {
                printf("  DPI: X=%d Y=%d\n", 
                       [[dpiInfo objectForKey:@"dpiX"] intValue],
                       [[dpiInfo objectForKey:@"dpiY"] intValue]);
            }
            
            // Get polling rate
            NSNumber *pollingRate = [manager getPollingRate];
            if (pollingRate) {
                printf("  Polling Rate: %d Hz\n", [pollingRate intValue]);
            }
            
            // Get battery
            NSNumber *battery = [manager getBatteryLevel];
            if (battery) {
                BOOL charging = [manager isCharging];
                printf("  Battery: %d%% %s\n", [battery intValue], charging ? "(Charging)" : "");
            }
        }
        else {
            fprintf(stderr, "Error: Unknown command '%s'\n", argv[1]);
            printUsage();
            return 1;
        }
        
        [manager stopDeviceDiscovery];
    }
    
    return 0;
} 