#ifndef PID_CONTROL_H
#define PID_CONTROL_H

#include <Arduino.h>
#include "config.h"
#include "motor_control.h"

// Variables for PID control
float previous_error = 0;
float integral = 0;

// Function to read line sensors and calculate error
// Assuming 3 sensors (Left, Center, Right) returning 1 on black line, 0 on white
// Might need to adjust this depending on your specific sensors
float calculateLineError() {
    int left = digitalRead(SENSOR_LINE_LEFT);
    int center = digitalRead(SENSOR_LINE_CENTER);
    int right = digitalRead(SENSOR_LINE_RIGHT);

    // Simple error calculation logic based on sensor states
    if (left == 0 && center == 1 && right == 0) {
        return 0; // Centered
    } else if (left == 1 && center == 1 && right == 0) {
        return -1; // Slightly off to the right
    } else if (left == 1 && center == 0 && right == 0) {
        return -2; // Off to the right
    } else if (left == 0 && center == 1 && right == 1) {
        return 1; // Slightly off to the left
    } else if (left == 0 && center == 0 && right == 1) {
        return 2; // Off to the left
    } else if (left == 1 && center == 1 && right == 1) {
        return 0; // Intersection or all black
    } else if (left == 0 && center == 0 && right == 0) {
        // Lost the line, maybe use previous error to turn back
        return (previous_error > 0) ? 3 : -3;
    }

    return 0; // Default case
}

// Function to update PID and adjust motor speeds
void updatePID() {
    float error = calculateLineError();

    // Calculate PID terms
    float proportional = error;
    integral += error;
    float derivative = error - previous_error;

    // Calculate control output
    float control_signal = (PID_KP * proportional) + (PID_KI * integral) + (PID_KD * derivative);

    // Adjust motor speeds based on control signal
    int left_speed = BASE_SPEED + control_signal;
    int right_speed = BASE_SPEED - control_signal;

    // Apply speeds to motors
    moveRobot(left_speed, right_speed);

    // Save current error for next iteration
    previous_error = error;
}

// Reset PID variables (useful when starting/stopping line following mode)
void resetPID() {
    previous_error = 0;
    integral = 0;
}

#endif // PID_CONTROL_H
