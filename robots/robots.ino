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

  // Wait for initial connection
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi Connected Successfully!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

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

  // ---------------------------------------------------------
  // 1. ROBUSTNESS: Auto-Reconnect WiFi if connection is lost
  // ---------------------------------------------------------
  if (WiFi.status() != WL_CONNECTED && (currentMillis - previousWiFiCheckMillis >= WIFI_CHECK_INTERVAL)) {
    Serial.println("WiFi Disconnected. Attempting to reconnect...");
    WiFi.disconnect();
    WiFi.reconnect();
    previousWiFiCheckMillis = currentMillis;

    // Safety: Stop the robot immediately if WiFi drops
    isLineFollowing = false;
    isMovingManually = false;
    stopMotors();
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

    int len = udp.read(packetBuffer, 255);
    if (len > 0) {
      packetBuffer[len] = 0; // null-terminate the string
    }

    String command = String(packetBuffer);
    command.trim(); // Remove trailing newline or whitespace

    Serial.printf("Received UDP command: %s from %s:%d\n", command.c_str(), remoteIp.toString().c_str(), remotePort);
    lastCommandTime = millis(); // Reset safety timer

    // Process command and send single response
    if (command == "F") {
      isLineFollowing = false;
      isMovingManually = true;
      moveRobot(MAX_SPEED, MAX_SPEED);
      sendResponse("F", remoteIp, remotePort);
    } else if (command == "B") {
      isLineFollowing = false;
      isMovingManually = true;
      moveRobot(-MAX_SPEED, -MAX_SPEED);
      sendResponse("B", remoteIp, remotePort);
    } else if (command == "L") {
      isLineFollowing = false;
      isMovingManually = true;
      moveRobot(-BASE_SPEED, BASE_SPEED);
      sendResponse("L", remoteIp, remotePort);
    } else if (command == "R") {
      isLineFollowing = false;
      isMovingManually = true;
      moveRobot(BASE_SPEED, -BASE_SPEED);
      sendResponse("R", remoteIp, remotePort);
    } else if (command == "S") {
      isLineFollowing = false;
      isMovingManually = false;
      stopMotors();
      sendResponse("S", remoteIp, remotePort);
    } else if (command == "LF") {
      isLineFollowing = true;
      isMovingManually = false;
      resetPID();
      Serial.println("Line Follow Mode Enabled");
      sendResponse("LF", remoteIp, remotePort);
    } else {
      Serial.println("Unknown Command ignored");
      sendResponse("ERR", remoteIp, remotePort);
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
  // 5. PID CONTINUOUS EXECUTION
  // ---------------------------------------------------------
  // If in line following mode, continuously update PID control
  if (isLineFollowing) {
    updatePID();
    delay(10); // Small delay for PID stability calculation
  }
}