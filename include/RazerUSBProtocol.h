#ifndef RAZER_USB_PROTOCOL_H
#define RAZER_USB_PROTOCOL_H

#include <stdint.h>
#include <stdbool.h>

// USB Vendor and Product IDs
#define RAZER_VENDOR_ID 0x1532
#define RAZER_BASILISK_X_HYPERSPEED_PID 0x0083

// USB Report Length
#define RAZER_USB_REPORT_LEN 0x5A  // 90 bytes

// LED State
#define OFF 0x00
#define ON  0x01

// LED Storage Options
#define NOSTORE 0x00
#define VARSTORE 0x01

// LED Definitions
#define ZERO_LED          0x00
#define SCROLL_WHEEL_LED  0x01
#define BATTERY_LED       0x03
#define LOGO_LED          0x04
#define BACKLIGHT_LED     0x05

// Report Status
#define RAZER_CMD_BUSY          0x01
#define RAZER_CMD_SUCCESSFUL    0x02
#define RAZER_CMD_FAILURE       0x03
#define RAZER_CMD_TIMEOUT       0x04
#define RAZER_CMD_NOT_SUPPORTED 0x05

// RGB Structure
typedef struct {
    uint8_t r;
    uint8_t g;
    uint8_t b;
} RazerRGB;

// Transaction ID Union
typedef union {
    uint8_t id;
    struct {
        uint8_t device : 3;
        uint8_t id : 5;
    } parts;
} TransactionID;

// Command ID Union
typedef union {
    uint8_t id;
    struct {
        uint8_t direction : 1;
        uint8_t id : 7;
    } parts;
} CommandID;

// Razer Report Structure
typedef struct {
    uint8_t status;
    TransactionID transaction_id;
    uint16_t remaining_packets;  // Big Endian
    uint8_t protocol_type;       // Always 0x00
    uint8_t data_size;
    uint8_t command_class;
    CommandID command_id;
    uint8_t arguments[80];
    uint8_t crc;                 // XOR'ed bytes of report
    uint8_t reserved;            // Always 0x00
} RazerReport;

// Function declarations
RazerReport razer_get_report(uint8_t command_class, uint8_t command_id, uint8_t data_size);
uint8_t razer_calculate_crc(RazerReport *report);

// DPI Functions
RazerReport razer_set_dpi_xy(uint8_t variable_storage, uint16_t dpi_x, uint16_t dpi_y);
RazerReport razer_get_dpi_xy(uint8_t variable_storage);

// Polling Rate Functions
RazerReport razer_set_polling_rate(uint16_t polling_rate);
RazerReport razer_get_polling_rate(void);

// Battery Functions
RazerReport razer_get_battery_level(void);
RazerReport razer_get_charging_status(void);

// Device Info Functions
RazerReport razer_get_firmware_version(void);
RazerReport razer_get_serial(void);

// Utility Functions
uint16_t clamp_u16(uint16_t value, uint16_t min, uint16_t max);

#endif // RAZER_USB_PROTOCOL_H 