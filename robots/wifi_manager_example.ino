// ============================================
// WiFiManager Integration Example for ESP32
// ============================================
// This example shows how to use WiFiManager for dynamic WiFi configuration
//
// Required Library: tzapu WiFiManager
// Install via Library Manager or:
//   pio lib install "WiFiManager"
//
// Uncomment the code below and integrate with robots.ino
// ============================================

/*
#include <WiFi.h>
#include <WiFiManager.h>
#include "config.h"

WiFiManager wifiManager;

void setupWiFi() {
  // Reset settings - for testing
  // wifiManager.resetSettings();

  // Set timeout for portal
  wifiManager.setConfigPortalTimeout(180); // 3 minutes

  // Auto connect, if fails starts portal
  if (!wifiManager.autoConnect("Boi-Robot")) {
    Serial.println("Failed to connect and hit timeout");
    delay(3000);
    ESP.restart();
  }

  Serial.println("WiFi connected!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void setup() {
  Serial.begin(115200);
  setupWiFi();

  // Rest of your setup code...
}

void loop() {
  // Keep WiFiManager running for portal access
  wifiManager.process();

  // Rest of your loop code...
}
*/
