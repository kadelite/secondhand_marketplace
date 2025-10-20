# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a Flutter-based e-commerce platform for a secondhand goods marketplace. The application uses Clean Architecture principles with BLoC state management, Firebase integration, and modern Flutter development practices.

## Development Commands

### Core Flutter Commands
- **Install dependencies**: `flutter pub get`
- **Run app (development)**: `flutter run`
- **Run app (specific platform)**: `flutter run -d windows` / `flutter run -d android` / `flutter run -d ios`
- **Build for release**: `flutter build apk` (Android) / `flutter build ios` (iOS) / `flutter build windows` (Windows)
- **Clean build**: `flutter clean && flutter pub get`

### Code Generation
- **Generate models/serialization**: `flutter packages pub run build_runner build`
- **Generate models (watch mode)**: `flutter packages pub run build_runner watch`
- **Clean generated files**: `flutter packages pub run build_runner clean`

### Testing & Quality
- **Run all tests**: `flutter test`
- **Run specific test**: `flutter test test/widget_test.dart`
- **Analyze code**: `flutter analyze`
- **Format code**: `dart format lib/ test/`

### Platform-Specific Commands
- **Run on specific device**: `flutter devices` (list) then `flutter run -d <device_id>`

## Architecture Overview

### Clean Architecture Structure
The project follows Clean Architecture with three main layers:

1. **Domain Layer** (`lib/domain/`):
   - Contains business entities, repository contracts, and use cases
   - Independent of external frameworks and data sources
   - Key entities: `Product`, `User`, `Category`

2. **Data Layer** (`lib/data/`):
   - Implements domain repositories
   - Handles data sources (API, local storage)
   - Contains data models with JSON serialization

3. **Presentation Layer** (`lib/presentation/`):
   - UI components, pages, and BLoC state management
   - Themed with custom `AppTheme` supporting light/dark modes

### Key Technologies
- **State Management**: flutter_bloc with Equatable for immutable state
- **Navigation**: go_router with route guards and authentication checks
- **Backend**: Firebase (Auth, Firestore, Messaging)
- **Local Storage**: Hive for caching, SharedPreferences for settings
- **Networking**: Dio with Retrofit for type-safe API calls
- **Authentication**: JWT tokens with biometric authentication support

### Core Features
- User authentication with email/password and biometric options
- Product browsing, searching, and filtering
- Real-time messaging between buyers and sellers
- Location-based product discovery
- Image upload and caching
- Push notifications

#### Shipping & Transaction Handling
- Generation of shipping labels (integrate with courier APIs: FedEx, DHL, UPS)
- In-app shipping status updates and tracking
- Escrow system holding payment until buyer confirms satisfactory receipt

#### Payment Integration
- Accept card payments (Visa, MasterCard, etc.), PayPal, Apple Pay, Google Pay
- Secure payment gateways: Stripe/PayPal with PCI DSS compliance and HTTPS
- Support in-app payments and payout to sellers' bank/PayPal accounts
- Fraud protection: monitor transactions, flag suspicious activity, enforce payment holds for dispute cases

#### Returns & Dispute Resolution
- Allow buyer-initiated disputes for "not as described" items
- Seller-set return policy for other cases
- Automated and manual resolution workflows

#### Trust & Safety
- Buyer protection policies and guarantees
- Item verification/inspection options
- Encrypted messaging/chat (end-to-end if possible)
- Security dashboard and reporting mechanism for users

### Navigation Structure
The app uses a shell-based navigation with bottom tabs:
- **Home**: Product feed and featured listings
- **Search**: Advanced product search and filtering
- **Messages**: Chat conversations with other users
- **Profile**: User account management

Full-screen routes exist for:
- Product details (`/product/:productId`)
- Create product (`/create-product`)
- Chat conversations (`/chat/:chatId`)

### State Management Patterns
- **BLoC Pattern**: Used throughout for predictable state management
- **Repository Pattern**: Abstracts data sources in domain layer
- **Use Cases**: Encapsulate business logic operations
- **Event-driven**: UI triggers events, BLoCs emit states

### Data Models
- Products support multiple images, condition ratings, and geolocation
- User profiles with authentication and seller ratings
- Categories for product organization
- Message threading for buyer-seller communication

### Development Notes
- Uses Material 3 design system with custom theming
- Supports multi-platform deployment (Android, iOS, Windows, Web)
- Implements JWT-based authentication with automatic token refresh
- Uses Hive for offline-first product caching
- Image handling with compression and caching via `cached_network_image`