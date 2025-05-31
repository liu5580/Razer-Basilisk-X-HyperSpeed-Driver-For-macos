#include "../include/RazerUSBProtocol.h"
#include <string.h>

// Utility function to clamp uint16_t values
uint16_t clamp_u16(uint16_t value, uint16_t min, uint16_t max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
}

// Create a base report structure
RazerReport razer_get_report(uint8_t command_class, uint8_t command_id, uint8_t data_size) {
    RazerReport report;
    memset(&report, 0, sizeof(RazerReport));
    
    report.status = 0x00;  // New command
    report.transaction_id.id = 0x1F;  // Default for Basilisk X HyperSpeed
    report.remaining_packets = 0x0000;
    report.protocol_type = 0x00;
    report.data_size = data_size;
    report.command_class = command_class;
    report.command_id.id = command_id;
    report.reserved = 0x00;
    
    return report;
}

// Calculate CRC for the report
uint8_t razer_calculate_crc(RazerReport *report) {
    uint8_t crc = 0;
    uint8_t *data = (uint8_t *)report;
    
    // XOR all bytes except status, crc itself, and reserved
    for (int i = 2; i < RAZER_USB_REPORT_LEN - 2; i++) {
        crc ^= data[i];
    }
    
    return crc;
}

// Set DPI for X and Y axes
RazerReport razer_set_dpi_xy(uint8_t variable_storage, uint16_t dpi_x, uint16_t dpi_y) {
    RazerReport report = razer_get_report(0x04, 0x05, 0x07);
    
    // Clamp DPI values
    dpi_x = clamp_u16(dpi_x, 100, 35000);
    dpi_y = clamp_u16(dpi_y, 100, 35000);
    
    report.arguments[0] = variable_storage;
    report.arguments[1] = (dpi_x >> 8) & 0xFF;  // High byte
    report.arguments[2] = dpi_x & 0xFF;         // Low byte
    report.arguments[3] = (dpi_y >> 8) & 0xFF;  // High byte
    report.arguments[4] = dpi_y & 0xFF;         // Low byte
    report.arguments[5] = 0x00;
    report.arguments[6] = 0x00;
    
    report.crc = razer_calculate_crc(&report);
    
    return report;
}

// Get DPI for X and Y axes
RazerReport razer_get_dpi_xy(uint8_t variable_storage) {
    RazerReport report = razer_get_report(0x04, 0x85, 0x07);
    
    report.arguments[0] = variable_storage;
    report.crc = razer_calculate_crc(&report);
    
    return report;
}

// Set polling rate
RazerReport razer_set_polling_rate(uint16_t polling_rate) {
    RazerReport report = razer_get_report(0x00, 0x05, 0x01);
    
    switch (polling_rate) {
        case 1000:
            report.arguments[0] = 0x01;
            break;
        case 500:
            report.arguments[0] = 0x02;
            break;
        case 125:
            report.arguments[0] = 0x08;
            break;
        default:  // Default to 500Hz
            report.arguments[0] = 0x02;
            break;
    }
    
    report.crc = razer_calculate_crc(&report);
    
    return report;
}

// Get polling rate
RazerReport razer_get_polling_rate(void) {
    RazerReport report = razer_get_report(0x00, 0x85, 0x01);
    report.crc = razer_calculate_crc(&report);
    return report;
}

// Get battery level
RazerReport razer_get_battery_level(void) {
    RazerReport report = razer_get_report(0x07, 0x80, 0x02);
    report.crc = razer_calculate_crc(&report);
    return report;
}

// Get charging status
RazerReport razer_get_charging_status(void) {
    RazerReport report = razer_get_report(0x07, 0x84, 0x02);
    report.crc = razer_calculate_crc(&report);
    return report;
}

// Get firmware version
RazerReport razer_get_firmware_version(void) {
    RazerReport report = razer_get_report(0x00, 0x81, 0x02);
    report.transaction_id.id = 0x1F;  // Specific for Basilisk X HyperSpeed
    report.crc = razer_calculate_crc(&report);
    return report;
}

// Get serial number
RazerReport razer_get_serial(void) {
    RazerReport report = razer_get_report(0x00, 0x82, 0x16);
    report.crc = razer_calculate_crc(&report);
    return report;
} 