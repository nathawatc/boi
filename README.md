# Boi App

A Flutter application for customer orders and e-commerce.

## Project Structure

This repository has been structured to follow standard Flutter best practices. Here is an overview of the key directories:

* **`lib/`**: Contains the main Dart source code for the application.
  *   **`pages/`**: Full-screen views and routes of the app (e.g., `home_page.dart`, `cart_page.dart`, `payment_page.dart`).
  *   **`widgets/`**: Reusable UI components used across multiple pages (e.g., `product_card.dart`, `custom_search_bar.dart`).
  *   **`providers/`**: State management logic and providers (e.g., `cart_provider.dart`).
  *   **`theme/`**: App-wide styling, colors, and theme configurations (`app_theme.dart`).
  *   **`main.dart`**: The entry point of the Flutter application.
* **`assets/`**: Static files used by the app, such as images and sound files.
  *   **`images/`**: Image assets (e.g., `Logo.JPG`).
  *   **`sounds/`**: Audio assets.
* **`apks/`**: Contains pre-compiled Android `.apk` builds of the application.

## Getting Started

To run this project locally, ensure you have Flutter installed and set up on your machine.

1. **Clone the repository** (if you haven't already).
2. **Install dependencies**:

    ```bash
    flutter pub get
    ```

3. **Run the app**:

    ```bash
    flutter run
    ```

### Compile

   ```bash
   flutter build apk --release
   flutter build ios --release
   ```

## Resources

A few resources to get you started if this is your first Flutter project:

* [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
* [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
* [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
