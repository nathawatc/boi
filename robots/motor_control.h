#ifndef MOTOR_CONTROL_H
#define MOTOR_CONTROL_H

#include <Arduino.h>
#include "config.h"

// Initialize motor pins and PWM channels
void initMotors() {
    // Setup PWM channels for ESP32
    ledcSetup(PWM_CH_A_IN1, PWM_FREQ, PWM_RESOLUTION);
    ledcSetup(PWM_CH_A_IN2, PWM_FREQ, PWM_RESOLUTION);
    ledcSetup(PWM_CH_B_IN3, PWM_FREQ, PWM_RESOLUTION);
    ledcSetup(PWM_CH_B_IN4, PWM_FREQ, PWM_RESOLUTION);

    // Attach pins to PWM channels
    ledcAttachPin(MOTOR_A_IN1, PWM_CH_A_IN1);
    ledcAttachPin(MOTOR_A_IN2, PWM_CH_A_IN2);
    ledcAttachPin(MOTOR_B_IN3, PWM_CH_B_IN3);
    ledcAttachPin(MOTOR_B_IN4, PWM_CH_B_IN4);

    // Ensure motors are stopped initially
    ledcWrite(PWM_CH_A_IN1, 0);
    ledcWrite(PWM_CH_A_IN2, 0);
    ledcWrite(PWM_CH_B_IN3, 0);
    ledcWrite(PWM_CH_B_IN4, 0);
}

// Control Left Motor
// speed: -MAX_SPEED to MAX_SPEED (negative for reverse)
void setMotorLeft(int speed) {
    speed = constrain(speed, -MAX_SPEED, MAX_SPEED);
    if (speed > 0) {
        ledcWrite(PWM_CH_A_IN1, speed);
        ledcWrite(PWM_CH_A_IN2, 0);
    } else if (speed < 0) {
        ledcWrite(PWM_CH_A_IN1, 0);
        ledcWrite(PWM_CH_A_IN2, -speed);
    } else {
        ledcWrite(PWM_CH_A_IN1, 0);
        ledcWrite(PWM_CH_A_IN2, 0);
    }
}

// Control Right Motor
// speed: -MAX_SPEED to MAX_SPEED (negative for reverse)
void setMotorRight(int speed) {
    speed = constrain(speed, -MAX_SPEED, MAX_SPEED);
    if (speed > 0) {
        ledcWrite(PWM_CH_B_IN3, speed);
        ledcWrite(PWM_CH_B_IN4, 0);
    } else if (speed < 0) {
        ledcWrite(PWM_CH_B_IN3, 0);
        ledcWrite(PWM_CH_B_IN4, -speed);
    } else {
        ledcWrite(PWM_CH_B_IN3, 0);
        ledcWrite(PWM_CH_B_IN4, 0);
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