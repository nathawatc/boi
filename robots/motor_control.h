#ifndef MOTOR_CONTROL_H
#define MOTOR_CONTROL_H

#include <Arduino.h>
#include "config.h"

// Initialize motor pins and PWM channels for standard L298N driver
void initMotors() {
    // Set Direction pins (IN1, IN2, IN3, IN4) as standard digital outputs
    pinMode(MOTOR_A_IN1, OUTPUT);
    pinMode(MOTOR_A_IN2, OUTPUT);
    pinMode(MOTOR_B_IN3, OUTPUT);
    pinMode(MOTOR_B_IN4, OUTPUT);

    // Setup PWM channels for ENA and ENB (Speed Control)
    // New ESP32 Arduino Core 3.x API - combines setup and attach
    ledcAttachChannel(MOTOR_A_EN, PWM_FREQ, PWM_RESOLUTION, PWM_CH_A_EN);
    ledcAttachChannel(MOTOR_B_EN, PWM_FREQ, PWM_RESOLUTION, PWM_CH_B_EN);

    // Ensure motors are stopped initially
    digitalWrite(MOTOR_A_IN1, LOW);
    digitalWrite(MOTOR_A_IN2, LOW);
    digitalWrite(MOTOR_B_IN3, LOW);
    digitalWrite(MOTOR_B_IN4, LOW);

    ledcWrite(MOTOR_A_EN, 0);
    ledcWrite(MOTOR_B_EN, 0);
}

// Control Left Motor (Motor A)
// speed: -MAX_SPEED to MAX_SPEED (negative for reverse)
void setMotorLeft(int speed) {
    speed = constrain(speed, -MAX_SPEED, MAX_SPEED);
    if (speed > 0) {
        // Forward
        digitalWrite(MOTOR_A_IN1, HIGH);
        digitalWrite(MOTOR_A_IN2, LOW);
        ledcWrite(MOTOR_A_EN, speed);
    } else if (speed < 0) {
        // Reverse
        digitalWrite(MOTOR_A_IN1, LOW);
        digitalWrite(MOTOR_A_IN2, HIGH);
        ledcWrite(MOTOR_A_EN, -speed);
    } else {
        // Stop
        digitalWrite(MOTOR_A_IN1, LOW);
        digitalWrite(MOTOR_A_IN2, LOW);
        ledcWrite(MOTOR_A_EN, 0);
    }
}

// Control Right Motor (Motor B)
// speed: -MAX_SPEED to MAX_SPEED (negative for reverse)
void setMotorRight(int speed) {
    speed = constrain(speed, -MAX_SPEED, MAX_SPEED);
    if (speed > 0) {
        // Forward
        digitalWrite(MOTOR_B_IN3, HIGH);
        digitalWrite(MOTOR_B_IN4, LOW);
        ledcWrite(MOTOR_B_EN, speed);
    } else if (speed < 0) {
        // Reverse
        digitalWrite(MOTOR_B_IN3, LOW);
        digitalWrite(MOTOR_B_IN4, HIGH);
        ledcWrite(MOTOR_B_EN, -speed);
    } else {
        // Stop
        digitalWrite(MOTOR_B_IN3, LOW);
        digitalWrite(MOTOR_B_IN4, LOW);
        ledcWrite(MOTOR_B_EN, 0);
    }
}

// Stop all motors
void stopMotors() {
    setMotorLeft(0);
    setMotorRight(0);
}

// Convenience function to move both motors
void moveRobot(int left_speed, int right_speed) {
    setMotorLeft(left_speed);
    setMotorRight(right_speed);
}

#endif // MOTOR_CONTROL_H