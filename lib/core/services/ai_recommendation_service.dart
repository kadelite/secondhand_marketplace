import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/user.dart';

enum RecommendationType {
  personalizedFeed,
  similarProducts,
  trending,
  categoryBased,
  locationBased,
  priceRange,
  collaborative,
  contentBased,
}

enum SearchIntent {
  browse,
  specific,
  comparative,
  inspirational,
  urgent,
}

class AIRecommendationService {
  static final AIRecommendationService _instance = AIRecommendationService._internal();
  factory AIRecommendationService() => _instance;
  AIRecommendationService._internal();

  // User behavior tracking
  final Map<String, UserBehaviorProfile> _userProfiles = {};
  final List<SearchQuery> _searchHistory = [];
  final Map<String, List<ProductInteraction>> _productInteractions = {};
  
  // ML Model placeholders (in production, these would be actual ML models)
  final Map<String, double> _categoryWeights = {};
  final Map<String, Map<String, double>> _userPreferences = {};
  final Map<String, List<String>> _productEmbeddings = {};

  // Trending and popular products cache
  final Map<String, List<Product>> _trendingCache = {};
  DateTime? _lastTrendingUpdate;

  // Initialize the AI service
  Future<void> initialize() async {
    await _loadUserProfiles();
    await _loadModelWeights();
    await _initializeProductEmbeddings();
    await _updateTrendingProducts();
  }

  // Main Recommendation Engine
  Future<List<Product>> getPersonalizedRecommendations({
    required String userId,
    int limit = 20,
    List<String>? excludeProductIds,
  }) async {
    final userProfile = await _getUserBehaviorProfile(userId);
    final recommendations = <ScoredProduct>[];

    // Content-based filtering
    final contentBased = await _getContentBasedRecommendations(
      userProfile, 
      limit: limit ~/ 4,
      excludeIds: excludeProductIds,
    );
    recommendations.addAll(contentBased);

    // Collaborative filtering
    final collaborative = await _getCollaborativeRecommendations(
      userId, 
      limit: limit ~/ 4,
      excludeIds: excludeProductIds,
    );
    recommendations.addAll(collaborative);

    // Trending products with personalization
    final trending = await _getTrendingRecommendations(
      userProfile, 
      limit: limit ~/ 4,
      excludeIds: excludeProductIds,
    );
    recommendations.addAll(trending);

    // Location-based recommendations
    final locationBased = await _getLocationBasedRecommendations(
      userId, 
      limit: limit ~/ 4,
      excludeIds: excludeProductIds,
    );
    recommendations.addAll(locationBased);

    // Sort by combined score and return top products
    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(limit).map((sp) => sp.product).toList();
  }

  // Smart Search with AI
  Future<SearchResult> smartSearch({
    required String query,
    required String userId,
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
    String? location,
    ProductCondition? condition,
    int limit = 50,
  }) async {
    final searchQuery = SearchQuery(
      query: query,
      userId: userId,
      timestamp: DateTime.now(),
      categories: categories,
      priceRange: minPrice != null && maxPrice != null 
          ? PriceRange(min: minPrice, max: maxPrice) 
          : null,
      location: location,
      condition: condition,
    );

    _searchHistory.add(searchQuery);

    // Analyze search intent
    final intent = _analyzeSearchIntent(query);
    
    // Get base search results
    final baseResults = await _performBaseSearch(searchQuery);
    
    // Apply AI ranking
    final rankedResults = await _applyAIRanking(
      baseResults, 
      searchQuery, 
      intent,
      userId,
    );

    // Generate search suggestions
    final suggestions = await _generateSearchSuggestions(query, userId);

    // Track search interaction
    await _trackSearchInteraction(searchQuery, rankedResults.length);

    return SearchResult(
      query: query,
      products: rankedResults.take(limit).toList(),
      totalCount: rankedResults.length,
      intent: intent,
      suggestions: suggestions,
      processingTime: DateTime.now().difference(searchQuery.timestamp),
    );
  }

  // Similar Products Recommendation
  Future<List<Product>> getSimilarProducts({
    required String productId,
    required String userId,
    int limit = 10,
  }) async {
    final product = await _getProduct(productId);
    if (product == null) return [];

    final similarities = <ScoredProduct>[];

    // Find products in same category
    final categoryProducts = await _getProductsByCategory(
      product.categoryId,
      excludeId: productId,
    );

    for (final candidateProduct in categoryProducts) {
      final similarity = _calculateProductSimilarity(product, candidateProduct);
      if (similarity > 0.3) {
        similarities.add(ScoredProduct(candidateProduct, similarity));
      }
    }

    // Sort by similarity and return top results
    similarities.sort((a, b) => b.score.compareTo(a.score));
    
    // Track similarity request
    await _trackProductInteraction(userId, productId, InteractionType.viewedSimilar);
    
    return similarities.take(limit).map((sp) => sp.product).toList();
  }

  // Trending Products with AI
  Future<List<Product>> getTrendingProducts({
    String? categoryId,
    String? location,
    int limit = 20,
  }) async {
    await _updateTrendingProducts();
    
    String cacheKey = 'global';
    if (categoryId != null) cacheKey += '_$categoryId';
    if (location != null) cacheKey += '_$location';

    final trending = _trendingCache[cacheKey] ?? [];
    return trending.take(limit).toList();
  }

  // User Behavior Tracking
  Future<void> trackProductView({
    required String userId,
    required String productId,
    Duration? viewDuration,
  }) async {
    await _trackProductInteraction(
      userId, 
      productId, 
      InteractionType.viewed,
      metadata: {'duration': viewDuration?.inSeconds ?? 0},
    );
  }

  Future<void> trackProductLike({
    required String userId,
    required String productId,
  }) async {
    await _trackProductInteraction(userId, productId, InteractionType.liked);
  }

  Future<void> trackProductShare({
    required String userId,
    required String productId,
    required String platform,
  }) async {
    await _trackProductInteraction(
      userId, 
      productId, 
      InteractionType.shared,
      metadata: {'platform': platform},
    );
  }

  Future<void> trackPurchase({
    required String userId,
    required String productId,
    required double amount,
  }) async {
    await _trackProductInteraction(
      userId, 
      productId, 
      InteractionType.purchased,
      metadata: {'amount': amount},
    );
  }

  // Category-based Recommendations
  Future<List<Product>> getCategoryRecommendations({
    required String userId,
    required String categoryId,
    int limit = 15,
  }) async {
    final userProfile = await _getUserBehaviorProfile(userId);
    final categoryProducts = await _getProductsByCategory(categoryId);
    
    final scored = categoryProducts.map((product) {
      final score = _calculatePersonalizedScore(product, userProfile);
      return ScoredProduct(product, score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((sp) => sp.product).toList();
  }

  // Price Prediction
  Future<PricePrediction> predictOptimalPrice({
    required Product product,
    String? targetLocation,
  }) async {
    final similarProducts = await _findSimilarProductsForPricing(product);
    
    if (similarProducts.isEmpty) {
      return PricePrediction(
        suggestedPrice: product.price,
        confidence: 0.3,
        priceRange: PriceRange(
          min: product.price * 0.8,
          max: product.price * 1.2,
        ),
        marketInsights: ['Insufficient market data for accurate prediction'],
      );
    }

    final prices = similarProducts.map((p) => p.price).toList();
    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
    final stdDev = _calculateStandardDeviation(prices);
    
    final insights = <String>[];
    
    if (product.price > avgPrice + stdDev) {
      insights.add('Price is above market average - consider reducing for faster sale');
    } else if (product.price < avgPrice - stdDev) {
      insights.add('Price is below market average - you may be undervaluing');
    } else {
      insights.add('Price is within market range');
    }

    // Seasonal adjustments
    final seasonalFactor = _getSeasonalPricingFactor(product.categoryId);
    final adjustedPrice = avgPrice * seasonalFactor;

    return PricePrediction(
      suggestedPrice: adjustedPrice,
      confidence: min(0.9, similarProducts.length / 20.0),
      priceRange: PriceRange(
        min: adjustedPrice * 0.9,
        max: adjustedPrice * 1.1,
      ),
      marketInsights: insights,
    );
  }

  // Market Insights
  Future<MarketInsights> getMarketInsights({
    required String categoryId,
    String? location,
  }) async {
    final products = await _getProductsByCategory(categoryId);
    final recentProducts = products.where(
      (p) => DateTime.now().difference(p.createdAt).inDays <= 30
    ).toList();

    final prices = recentProducts.map((p) => p.price).toList();
    final avgPrice = prices.isNotEmpty 
        ? prices.reduce((a, b) => a + b) / prices.length 
        : 0.0;

    // Calculate trends
    final oldProducts = products.where(
      (p) => DateTime.now().difference(p.createdAt).inDays > 30 &&
             DateTime.now().difference(p.createdAt).inDays <= 60
    ).toList();

    final oldPrices = oldProducts.map((p) => p.price).toList();
    final oldAvgPrice = oldPrices.isNotEmpty 
        ? oldPrices.reduce((a, b) => a + b) / oldPrices.length 
        : avgPrice;

    final priceTrend = avgPrice != 0 
        ? ((avgPrice - oldAvgPrice) / oldAvgPrice) * 100 
        : 0.0;

    return MarketInsights(
      categoryId: categoryId,
      averagePrice: avgPrice,
      priceTrend: priceTrend,
      totalListings: recentProducts.length,
      demandScore: _calculateDemandScore(recentProducts),
      seasonalFactor: _getSeasonalPricingFactor(categoryId),
      topConditions: _getTopConditions(recentProducts),
      suggestedKeywords: _extractTrendingKeywords(recentProducts),
    );
  }

  // Private Helper Methods

  Future<UserBehaviorProfile> _getUserBehaviorProfile(String userId) async {
    if (_userProfiles.containsKey(userId)) {
      return _userProfiles[userId]!;
    }

    final profile = UserBehaviorProfile(
      userId: userId,
      categoryPreferences: {},
      priceRangePreferences: {},
      locationPreferences: [],
      timeOfDayActivity: {},
      seasonalPatterns: {},
      interactionHistory: [],
    );

    _userProfiles[userId] = profile;
    return profile;
  }

  Future<List<ScoredProduct>> _getContentBasedRecommendations(
    UserBehaviorProfile profile, {
    required int limit,
    List<String>? excludeIds,
  }) async {
    final recommendations = <ScoredProduct>[];
    
    // Get products matching user's category preferences
    for (final categoryEntry in profile.categoryPreferences.entries) {
      if (categoryEntry.value > 0.1) { // Only categories with sufficient interest
        final categoryProducts = await _getProductsByCategory(categoryEntry.key);
        
        for (final product in categoryProducts) {
          if (excludeIds?.contains(product.id) == true) continue;
          
          final score = _calculatePersonalizedScore(product, profile);
          recommendations.add(ScoredProduct(product, score));
        }
      }
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(limit).toList();
  }

  Future<List<ScoredProduct>> _getCollaborativeRecommendations(
    String userId, {
    required int limit,
    List<String>? excludeIds,
  }) async {
    // Find users with similar behavior patterns
    final similarUsers = await _findSimilarUsers(userId);
    final recommendations = <ScoredProduct>[];

    for (final similarUser in similarUsers) {
      final theirInteractions = _productInteractions[similarUser.userId] ?? [];
      
      for (final interaction in theirInteractions) {
        if (excludeIds?.contains(interaction.productId) == true) continue;
        if (interaction.type == InteractionType.liked || 
            interaction.type == InteractionType.purchased) {
          
          final product = await _getProduct(interaction.productId);
          if (product != null) {
            final score = similarUser.similarity * _getInteractionWeight(interaction.type);
            recommendations.add(ScoredProduct(product, score));
          }
        }
      }
    }

    // Aggregate scores for duplicate products
    final productScores = <String, double>{};
    for (final rec in recommendations) {
      productScores[rec.product.id] = 
          (productScores[rec.product.id] ?? 0) + rec.score;
    }

    final uniqueRecommendations = productScores.entries
        .map((entry) async => ScoredProduct(
              await _getProduct(entry.key),
              entry.value,
            ))
        .where((futureProduct) => futureProduct != null)
        .map((futureProduct) => futureProduct as ScoredProduct)
        .toList();

    return uniqueRecommendations.take(limit).toList();
  }

  Future<List<ScoredProduct>> _getTrendingRecommendations(
    UserBehaviorProfile profile, {
    required int limit,
    List<String>? excludeIds,
  }) async {
    await _updateTrendingProducts();
    
    final trending = _trendingCache['global'] ?? [];
    final personalizedTrending = <ScoredProduct>[];

    for (final product in trending) {
      if (excludeIds?.contains(product.id) == true) continue;
      
      final personalizationScore = _calculatePersonalizedScore(product, profile);
      final trendingScore = 0.8; // Base trending score
      final combinedScore = (trendingScore + personalizationScore) / 2;
      
      personalizedTrending.add(ScoredProduct(product, combinedScore));
    }

    return personalizedTrending.take(limit).toList();
  }

  Future<List<ScoredProduct>> _getLocationBasedRecommendations(
    String userId, {
    required int limit,
    List<String>? excludeIds,
  }) async {
    final userLocation = await _getUserLocation(userId);
    if (userLocation == null) return [];

    final nearbyProducts = await _getProductsByLocation(userLocation, radius: 50);
    final recommendations = <ScoredProduct>[];

    for (final product in nearbyProducts) {
      if (excludeIds?.contains(product.id) == true) continue;
      
      final distance = _calculateDistance(userLocation, product.location);
      final proximityScore = max(0.0, (50 - distance) / 50); // Closer = higher score
      
      recommendations.add(ScoredProduct(product, proximityScore));
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(limit).toList();
  }

  SearchIntent _analyzeSearchIntent(String query) {
    final lowercaseQuery = query.toLowerCase();
    
    // Urgent intent indicators
    if (lowercaseQuery.contains(RegExp(r'\b(urgent|asap|today|now|emergency)\b'))) {
      return SearchIntent.urgent;
    }
    
    // Comparative intent indicators
    if (lowercaseQuery.contains(RegExp(r'\b(vs|versus|compare|better|best|top)\b'))) {
      return SearchIntent.comparative;
    }
    
    // Specific intent indicators
    if (lowercaseQuery.contains(RegExp(r'\b(model|serial|exact|specific)\b')) ||
        query.contains(RegExp(r'\d{3,}'))) {
      return SearchIntent.specific;
    }
    
    // Inspirational intent indicators
    if (lowercaseQuery.contains(RegExp(r'\b(ideas|inspiration|style|cool|unique)\b'))) {
      return SearchIntent.inspirational;
    }
    
    return SearchIntent.browse;
  }

  double _calculateProductSimilarity(Product product1, Product product2) {
    double similarity = 0.0;
    
    // Category similarity (highest weight)
    if (product1.categoryId == product2.categoryId) {
      similarity += 0.4;
    }
    
    // Price similarity
    final priceDiff = (product1.price - product2.price).abs();
    final avgPrice = (product1.price + product2.price) / 2;
    if (avgPrice > 0) {
      final priceSimiliarity = max(0.0, 1 - (priceDiff / avgPrice));
      similarity += priceSimiliarity * 0.2;
    }
    
    // Condition similarity
    if (product1.condition == product2.condition) {
      similarity += 0.1;
    }
    
    // Title similarity (using simple word matching)
    final words1 = product1.title.toLowerCase().split(' ');
    final words2 = product2.title.toLowerCase().split(' ');
    final commonWords = words1.where((word) => words2.contains(word)).length;
    final titleSimilarity = commonWords / max(words1.length, words2.length);
    similarity += titleSimilarity * 0.2;
    
    // Location proximity
    if (product1.location != null && product2.location != null) {
      // Simplified location similarity
      if (product1.location == product2.location) {
        similarity += 0.1;
      }
    }
    
    return similarity.clamp(0.0, 1.0);
  }

  double _calculatePersonalizedScore(Product product, UserBehaviorProfile profile) {
    double score = 0.0;
    
    // Category preference
    final categoryPreference = profile.categoryPreferences[product.categoryId] ?? 0.0;
    score += categoryPreference * 0.4;
    
    // Price range preference
    for (final priceRangeEntry in profile.priceRangePreferences.entries) {
      final range = priceRangeEntry.key;
      if (product.price >= range.min && product.price <= range.max) {
        score += priceRangeEntry.value * 0.2;
        break;
      }
    }
    
    // Recency bonus
    final daysSincePosted = DateTime.now().difference(product.createdAt).inDays;
    final recencyScore = max(0.0, (30 - daysSincePosted) / 30);
    score += recencyScore * 0.2;
    
    // Popularity bonus
    final popularityScore = min(1.0, (product.viewCount + product.likeCount) / 100.0);
    score += popularityScore * 0.2;
    
    return score.clamp(0.0, 1.0);
  }

  // Placeholder methods for data access
  Future<Product?> _getProduct(String productId) async {
    // Implement product fetching logic
    return null;
  }

  Future<List<Product>> _getProductsByCategory(String categoryId, {String? excludeId}) async {
    // Implement category-based product fetching
    return [];
  }

  Future<List<Product>> _getProductsByLocation(String location, {double radius = 25}) async {
    // Implement location-based product fetching
    return [];
  }

  Future<String?> _getUserLocation(String userId) async {
    // Implement user location fetching
    return null;
  }

  Future<List<Product>> _performBaseSearch(SearchQuery query) async {
    // Implement base search logic
    return [];
  }

  Future<List<Product>> _applyAIRanking(
    List<Product> products,
    SearchQuery query,
    SearchIntent intent,
    String userId,
  ) async {
    // Implement AI-based ranking
    return products;
  }

  Future<List<String>> _generateSearchSuggestions(String query, String userId) async {
    // Implement search suggestion generation
    return [];
  }

  // More placeholder methods...
  Future<void> _loadUserProfiles() async {}
  Future<void> _loadModelWeights() async {}
  Future<void> _initializeProductEmbeddings() async {}
  Future<void> _updateTrendingProducts() async {}
  Future<void> _trackProductInteraction(String userId, String productId, InteractionType type, {Map<String, dynamic>? metadata}) async {}
  Future<void> _trackSearchInteraction(SearchQuery query, int resultCount) async {}
  Future<List<SimilarUser>> _findSimilarUsers(String userId) async => [];
  Future<List<Product>> _findSimilarProductsForPricing(Product product) async => [];
  double _calculateDistance(String? location1, String? location2) => 0.0;
  double _getInteractionWeight(InteractionType type) => 1.0;
  double _calculateStandardDeviation(List<double> values) => 0.0;
  double _getSeasonalPricingFactor(String categoryId) => 1.0;
  double _calculateDemandScore(List<Product> products) => 0.5;
  List<ProductCondition> _getTopConditions(List<Product> products) => [];
  List<String> _extractTrendingKeywords(List<Product> products) => [];
}

// Data Classes
class ScoredProduct {
  final Product? product;
  final double score;

  ScoredProduct(this.product, this.score);
}

class UserBehaviorProfile {
  final String userId;
  final Map<String, double> categoryPreferences;
  final Map<PriceRange, double> priceRangePreferences;
  final List<String> locationPreferences;
  final Map<int, double> timeOfDayActivity; // Hour -> Activity level
  final Map<String, double> seasonalPatterns;
  final List<ProductInteraction> interactionHistory;

  UserBehaviorProfile({
    required this.userId,
    required this.categoryPreferences,
    required this.priceRangePreferences,
    required this.locationPreferences,
    required this.timeOfDayActivity,
    required this.seasonalPatterns,
    required this.interactionHistory,
  });
}

class SearchQuery {
  final String query;
  final String userId;
  final DateTime timestamp;
  final List<String>? categories;
  final PriceRange? priceRange;
  final String? location;
  final ProductCondition? condition;

  SearchQuery({
    required this.query,
    required this.userId,
    required this.timestamp,
    this.categories,
    this.priceRange,
    this.location,
    this.condition,
  });
}

class SearchResult {
  final String query;
  final List<Product> products;
  final int totalCount;
  final SearchIntent intent;
  final List<String> suggestions;
  final Duration processingTime;

  SearchResult({
    required this.query,
    required this.products,
    required this.totalCount,
    required this.intent,
    required this.suggestions,
    required this.processingTime,
  });
}

class ProductInteraction {
  final String productId;
  final InteractionType type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ProductInteraction({
    required this.productId,
    required this.type,
    required this.timestamp,
    this.metadata,
  });
}

class PriceRange {
  final double min;
  final double max;

  PriceRange({required this.min, required this.max});
  
  @override
  bool operator ==(Object other) {
    if (other is! PriceRange) return false;
    return min == other.min && max == other.max;
  }
  
  @override
  int get hashCode => Object.hash(min, max);
}

class PricePrediction {
  final double suggestedPrice;
  final double confidence;
  final PriceRange priceRange;
  final List<String> marketInsights;

  PricePrediction({
    required this.suggestedPrice,
    required this.confidence,
    required this.priceRange,
    required this.marketInsights,
  });
}

class MarketInsights {
  final String categoryId;
  final double averagePrice;
  final double priceTrend; // Percentage change
  final int totalListings;
  final double demandScore;
  final double seasonalFactor;
  final List<ProductCondition> topConditions;
  final List<String> suggestedKeywords;

  MarketInsights({
    required this.categoryId,
    required this.averagePrice,
    required this.priceTrend,
    required this.totalListings,
    required this.demandScore,
    required this.seasonalFactor,
    required this.topConditions,
    required this.suggestedKeywords,
  });
}

class SimilarUser {
  final String userId;
  final double similarity;

  SimilarUser({required this.userId, required this.similarity});
}

enum InteractionType {
  viewed,
  liked,
  shared,
  purchased,
  contacted,
  saved,
  viewedSimilar,
}