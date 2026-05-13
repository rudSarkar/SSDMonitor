#pragma once
#include <IOKit/IOKitLib.h>

typedef struct {
    uint32_t dataSize;
    uint32_t dataType;
    uint8_t  dataAttributes;
} SMCKeyData_keyInfo_t;

typedef struct {
    uint32_t              key;
    SMCKeyData_keyInfo_t  keyInfo;
    uint8_t               result;
    uint8_t               status;
    uint8_t               data8;
    uint32_t              data32;
    uint8_t               bytes[32];
} SMCKeyData_t;

#define kSMCGetKeyInfo   9
#define kSMCReadKey      5
#define kSMCSuccess      0
