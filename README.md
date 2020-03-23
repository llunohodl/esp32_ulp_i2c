# STLM75 and VEML3328 I2C sensor driver for ESP32 ULP coprocessor

**Project based on [tomtor/ulp-i2c](https://github.com/tomtor/ulp-i2c.git)**

STLM75 and VEML3328 is connected to GPIO 18 (sda) / 5 (scl) | LED connected at GPIO 21 


[ESP-IDF version: v4.0 (CMake)](https://github.com/espressif/esp-idf/tree/release/v4.0)

**Don't forget reserve RTC SLOW MEM for ULP program** from 2048 bytes to 8Kb max (see [ESP32_RM p.27](https://www.espressif.com/sites/default/files/documentation/esp32_technical_reference_manual_en.pdf))

Settings at: SDK config->Component Config->ESP32 specific->RTC slow memory reserved for coprocessor
