#include <WiFi.h>
#include <WiFiUdp.h>
#include "config.h"
#include "motor_control.h"
#include "pid_control.h"

WiFiUDP udp;
char packetBuffer[255]; // buffer to hold incoming packet

bool isLineFollowing = false;

void setup() {
  Serial.begin(115200);

  // Initialize motors with PWM
  initMotors();

  // Initialize line sensors
  pinMode(SENSOR_LINE_LEFT, INPUT);
  pinMode(SENSOR_LINE_CENTER, INPUT);
  pinMode(SENSOR_LINE_RIGHT, INPUT);

  // Initialize Ultrasonic pins
  pinMode(ULTRASONIC_TRIG, OUTPUT);
  pinMode(ULTRASONIC_ECHO, INPUT);

  // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi: ");
  Serial.print(WIFI_SSID);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println("\nWiFi Connected");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  // Start UDP listening
  udp.begin(UDP_PORT);
  Serial.printf("Listening on UDP port %d\n", UDP_PORT);

  Serial.println("===== ระบบพร้อมทำงาน =====");
}

void loop() {
  // Check for incoming UDP packets
  int packetSize = udp.parsePacket();
  if (packetSize) {
    int len = udp.read(packetBuffer, 255);
    if (len > 0) {
      packetBuffer[len] = 0; // null-terminate the string
    }
    
    String command = String(packetBuffer);
    command.trim(); // Remove trailing newline or whitespace
    
    Serial.printf("Received UDP command: %s\n", command.c_str());

    // Process command
    if (command == "F") {
      isLineFollowing = false;
      moveRobot(MAX_SPEED, MAX_SPEED);
    } else if (command == "B") {
      isLineFollowing = false;
      moveRobot(-MAX_SPEED, -MAX_SPEED);
    } else if (command == "L") {
      isLineFollowing = false;
      moveRobot(-BASE_SPEED, BASE_SPEED);
    } else if (command == "R") {
      isLineFollowing = false;
      moveRobot(BASE_SPEED, -BASE_SPEED);
    } else if (command == "S") {
      isLineFollowing = false;
      stopMotors();
    } else if (command == "LF") {
      isLineFollowing = true;
      resetPID();
      Serial.println("Line Follow Mode Enabled");
    } else {
      Serial.println("Unknown Command");
    }
  }

  // If in line following mode, continuously update PID control
  if (isLineFollowing) {
    updatePID();
    // A small delay for stability in loop iteration
    delay(10); 
  }
}