import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../bloc/seller/enterprise_seller_bloc.dart';
import '../../widgets/seller/bulk_upload_widget.dart';
import '../../widgets/seller/seller_analytics_widget.dart';
import '../../widgets/seller/inventory_management_widget.dart';
import '../../widgets/seller/performance_insights_widget.dart';
import '../../widgets/seller/sales_forecast_widget.dart';

class EnterpriseSellerDashboard extends StatefulWidget {
  final String sellerId;

  const EnterpriseSellerDashboard({
    super.key,
    required this.sellerId,
  });

  @override
  State<EnterpriseSellerDashboard> createState() => _EnterpriseSellerDashboardState();
}

class _EnterpriseSellerDashboardState extends State<EnterpriseSellerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<EnterpriseTab> _tabs = [
    EnterpriseTab(
      title: 'Overview',
      icon: Icons.dashboard_outlined,
      widget: const SellerOverviewTab(),
    ),
    EnterpriseTab(
      title: 'Inventory',
      icon: Icons.inventory_2_outlined,
      widget: const InventoryManagementTab(),
    ),
    EnterpriseTab(
      title: 'Analytics',
      icon: Icons.analytics_outlined,
      widget: const SellerAnalyticsTab(),
    ),
    EnterpriseTab(
      title: 'Bulk Tools',
      icon: Icons.cloud_upload_outlined,
      widget: const BulkToolsTab(),
    ),
    EnterpriseTab(
      title: 'Performance',
      icon: Icons.trending_up_outlined,
      widget: const PerformanceTab(),
    ),
    EnterpriseTab(
      title: 'Marketing',
      icon: Icons.campaign_outlined,
      widget: const MarketingTab(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    // Load initial enterprise seller data
    context.read<EnterpriseSellerBloc>().add(
      LoadEnterpriseSellerDashboardEvent(widget.sellerId),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.business, size: 28),
            const SizedBox(width: 8),
            const Text('Enterprise Dashboard'),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          // Quick Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleQuickAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'bulk_upload',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Bulk Upload'),
                ),
              ),
              const PopupMenuItem(
                value: 'export_data',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Data'),
                ),
              ),
              const PopupMenuItem(
                value: 'performance_report',
                child: ListTile(
                  leading: Icon(Icons.assessment),
                  title: Text('Performance Report'),
                ),
              ),
              const PopupMenuItem(
                value: 'api_settings',
                child: ListTile(
                  leading: Icon(Icons.api),
                  title: Text('API Settings'),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((tab) => Tab(
            icon: Icon(tab.icon),
            text: tab.title,
          )).toList(),
        ),
      ),
      body: BlocConsumer<EnterpriseSellerBloc, EnterpriseSellerState>(
        listener: (context, state) {
          if (state is EnterpriseSellerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is EnterpriseSellerLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) => tab.widget).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickActions,
        icon: const Icon(Icons.add_business),
        label: const Text('Quick Action'),
      ),
    );
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case 'bulk_upload':
        _tabController.animateTo(3); // Go to Bulk Tools tab
        break;
      case 'export_data':
        _exportSellerData();
        break;
      case 'performance_report':
        _generatePerformanceReport();
        break;
      case 'api_settings':
        _showAPISettings();
        break;
    }
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              children: [
                _buildQuickActionButton(
                  icon: Icons.upload_file,
                  label: 'Bulk Upload',
                  onTap: () {
                    Navigator.pop(context);
                    _handleQuickAction('bulk_upload');
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.analytics,
                  label: 'Analytics',
                  onTap: () {
                    Navigator.pop(context);
                    _tabController.animateTo(2);
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.inventory,
                  label: 'Inventory',
                  onTap: () {
                    Navigator.pop(context);
                    _tabController.animateTo(1);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _exportSellerData() {
    context.read<EnterpriseSellerBloc>().add(
      ExportSellerDataEvent(widget.sellerId),
    );
  }

  void _generatePerformanceReport() {
    context.read<EnterpriseSellerBloc>().add(
      GeneratePerformanceReportEvent(widget.sellerId),
    );
  }

  void _showAPISettings() {
    Navigator.of(context).pushNamed('/seller/api-settings');
  }
}

// Tab Content Widgets

class SellerOverviewTab extends StatelessWidget {
  const SellerOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Performance Indicators
          Row(
            children: [
              Text(
                'Performance Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Chip(label: Text('Last 30 days')),
            ],
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: const [
              KPICard(
                title: 'Total Revenue',
                value: '\$24,567',
                change: '+12.5%',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
              KPICard(
                title: 'Units Sold',
                value: '1,247',
                change: '+8.3%',
                icon: Icons.shopping_cart,
                color: Colors.blue,
              ),
              KPICard(
                title: 'Active Listings',
                value: '456',
                change: '+15.2%',
                icon: Icons.inventory,
                color: Colors.orange,
              ),
              KPICard(
                title: 'Conversion Rate',
                value: '3.8%',
                change: '+0.5%',
                icon: Icons.trending_up,
                color: Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Recent Activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Sales Activity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const RecentSalesWidget(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Insights
          const PerformanceInsightsWidget(),
        ],
      ),
    );
  }
}

class InventoryManagementTab extends StatelessWidget {
  const InventoryManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: InventoryManagementWidget(),
    );
  }
}

class SellerAnalyticsTab extends StatelessWidget {
  const SellerAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: SellerAnalyticsWidget(),
    );
  }
}

class BulkToolsTab extends StatelessWidget {
  const BulkToolsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bulk Operations',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your inventory efficiently with bulk operations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Bulk Upload Section
          const BulkUploadWidget(),
          
          const SizedBox(height: 32),
          
          // Bulk Edit Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Bulk Edit',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Update multiple listings at once'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showBulkPriceUpdate(context),
                        icon: const Icon(Icons.price_change),
                        label: const Text('Update Prices'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showBulkCategoryUpdate(context),
                        icon: const Icon(Icons.category),
                        label: const Text('Change Categories'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showBulkStatusUpdate(context),
                        icon: const Icon(Icons.visibility),
                        label: const Text('Update Status'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // API Integration Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.api, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'API Integration',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Connect with your existing inventory systems'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showAPIDocumentation(context),
                        icon: const Icon(Icons.code),
                        label: const Text('API Documentation'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _generateAPIKey(context),
                        icon: const Icon(Icons.key),
                        label: const Text('Generate API Key'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showBulkPriceUpdate(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BulkPriceUpdateDialog(),
    );
  }

  static void _showBulkCategoryUpdate(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BulkCategoryUpdateDialog(),
    );
  }

  static void _showBulkStatusUpdate(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BulkStatusUpdateDialog(),
    );
  }

  static void _showAPIDocumentation(BuildContext context) {
    Navigator.of(context).pushNamed('/api-documentation');
  }

  static void _generateAPIKey(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const APIKeyGeneratorDialog(),
    );
  }
}

class PerformanceTab extends StatelessWidget {
  const PerformanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const PerformanceInsightsWidget(),
          const SizedBox(height: 24),
          const SalesForecastWidget(),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Optimization Recommendations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const OptimizationRecommendationsWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MarketingTab extends StatelessWidget {
  const MarketingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Marketing Tools',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Promotion Tools
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_offer, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Promotions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Create and manage promotional campaigns'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _createDiscount(context),
                        icon: const Icon(Icons.percent),
                        label: const Text('Create Discount'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _boostListings(context),
                        icon: const Icon(Icons.rocket_launch),
                        label: const Text('Boost Listings'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Analytics Integration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.campaign, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Campaign Performance',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const CampaignPerformanceWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _createDiscount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateDiscountDialog(),
    );
  }

  static void _boostListings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BoostListingsDialog(),
    );
  }
}

// Supporting Widgets

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: change.startsWith('+') ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    change,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder Widgets (these would be implemented as separate files)
class RecentSalesWidget extends StatelessWidget {
  const RecentSalesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ListTile(
          leading: CircleAvatar(child: Text('📱')),
          title: Text('iPhone 12 Pro'),
          subtitle: Text('2 hours ago'),
          trailing: Text('\$899', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: CircleAvatar(child: Text('👟')),
          title: Text('Nike Air Max'),
          subtitle: Text('5 hours ago'),
          trailing: Text('\$120', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: CircleAvatar(child: Text('📚')),
          title: Text('Programming Books'),
          subtitle: Text('1 day ago'),
          trailing: Text('\$45', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class OptimizationRecommendationsWidget extends StatelessWidget {
  const OptimizationRecommendationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ListTile(
          leading: Icon(Icons.lightbulb, color: Colors.orange),
          title: Text('Optimize pricing for better conversion'),
          subtitle: Text('Consider reducing prices by 5-10% for faster sales'),
        ),
        ListTile(
          leading: Icon(Icons.photo_camera, color: Colors.blue),
          title: Text('Add more high-quality photos'),
          subtitle: Text('Listings with 5+ photos sell 40% faster'),
        ),
        ListTile(
          leading: Icon(Icons.schedule, color: Colors.green),
          title: Text('Post during peak hours'),
          subtitle: Text('Best posting times: 7-9 PM weekdays'),
        ),
      ],
    );
  }
}

class CampaignPerformanceWidget extends StatelessWidget {
  const CampaignPerformanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ListTile(
          title: Text('Summer Sale Campaign'),
          subtitle: Text('Active • 12 days remaining'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('2.3%', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('CTR', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        ListTile(
          title: Text('Back to School Promo'),
          subtitle: Text('Ended • 5 days ago'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('3.1%', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('CTR', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

// Dialog Widgets
class BulkPriceUpdateDialog extends StatelessWidget {
  const BulkPriceUpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk Price Update'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Price Adjustment (%)',
              hintText: 'e.g., +10 or -5',
            ),
          ),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Category Filter (optional)',
              hintText: 'Electronics, Clothing, etc.',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class BulkCategoryUpdateDialog extends StatelessWidget {
  const BulkCategoryUpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk Category Update'),
      content: const Text('Select products and new category'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class BulkStatusUpdateDialog extends StatelessWidget {
  const BulkStatusUpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk Status Update'),
      content: const Text('Update listing visibility status'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class APIKeyGeneratorDialog extends StatelessWidget {
  const APIKeyGeneratorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate API Key'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Generate a new API key for external integrations'),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'API Key Name',
              hintText: 'e.g., Inventory System',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Generate'),
        ),
      ],
    );
  }
}

class CreateDiscountDialog extends StatelessWidget {
  const CreateDiscountDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Discount'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Discount Percentage',
              hintText: '10, 15, 20, etc.',
            ),
          ),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Campaign Duration (days)',
              hintText: '7, 14, 30, etc.',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class BoostListingsDialog extends StatelessWidget {
  const BoostListingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Boost Listings'),
      content: const Text('Increase visibility of selected listings'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Boost'),
        ),
      ],
    );
  }
}

// Data Classes
class EnterpriseTab {
  final String title;
  final IconData icon;
  final Widget widget;

  EnterpriseTab({
    required this.title,
    required this.icon,
    required this.widget,
  });
}