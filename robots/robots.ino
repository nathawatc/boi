#include <WiFi.h>
#include <WiFiUdp.h>
#include "config.h"
#include "motor_control.h"
#include "pid_control.h"

WiFiUDP udp;
char packetBuffer[255]; // buffer to hold incoming packet

// State tracking
bool isLineFollowing = false;
bool isMovingManually = false;

// Safety and Connectivity timers
unsigned long lastCommandTime = 0;
const unsigned long COMMAND_TIMEOUT = 1500; // 1.5 seconds safety stop

unsigned long previousWiFiCheckMillis = 0;
const long WIFI_CHECK_INTERVAL = 5000; // Check WiFi every 5 seconds

// Ultrasonic obstacle detection
unsigned long lastObstacleCheck = 0;
const long OBSTACLE_CHECK_INTERVAL = 200; // Check every 200ms
const int OBSTACLE_DISTANCE_CM = 30; // Stop if obstacle within 30cm

void setup() {
  Serial.begin(115200);

  // Initialize hardware
  initMotors();
  pinMode(SENSOR_LINE_LEFT, INPUT);
  pinMode(SENSOR_LINE_CENTER, INPUT);
  pinMode(SENSOR_LINE_RIGHT, INPUT);
  pinMode(ULTRASONIC_TRIG, OUTPUT);
  pinMode(ULTRASONIC_ECHO, INPUT);

  // Connect to WiFi
  WiFi.mode(WIFI_STA); // Set as Station mode
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("Connecting to WiFi: ");
  Serial.print(WIFI_SSID);

  // Wait for initial connection with timeout (10 seconds max)
  // SAFETY FIX: Don't block forever - allow robot to start even if WiFi unavailable
  unsigned long wifiConnectStart = millis();
  while (WiFi.status() != WL_CONNECTED && (millis() - wifiConnectStart < 10000)) {
    delay(500);
    Serial.print(".");
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi Connected Successfully!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nWiFi connection timeout. Starting anyway - will retry in loop.");
  }

  // Start UDP listening
  udp.begin(UDP_PORT);
  Serial.printf("Listening on UDP port %d\n", UDP_PORT);

  Serial.println("===== ระบบพร้อมทำงาน (System Ready) =====");
}

/// Measure distance using ultrasonic sensor (HC-SR04)
/// Returns distance in cm, or -1 if measurement failed
int getDistanceCM() {
  digitalWrite(ULTRASONIC_TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(ULTRASONIC_TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(ULTRASONIC_TRIG, LOW);

  long duration = pulseIn(ULTRASONIC_ECHO, HIGH, 30000); // 30ms timeout (~5m max)
  if (duration == 0) return -1; // Timeout, no echo received

  // Speed of sound: 343 m/s = 0.0343 cm/us
  // Distance = (duration * 0.0343) / 2 (round trip)
  return (int)(duration * 0.017);
}

/// Send UDP response back to the sender (for discovery/acknowledgment)
void sendResponse(const char* response, IPAddress remoteIp, int remotePort) {
  udp.beginPacket(remoteIp, remotePort);
  udp.write(response);
  udp.endPacket();
}

void loop() {
  unsigned long currentMillis = millis();

  // Clear packet buffer at start of each iteration to prevent stale data
  packetBuffer[0] = 0;

  // ---------------------------------------------------------
  // 1. ROBUSTNESS: Auto-Reconnect WiFi if connection is lost
  // ---------------------------------------------------------
  if (WiFi.status() != WL_CONNECTED && (currentMillis - previousWiFiCheckMillis >= WIFI_CHECK_INTERVAL)) {
    Serial.println("WiFi Disconnected. Attempting to reconnect...");
    
    // SAFETY FIX: Stop motors BEFORE attempting reconnection
    // Previously, motors kept running during 3-second reconnect attempt
    stopMotors();
    isLineFollowing = false;
    isMovingManually = false;
    Serial.println("Motors stopped for safety during WiFi reconnection.");
    
    WiFi.disconnect();
    delay(500);
    // Use WiFi.begin for reconnection (more reliable than WiFi.reconnect on ESP32 Core 3.x)
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    // Wait up to 3 seconds for reconnection
    unsigned long reconnectStart = millis();
    while (WiFi.status() != WL_CONNECTED && (millis() - reconnectStart < 3000)) {
      delay(200);
      Serial.print(".");
    }

    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("\nWiFi Reconnected Successfully!");
      Serial.print("IP Address: ");
      Serial.println(WiFi.localIP());
    } else {
      Serial.println("\nWiFi Reconnect Failed");
    }
    
    // FIX: Always restart UDP to ensure clean state
    // Previously only restarted on successful reconnect
    udp.stop();
    udp.begin(UDP_PORT);
    Serial.printf("UDP restarted on port %d\n", UDP_PORT);

    previousWiFiCheckMillis = currentMillis;
  }

  // ---------------------------------------------------------
  // 2. OBSTACLE DETECTION (Ultrasonic Sensor)
  // ---------------------------------------------------------
  if (currentMillis - lastObstacleCheck >= OBSTACLE_CHECK_INTERVAL) {
    lastObstacleCheck = currentMillis;

    int distance = getDistanceCM();
    if (distance > 0 && distance < OBSTACLE_DISTANCE_CM) {
      Serial.printf("OBSTACLE DETECTED: %d cm - Stopping!\n", distance);
      // Stop motors if obstacle detected (only if robot is moving)
      if (isMovingManually || isLineFollowing) {
        isMovingManually = false;
        isLineFollowing = false;
        stopMotors();
      }
    }
  }

  // ---------------------------------------------------------
  // 3. UDP COMMAND PROCESSING
  // ---------------------------------------------------------
  int packetSize = udp.parsePacket();
  if (packetSize) {
    IPAddress remoteIp = udp.remoteIP();
    int remotePort = udp.remotePort();

    // Read with bounds checking (buffer is 255 bytes, leave room for null terminator)
    int maxRead = min(packetSize, (int)sizeof(packetBuffer) - 1);
    int len = udp.read(packetBuffer, maxRead);
    if (len > 0 && len < (int)sizeof(packetBuffer)) {
      packetBuffer[len] = 0; // null-terminate the string
    } else if (len >= (int)sizeof(packetBuffer)) {
      // Safety: shouldn't happen, but ensure null termination
      packetBuffer[sizeof(packetBuffer) - 1] = 0;
      len = sizeof(packetBuffer) - 1;
    }

    // PERFORMANCE FIX: Avoid String heap fragmentation by using strcmp()
    // Trim whitespace manually instead of String.trim()
    int cmdLen = strlen(packetBuffer);
    while (cmdLen > 0 && (packetBuffer[cmdLen-1] == '\r' || packetBuffer[cmdLen-1] == '\n' || packetBuffer[cmdLen-1] == ' ')) {
      packetBuffer[--cmdLen] = 0;
    }

    Serial.printf("Received UDP command: %s from %s:%d\n", packetBuffer, remoteIp.toString().c_str(), remotePort);
    
    // FIX: Only reset safety timer on valid commands
    // Previously reset on all packets, preventing timeout if garbage floods in
    bool validCommand = false;

    // Process commands using strcmp() instead of String comparison
    if (strcmp(packetBuffer, "F") == 0) {
      validCommand = true;
      isLineFollowing = false;
      isMovingManually = true;
      moveRobot(MAX_SPEED, MAX_SPEED);
      sendResponse("F", remoteIp, remotePort);
    } else if (strcmp(packetBuffer, "B") == 0) {
      validCommand = true;
      isLineFollowing = false;
      isMovingManually = true;
      moveRobot(-MAX_SPEED, -MAX_SPEED);
      sendResponse("B", remoteIp, remotePort);
    } else if (strcmp(packetBuffer, "L") == 0) {
      validCommand = true;
      isLineFollowing = false;
      isMovingManually = true;
      moveRobot(-BASE_SPEED, BASE_SPEED);
      sendResponse("L", remoteIp, remotePort);
    } else if (strcmp(packetBuffer, "R") == 0) {
      validCommand = true;
      isLineFollowing = false;
      isMovingManually = true;
      moveRobot(BASE_SPEED, -BASE_SPEED);
      sendResponse("R", remoteIp, remotePort);
    } else if (strcmp(packetBuffer, "S") == 0) {
      validCommand = true;
      isLineFollowing = false;
      isMovingManually = false;
      stopMotors();
      sendResponse("S", remoteIp, remotePort);
    } else if (strcmp(packetBuffer, "LF") == 0) {
      validCommand = true;
      isLineFollowing = true;
      isMovingManually = false;
      resetPID();
      Serial.println("Line Follow Mode Enabled");
      sendResponse("LF", remoteIp, remotePort);
    } else {
      Serial.println("Unknown Command ignored");
      sendResponse("ERR", remoteIp, remotePort);
    }
    
    // Only reset safety timer for valid commands
    if (validCommand) {
      lastCommandTime = millis();
    }
  }

  // ---------------------------------------------------------
  // 4. SAFETY: Dead-man's Switch for Manual Control
  // ---------------------------------------------------------
  // If the robot is moving manually and hasn't received a command
  // in the last 1.5 seconds, automatically stop it to prevent crashing.
  if (isMovingManually && (currentMillis - lastCommandTime > COMMAND_TIMEOUT)) {
    Serial.println("Safety Timeout Triggered: Stopping motors.");
    isMovingManually = false;
    stopMotors();
  }

  // ---------------------------------------------------------
  // 5. SAFETY: Dead-man's Switch for Line-Follow Mode
  // ---------------------------------------------------------
  // SAFETY FIX: Previously, line-follow mode had NO timeout
  // Robot could run indefinitely if line was lost or robot got stuck
  if (isLineFollowing && (currentMillis - lastCommandTime > COMMAND_TIMEOUT)) {
    Serial.println("Safety Timeout in Line-Follow: Stopping motors.");
    isLineFollowing = false;
    stopMotors();
  }

  // ---------------------------------------------------------
  // 6. PID CONTINUOUS EXECUTION (Non-blocking)
  // ---------------------------------------------------------
  // FIX: Use non-blocking timing instead of delay(10)
  // Previously, delay(10) blocked all other processing (WiFi, obstacles, UDP)
  // Now PID updates at ~100Hz while keeping loop responsive
  if (isLineFollowing) {
    static unsigned long lastPidUpdate = 0;
    if (currentMillis - lastPidUpdate >= 10) {
      updatePID();
      lastPidUpdate = currentMillis;
    }
  }
}
