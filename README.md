# PantryPay Mobile (pp-mobile)

PantryPay (also known as PantryPal V3) is a comprehensive cross-platform mobile application built with Flutter. It helps users manage their kitchen inventory, discover recipes based on their pantry, plan meals, and streamline their grocery shopping experience.

## Features

- **Authentication & Onboarding**: Secure user authentication powered by AWS Amplify Cognito.
- **Pantry Management**: 
  - Track inventory levels of ingredients.
  - Smart scanning integration (camera/image picker) to add items easily.
- **Recipe Discovery**: 
  - Browse recipes powered by Spoonacular API.
  - "Cook Now" functionality which automatically deducts used ingredients from your pantry.
- **Shopping Planner**: Manage your shopping lists, moving items easily between your cart and pantry.
- **Dashboard**: A centralized view of your kitchen's status.

## Tech Stack & Architecture

This application leverages modern Flutter development practices:

- **Framework**: Flutter SDK (>=3.3.0)
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`, `riverpod_generator`)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) for declarative routing
- **Networking**: [Dio](https://pub.dev/packages/dio) for robust HTTP requests
- **Authentication**: AWS Amplify Cognito (`amplify_flutter`)
- **Environment**: `flutter_dotenv` for managing environment variables

## Project Structure

The codebase is organized into feature-based modules within the `lib/features` directory:

- `auth/` - Authentication flows (Login, Register, AWS Cognito setup)
- `dashboard/` - Main landing view after login
- `onboarding/` - Welcome screens and initial setup for new users
- `pantry/` - Inventory list, item details, and camera/scanning logic
- `planner/` - Shopping lists and meal planning
- `profile/` - User settings and preferences
- `recipes/` - Recipe feed, detailed instructions, and "Cook Now" logic
- `splash/` - Initial app load screen

## Getting Started

### Prerequisites

- Flutter SDK (>=3.3.0)
- Dart SDK
- Android Studio / Xcode (for emulation/building)
- API Keys: You will need a valid Spoonacular API key and an AWS backend environment configured.

### Environment Setup

Create a `.env` file in the root directory and add the necessary configuration variables:

```env
# Example .env configuration
SPOONACULAR_API_KEY=your_api_key_here
API_BASE_URL=your_backend_url_here
```

### Installation

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Generate required Riverpod and JSON serialization files:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Generating Launcher Icons

To update or generate launcher icons, ensure your asset image is placed at `assets/images/app-logo.png` and run:

```bash
flutter pub run flutter_launcher_icons
```
