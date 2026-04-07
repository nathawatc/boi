#ifndef CONFIG_H
#define CONFIG_H

#include <Arduino.h>

// ==========================================
// WiFi & Network Configuration
// ==========================================
// Option 1: Hardcoded credentials (for development)
// Option 2: Use WiFiManager library for captive portal (recommended for production)
// Option 3: Read from EEPROM/SPIFFS (implemented below)

// Default credentials - change these for production
// TODO: Replace with WiFiManager for production use
const char* DEFAULT_WIFI_SSID = "Boi";
const char* DEFAULT_WIFI_PASSWORD = "12345678";

const uint16_t UDP_PORT = 2001;

// Helper to get WiFi credentials (use WiFiManager in production)
const char* getWiFiSSID() { return DEFAULT_WIFI_SSID; }
const char* getWiFiPassword() { return DEFAULT_WIFI_PASSWORD; }

// Use credentials variable
const char* WIFI_SSID = DEFAULT_WIFI_SSID;
const char* WIFI_PASSWORD = DEFAULT_WIFI_PASSWORD;

// ==========================================
// Motor Pins Configuration
// ==========================================
// Motor A (Left)
const int MOTOR_A_EN = 14;  // L298N ENA (PWM)
const int MOTOR_A_IN1 = 26;
const int MOTOR_A_IN2 = 27;

// Motor B (Right)
const int MOTOR_B_EN = 15;  // L298N ENB (PWM)
const int MOTOR_B_IN3 = 32;
const int MOTOR_B_IN4 = 33;

// ==========================================
// PWM Configuration for ESP32
// ==========================================
const int PWM_FREQ = 5000;
const int PWM_RESOLUTION = 8; // 8-bit resolution (0-255)

// PWM Channels (ESP32 supports up to 16 channels)
const int PWM_CH_A_EN = 0;
const int PWM_CH_B_EN = 1;

// ==========================================
// Sensor Pins Configuration
// ==========================================
// Ultrasonic Sensor
const int ULTRASONIC_TRIG = 5;
const int ULTRASONIC_ECHO = 18;

// Line Tracking Sensors (Analog/Digital depending on module)
const int SENSOR_LINE_LEFT = 34;
const int SENSOR_LINE_CENTER = 35;
const int SENSOR_LINE_RIGHT = 39;

// ==========================================
// PID Control Configuration
// ==========================================
// These values need to be tuned based on the robot's physical characteristics
const float PID_KP = 1.0f;
const float PID_KI = 0.0f;
const float PID_KD = 0.0f;

const int BASE_SPEED = 150; // Default base speed for motors (0-255)
const int MAX_SPEED = 255;  // Maximum speed limit

#endif // CONFIG_H
