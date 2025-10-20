import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/admin/admin_bloc.dart';
import '../../widgets/admin/admin_stats_card.dart';
import '../../widgets/admin/pending_approvals_widget.dart';
import '../../widgets/admin/user_management_widget.dart';
import '../../widgets/admin/dispute_management_widget.dart';
import '../../widgets/admin/analytics_dashboard_widget.dart';
import '../../widgets/admin/system_health_widget.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<AdminTab> _tabs = [
    AdminTab(
      title: 'Overview',
      icon: Icons.dashboard,
      widget: const AdminOverviewTab(),
    ),
    AdminTab(
      title: 'Moderation',
      icon: Icons.admin_panel_settings,
      widget: const AdminModerationTab(),
    ),
    AdminTab(
      title: 'Users',
      icon: Icons.people,
      widget: const AdminUsersTab(),
    ),
    AdminTab(
      title: 'Disputes',
      icon: Icons.gavel,
      widget: const AdminDisputesTab(),
    ),
    AdminTab(
      title: 'Analytics',
      icon: Icons.analytics,
      widget: const AdminAnalyticsTab(),
    ),
    AdminTab(
      title: 'System',
      icon: Icons.settings,
      widget: const AdminSystemTab(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    // Load initial admin data
    context.read<AdminBloc>().add(LoadAdminDashboardEvent());
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
        title: const Text('Admin Dashboard'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          // Notification Bell
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showNotifications,
          ),
          
          // Quick Actions Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleQuickAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_data',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Data'),
                ),
              ),
              const PopupMenuItem(
                value: 'system_logs',
                child: ListTile(
                  leading: Icon(Icons.article),
                  title: Text('System Logs'),
                ),
              ),
              const PopupMenuItem(
                value: 'backup',
                child: ListTile(
                  leading: Icon(Icons.backup),
                  title: Text('Create Backup'),
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
      
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) => tab.widget).toList(),
          );
        },
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => const AdminNotificationsDialog(),
    );
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case 'export_data':
        context.read<AdminBloc>().add(ExportAdminDataEvent());
        break;
      case 'system_logs':
        _showSystemLogs();
        break;
      case 'backup':
        context.read<AdminBloc>().add(CreateSystemBackupEvent());
        break;
    }
  }

  void _showSystemLogs() {
    Navigator.of(context).pushNamed('/admin/system-logs');
  }
}

class AdminOverviewTab extends StatelessWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: const [
              AdminStatsCard(
                title: 'Active Users',
                value: '12,457',
                trend: 8.2,
                icon: Icons.people,
                color: Colors.blue,
              ),
              AdminStatsCard(
                title: 'Total Products',
                value: '45,892',
                trend: 15.7,
                icon: Icons.inventory,
                color: Colors.green,
              ),
              AdminStatsCard(
                title: 'Pending Reviews',
                value: '128',
                trend: -12.3,
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              AdminStatsCard(
                title: 'Revenue (30d)',
                value: '\$124,589',
                trend: 23.1,
                icon: Icons.monetization_on,
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
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const RecentActivityList(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Pending Actions
          const PendingApprovalsWidget(),
        ],
      ),
    );
  }
}

class AdminModerationTab extends StatelessWidget {
  const AdminModerationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Moderation Queue
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Moderation Queue',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      FilterChip(
                        label: const Text('Priority First'),
                        selected: true,
                        onSelected: (selected) {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const ModerationQueueList(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Content Policies
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Content Policies',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ContentPoliciesWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminUsersTab extends StatelessWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: UserManagementWidget(),
    );
  }
}

class AdminDisputesTab extends StatelessWidget {
  const AdminDisputesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: DisputeManagementWidget(),
    );
  }
}

class AdminAnalyticsTab extends StatelessWidget {
  const AdminAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: AnalyticsDashboardWidget(),
    );
  }
}

class AdminSystemTab extends StatelessWidget {
  const AdminSystemTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SystemHealthWidget(),
          const SizedBox(height: 24),
          const SystemConfigurationWidget(),
          const SizedBox(height: 24),
          const AuditLogsWidget(),
        ],
      ),
    );
  }
}

// Supporting Widgets
class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      AdminActivity(
        title: 'New product reported',
        subtitle: 'iPhone 13 Pro - Suspected counterfeit',
        timestamp: '5 minutes ago',
        icon: Icons.report,
        priority: ActivityPriority.high,
      ),
      AdminActivity(
        title: 'User verification completed',
        subtitle: 'john.doe@example.com - Identity verified',
        timestamp: '12 minutes ago',
        icon: Icons.verified_user,
        priority: ActivityPriority.normal,
      ),
      AdminActivity(
        title: 'Dispute resolved',
        subtitle: 'Order #12345 - Refund issued to buyer',
        timestamp: '1 hour ago',
        icon: Icons.check_circle,
        priority: ActivityPriority.low,
      ),
    ];

    return Column(
      children: activities.map((activity) => _buildActivityTile(activity)).toList(),
    );
  }

  Widget _buildActivityTile(AdminActivity activity) {
    Color priorityColor = switch (activity.priority) {
      ActivityPriority.high => Colors.red,
      ActivityPriority.normal => Colors.orange,
      ActivityPriority.low => Colors.green,
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: priorityColor.withOpacity(0.1),
        child: Icon(activity.icon, color: priorityColor),
      ),
      title: Text(activity.title),
      subtitle: Text(activity.subtitle),
      trailing: Text(
        activity.timestamp,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}

class ModerationQueueList extends StatelessWidget {
  const ModerationQueueList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildModerationItem(
          title: 'Vintage Rolex Watch',
          reason: 'Suspected counterfeit',
          reportedBy: '3 users',
          priority: ModerationPriority.high,
          onApprove: () {},
          onReject: () {},
        ),
        _buildModerationItem(
          title: 'Designer Handbag Collection',
          reason: 'Price manipulation',
          reportedBy: '1 user',
          priority: ModerationPriority.medium,
          onApprove: () {},
          onReject: () {},
        ),
      ],
    );
  }

  Widget _buildModerationItem({
    required String title,
    required String reason,
    required String reportedBy,
    required ModerationPriority priority,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Reason: $reason',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Reported by: $reportedBy',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(priority.name.toUpperCase()),
              backgroundColor: _getPriorityColor(priority),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: onApprove,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: onReject,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(ModerationPriority priority) {
    return switch (priority) {
      ModerationPriority.high => Colors.red.withOpacity(0.2),
      ModerationPriority.medium => Colors.orange.withOpacity(0.2),
      ModerationPriority.low => Colors.green.withOpacity(0.2),
    };
  }
}

class AdminNotificationsDialog extends StatelessWidget {
  const AdminNotificationsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Admin Notifications'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: ListView(
          children: const [
            ListTile(
              leading: Icon(Icons.warning, color: Colors.red),
              title: Text('High Priority Alert'),
              subtitle: Text('Multiple reports on same product'),
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.blue),
              title: Text('System Update Available'),
              subtitle: Text('Version 2.1.0 is ready'),
            ),
            ListTile(
              leading: Icon(Icons.schedule, color: Colors.orange),
              title: Text('Scheduled Maintenance'),
              subtitle: Text('Tomorrow at 2:00 AM UTC'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// Additional placeholder widgets
class ContentPoliciesWidget extends StatelessWidget {
  const ContentPoliciesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ListTile(
          leading: Icon(Icons.policy),
          title: Text('Prohibited Items Policy'),
          subtitle: Text('Last updated 2 days ago'),
          trailing: Icon(Icons.edit),
        ),
        ListTile(
          leading: Icon(Icons.security),
          title: Text('Content Safety Guidelines'),
          subtitle: Text('Last updated 1 week ago'),
          trailing: Icon(Icons.edit),
        ),
      ],
    );
  }
}

class SystemConfigurationWidget extends StatelessWidget {
  const SystemConfigurationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Configuration',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const ListTile(
              title: Text('Maintenance Mode'),
              trailing: Switch(value: false, onChanged: null),
            ),
            const ListTile(
              title: Text('Auto-moderation'),
              trailing: Switch(value: true, onChanged: null),
            ),
          ],
        ),
      ),
    );
  }
}

class AuditLogsWidget extends StatelessWidget {
  const AuditLogsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Audit Logs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Admin action logs appear here...'),
          ],
        ),
      ),
    );
  }
}

// Data Classes
class AdminTab {
  final String title;
  final IconData icon;
  final Widget widget;

  AdminTab({
    required this.title,
    required this.icon,
    required this.widget,
  });
}

class AdminActivity {
  final String title;
  final String subtitle;
  final String timestamp;
  final IconData icon;
  final ActivityPriority priority;

  AdminActivity({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.priority,
  });
}

enum ActivityPriority { high, normal, low }
enum ModerationPriority { high, medium, low }