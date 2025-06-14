import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _dailyNotificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;
  bool _notificationsSupported = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Check if notifications are supported on this platform
    _notificationsSupported = !kIsWeb && await NotificationService.initialize();
    
    if (_notificationsSupported) {
      final isEnabled = await NotificationService.isDailyNotificationEnabled();
      final timeSettings = await NotificationService.getNotificationTime();
      
      setState(() {
        _dailyNotificationsEnabled = isEnabled;
        _notificationTime = TimeOfDay(
          hour: timeSettings['hour']!,
          minute: timeSettings['minute']!,
        );
      });
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleDailyNotifications(bool enabled) async {
    if (!_notificationsSupported) {
      _showMessage('Notifications not supported on this platform');
      return;
    }

    setState(() {
      _dailyNotificationsEnabled = enabled;
    });

    if (enabled) {
      final permissionGranted = await NotificationService.requestPermissions();
      if (!permissionGranted) {
        setState(() {
          _dailyNotificationsEnabled = false;
        });
        _showMessage('Notification permission denied');
        return;
      }
      
      await NotificationService.scheduleDailyQuote(
        hour: _notificationTime.hour,
        minute: _notificationTime.minute,
      );
      _showMessage('Daily notifications enabled!');
    } else {
      await NotificationService.cancelDailyQuote();
      _showMessage('Daily notifications disabled');
    }
  }

  Future<void> _selectTime() async {
    if (!_notificationsSupported) {
      _showMessage('Notifications not supported on this platform');
      return;
    }
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );

    if (picked != null && picked != _notificationTime) {
      setState(() {
        _notificationTime = picked;
      });

      if (_dailyNotificationsEnabled) {
        await NotificationService.scheduleDailyQuote(
          hour: _notificationTime.hour,
          minute: _notificationTime.minute,
        );
        _showMessage('Notification time updated!');
      }
    }
  }

  Future<void> _testNotification() async {
    if (!_notificationsSupported) {
      _showMessage('Notifications not supported on this platform');
      return;
    }
    
    final permissionGranted = await NotificationService.requestPermissions();
    if (!permissionGranted) {
      _showMessage('Notification permission denied');
      return;
    }
    
    await NotificationService.showTestNotification();
    _showMessage('Test notification sent!');
  }

  Future<void> _scheduleMotivational() async {
    if (!_notificationsSupported) {
      _showMessage('Notifications not supported on this platform');
      return;
    }
    
    final permissionGranted = await NotificationService.requestPermissions();
    if (!permissionGranted) {
      _showMessage('Notification permission denied');
      return;
    }
    
    await NotificationService.scheduleMotivationalReminders();
    _showMessage('Motivational reminders scheduled!');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Notification Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_notificationsSupported) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Notifications are not supported on this platform',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Please run the app on a physical device to use notifications',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Quote Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get a daily inspirational quote delivered to your device',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Daily Quotes'),
                    subtitle: Text(
                      _dailyNotificationsEnabled 
                          ? 'Notifications are enabled'
                          : 'Notifications are disabled'
                    ),
                    value: _dailyNotificationsEnabled,
                    onChanged: _toggleDailyNotifications,
                  ),
                  if (_dailyNotificationsEnabled) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('Notification Time'),
                      subtitle: Text(
                        '${_notificationTime.hour.toString().padLeft(2, '0')}:${_notificationTime.minute.toString().padLeft(2, '0')}'
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _selectTime,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Motivational Reminders',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get motivational quotes 3 times a day (9 AM, 2 PM, 7 PM)',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _scheduleMotivational,
                    icon: const Icon(Icons.fitness_center),
                    label: const Text('Schedule Motivational Reminders'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Test & Manage',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _testNotification,
                          icon: const Icon(Icons.notifications_active),
                          label: const Text('Test Notification'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await NotificationService.cancelAllNotifications();
                            setState(() {
                              _dailyNotificationsEnabled = false;
                            });
                            _showMessage('All notifications cancelled');
                          },
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Cancel All'),
                        ),
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
}
