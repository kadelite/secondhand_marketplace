# Secondhand Marketplace Services Documentation

This directory contains all the core services for the secondhand marketplace Flutter application. Each service is designed with a singleton pattern for efficient resource management and provides comprehensive functionality for different aspects of the application.

## Services Overview

### 1. Push Notification Service (`push_notification_service.dart`)

**Purpose**: Handle Firebase Cloud Messaging and local notifications

**Key Features**:
- Firebase Cloud Messaging integration
- Local notifications support
- Notification categories and priorities
- Topic-based subscriptions
- Notification interaction handling
- Custom notification sounds and icons
- Background message handling

**Main Methods**:
- `initialize()` - Set up FCM and local notifications
- `showLocalNotification()` - Display local notifications
- `subscribeToTopic()` - Subscribe to FCM topics
- `getToken()` - Get FCM registration token

### 2. AI Recommendation Service (`ai_recommendation_service.dart`)

**Purpose**: Provide AI-powered recommendations and smart search functionality

**Key Features**:
- Personalized product recommendations
- Similar product suggestions
- Smart search with intent analysis
- Category-based recommendations
- Location-based suggestions
- Price prediction algorithms
- Market trend analysis
- User behavior tracking
- Machine learning model integration

**Main Methods**:
- `getPersonalizedRecommendations()` - Get user-specific recommendations
- `getSimilarProducts()` - Find similar items
- `smartSearch()` - AI-powered search with intent detection
- `getPricePrediction()` - Predict optimal pricing
- `getMarketInsights()` - Analyze market trends

### 3. Social Community Service (`social_community_service.dart`)

**Purpose**: Enable social features and community engagement

**Key Features**:
- Community forums with categories
- Social sharing (products, profiles)
- Referral program management
- Badge and achievement system
- User following/followers
- Content moderation and reporting
- Polls and community events
- Gamification elements
- User profile management

**Main Methods**:
- `createForumPost()` - Create discussion posts
- `shareProduct()` - Share items on social platforms
- `createReferral()` - Generate referral links
- `awardBadge()` - Award user achievements
- `followUser()` - Follow other users

### 4. Performance Monitoring Service (`performance_monitoring_service.dart`)

**Purpose**: Track app performance, analytics, and crash reporting

**Key Features**:
- Real-time analytics tracking
- Performance metric collection
- Crash reporting and error handling
- Session management
- User behavior analytics
- Custom event tracking
- Memory usage monitoring
- A/B testing support
- Revenue tracking
- Funnel analysis

**Main Methods**:
- `trackEvent()` - Log custom events
- `trackScreenView()` - Track screen navigation
- `startPerformanceTimer()` - Monitor performance metrics
- `trackCrash()` - Report crashes and errors
- `setUserId()` - Associate events with users

### 5. Data Synchronization Service (`data_sync_service.dart`)

**Purpose**: Handle offline-online data synchronization

**Key Features**:
- Offline-first data management
- Automatic sync when online
- Conflict resolution strategies
- Priority-based sync queue
- Connectivity monitoring
- Retry mechanism for failed syncs
- Manual sync control
- Sync statistics and monitoring
- Configurable sync intervals

**Main Methods**:
- `addSyncItem()` - Queue data for synchronization
- `syncNow()` - Force immediate synchronization
- `setAutoSyncEnabled()` - Configure automatic sync
- `resolveConflict()` - Handle data conflicts
- `getSyncStats()` - Get synchronization statistics

## Service Architecture

### Common Patterns

All services follow these architectural patterns:

1. **Singleton Pattern**: Each service uses a singleton instance for memory efficiency
2. **Stream-based Updates**: Services use streams for real-time updates
3. **Persistent Storage**: Configuration and data persistence using SharedPreferences
4. **Error Handling**: Comprehensive error handling and logging
5. **Configuration**: Flexible configuration options for each service
6. **Initialization**: Proper initialization methods for setup

### Service Dependencies

```dart
// Initialize all services in your main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await PushNotificationService().initialize();
  await AIRecommendationService().initialize();
  await SocialCommunityService().initialize();
  await PerformanceMonitoringService().initialize();
  await DataSyncService().initialize();
  
  runApp(MyApp());
}
```

### Integration Example

```dart
// Example: Track user action and sync data
class ProductService {
  Future<void> createProduct(Product product) async {
    // Create product locally
    final productData = product.toJson();
    
    // Track the action for analytics
    await PerformanceMonitoringService().trackUserAction('product_created', {
      'category': product.category,
      'price': product.price.toString(),
    });
    
    // Queue for synchronization
    await DataSyncService().addSyncItem(
      id: product.id,
      entity: 'products',
      operation: SyncOperation.create,
      data: productData,
      priority: SyncPriority.high,
    );
    
    // Get AI recommendations for similar products
    final similar = await AIRecommendationService().getSimilarProducts(
      category: product.category,
      priceRange: PriceRange(
        min: product.price * 0.8,
        max: product.price * 1.2,
      ),
    );
    
    // Award badge if it's user's first product
    await SocialCommunityService().trackUserActivity(
      userId: product.sellerId,
      activity: 'product_created',
      metadata: {'product_id': product.id},
    );
  }
}
```

## Configuration

### Environment Setup

Create a configuration file to manage service settings:

```dart
// lib/core/config/service_config.dart
class ServiceConfig {
  // Push Notifications
  static const bool pushNotificationsEnabled = true;
  
  // AI Recommendations
  static const bool aiRecommendationsEnabled = true;
  static const Duration recommendationCacheTimeout = Duration(hours: 1);
  
  // Analytics
  static const bool analyticsEnabled = true;
  static const Duration analyticsFlushInterval = Duration(minutes: 5);
  
  // Data Sync
  static const bool autoSyncEnabled = true;
  static const Duration syncInterval = Duration(minutes: 3);
  static const bool syncOnlyOnWifi = false;
  
  // Social Features
  static const bool socialFeaturesEnabled = true;
  static const bool referralProgramEnabled = true;
}
```

### Required Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  # Core
  flutter:
    sdk: flutter
  
  # Notifications
  firebase_messaging: ^14.0.0
  flutter_local_notifications: ^16.0.0
  
  # Storage and Networking
  shared_preferences: ^2.2.0
  connectivity_plus: ^4.0.0
  
  # Utilities
  uuid: ^4.0.0
  device_info_plus: ^9.0.0
  package_info_plus: ^4.0.0
  
  # Social Sharing
  share_plus: ^7.0.0
```

## Security Considerations

1. **Data Encryption**: Sensitive data should be encrypted before storage
2. **API Keys**: Store API keys securely using environment variables
3. **User Privacy**: Respect user privacy settings for analytics and tracking
4. **Network Security**: Use HTTPS for all network communications
5. **Input Validation**: Validate all user inputs and API responses

## Testing

Each service includes methods for testing and debugging:

```dart
// Enable debug mode for detailed logging
await PerformanceMonitoringService().initialize(
  enabled: true,
  crashReporting: true,
  performanceTracking: true,
);

// Test sync functionality
final syncStats = DataSyncService().getSyncStats();
print('Sync Status: ${syncStats.syncStatus}');
print('Pending Items: ${syncStats.pendingItems}');
```

## Performance Optimization

1. **Lazy Loading**: Services are initialized only when needed
2. **Caching**: Intelligent caching strategies to reduce API calls
3. **Background Processing**: Heavy operations run in background isolates
4. **Memory Management**: Proper disposal of resources and streams
5. **Network Optimization**: Efficient data synchronization and batch operations

## Future Enhancements

1. **Machine Learning**: Enhanced AI recommendations with on-device ML
2. **Real-time Features**: WebSocket integration for real-time updates
3. **Advanced Analytics**: More sophisticated user behavior analysis
4. **Blockchain Integration**: Decentralized features for trust and verification
5. **AR/VR Support**: Augmented reality product visualization

## Support and Maintenance

- Regular updates for security patches
- Performance monitoring and optimization
- User feedback integration
- Continuous improvement based on analytics data
- Documentation updates for new features

For detailed API documentation and examples, refer to the individual service files.