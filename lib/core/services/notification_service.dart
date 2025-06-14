import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../../models/quote_model.dart';
import 'quote_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final QuoteService _quoteService = QuoteService();
  static bool _isInitialized = false;

  // Initialize notifications
  static Future<bool> initialize() async {
    // Skip initialization on web platform
    if (kIsWeb) {
      print('Notifications not supported on web platform');
      return false;
    }
    
    try {
      // Initialize timezone
      tz.initializeTimeZones();
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final success = await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      _isInitialized = success ?? false;
      print('Notification service initialized: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      print('Error initializing notification service: $e');
      _isInitialized = false;
      return false;
    }
  }

  // Check if notifications are supported and initialized
  static bool get isSupported {
    return !kIsWeb && _isInitialized;
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // You can navigate to specific screens here
  }

  // Request permissions
  static Future<bool> requestPermissions() async {
    if (!isSupported) return false;
    
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      
      bool granted = true;
      
      if (androidPlugin != null) {
        granted = await androidPlugin.requestNotificationsPermission() ?? false;
      }
      
      if (iosPlugin != null) {
        granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ?? false;
      }
      
      return granted;
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  // Show immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!isSupported) {
      print('Notifications not supported or initialized');
      return;
    }
    
    try {
      const androidDetails = AndroidNotificationDetails(
        'quotes_channel',
        'Daily Quotes',
        channelDescription: 'Daily inspirational quotes',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details, payload: payload);
      print('Notification shown successfully');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  // Schedule daily quote notification with local quotes
  static Future<void> scheduleDailyQuote({
    required int hour,
    required int minute,
  }) async {
    if (!isSupported) {
      print('Notifications not supported or initialized');
      return;
    }
    
    try {
      // Cancel existing daily notifications
      await cancelDailyQuote();

      // Save notification settings
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('daily_notifications_enabled', true);
      await prefs.setInt('notification_hour', hour);
      await prefs.setInt('notification_minute', minute);

      // Schedule for the next 7 days with different quotes
      for (int i = 0; i < 7; i++) {
        final quote = await _getRandomLocalQuote();
        
        final now = DateTime.now();
        var scheduledDate = DateTime(now.year, now.month, now.day + i, hour, minute);
        
        // If it's today and the time has passed, start from tomorrow
        if (i == 0 && scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        const androidDetails = AndroidNotificationDetails(
          'daily_quotes',
          'Daily Quotes',
          channelDescription: 'Daily inspirational quotes',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(''),
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _notifications.zonedSchedule(
          i, // Daily quote notification IDs: 0-6
          'Daily Quote 💭',
          '"${quote.text}" - ${quote.author}',
          tz.TZDateTime.from(scheduledDate, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exact,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      print('Daily quotes scheduled for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} for the next 7 days');
    } catch (e) {
      print('Error scheduling daily quotes: $e');
    }
  }

  // Schedule motivational notifications
  static Future<void> scheduleMotivationalReminders() async {
    if (!isSupported) {
      print('Notifications not supported or initialized');
      return;
    }
    
    try {
      final motivationalQuotes = await _getMotivationalQuotes();
      
      // Schedule 3 motivational quotes throughout the day
      final times = [
        {'hour': 9, 'minute': 0, 'title': 'Morning Motivation ☀️'},
        {'hour': 14, 'minute': 0, 'title': 'Afternoon Boost 💪'},
        {'hour': 19, 'minute': 0, 'title': 'Evening Inspiration 🌟'},
      ];

      for (int timeIndex = 0; timeIndex < times.length; timeIndex++) {
        for (int day = 0; day < 7; day++) {
          final quote = motivationalQuotes[(timeIndex * 7 + day) % motivationalQuotes.length];
          final timeSlot = times[timeIndex];
          
          final now = DateTime.now();
          var scheduledDate = DateTime(
            now.year, 
            now.month, 
            now.day + day, 
            timeSlot['hour'] as int, 
            timeSlot['minute'] as int
          );
          
          if (day == 0 && scheduledDate.isBefore(now)) {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          }

          const androidDetails = AndroidNotificationDetails(
            'motivational_quotes',
            'Motivational Quotes',
            channelDescription: 'Motivational quotes throughout the day',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          );

          const iosDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

          const details = NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
          );

          await _notifications.zonedSchedule(
            100 + (timeIndex * 7) + day, // Motivational IDs: 100-120
            timeSlot['title'] as String,
            '"${quote.text}" - ${quote.author}',
            tz.TZDateTime.from(scheduledDate, tz.local),
            details,
            matchDateTimeComponents: DateTimeComponents.time,
            androidScheduleMode: AndroidScheduleMode.exact,
          );
        }
      }

      print('Motivational reminders scheduled');
    } catch (e) {
      print('Error scheduling motivational reminders: $e');
    }
  }

  // Get random local quote from any category
  static Future<QuoteModel> _getRandomLocalQuote() async {
    try {
      final categories = ['motivational', 'wisdom', 'success', 'love', 'attitude', 'family', 'friends'];
      final randomCategory = categories[Random().nextInt(categories.length)];
      final quotes = await _quoteService.getQuotesByCategory(randomCategory);
      
      if (quotes.isNotEmpty) {
        return quotes[Random().nextInt(quotes.length)];
      }
    } catch (e) {
      print('Error getting random local quote: $e');
    }
    
    // Fallback quote
    return QuoteModel(
      id: 'notification_fallback',
      text: 'Every day is a new beginning. Take a deep breath and start again.',
      author: 'Anonymous',
    );
  }

  // Get motivational quotes specifically
  static Future<List<QuoteModel>> _getMotivationalQuotes() async {
    try {
      return await _quoteService.getQuotesByCategory('motivational');
    } catch (e) {
      print('Error getting motivational quotes: $e');
      return [
        QuoteModel(
          id: 'motivational_fallback',
          text: 'The only way to do great work is to love what you do.',
          author: 'Steve Jobs',
        ),
      ];
    }
  }

  // Cancel daily quote notifications
  static Future<void> cancelDailyQuote() async {
    if (!isSupported) {
      print('Notifications not supported or initialized');
      return;
    }
    
    try {
      for (int i = 0; i < 7; i++) {
        await _notifications.cancel(i);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('daily_notifications_enabled', false);
      print('Daily quote notifications cancelled');
    } catch (e) {
      print('Error cancelling daily quotes: $e');
    }
  }

  // Cancel motivational notifications
  static Future<void> cancelMotivationalReminders() async {
    if (!isSupported) {
      print('Notifications not supported or initialized');
      return;
    }
    
    try {
      for (int i = 100; i <= 120; i++) {
        await _notifications.cancel(i);
      }
      print('Motivational reminders cancelled');
    } catch (e) {
      print('Error cancelling motivational reminders: $e');
    }
  }

  // Check if daily notifications are enabled
  static Future<bool> isDailyNotificationEnabled() async {
    if (!isSupported) return false;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('daily_notifications_enabled') ?? false;
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }

  // Get notification time settings
  static Future<Map<String, int>> getNotificationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'hour': prefs.getInt('notification_hour') ?? 9,
        'minute': prefs.getInt('notification_minute') ?? 0,
      };
    } catch (e) {
      print('Error getting notification time: $e');
      return {'hour': 9, 'minute': 0};
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    if (!isSupported) {
      print('Notifications not supported or initialized');
      return;
    }
    
    try {
      await _notifications.cancelAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('daily_notifications_enabled', false);
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }

  // Get pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!isSupported) return [];
    
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }

  // Test notification
  static Future<void> showTestNotification() async {
    if (!isSupported) {
      print('Notifications not supported or initialized');
      return;
    }
    
    try {
      final quote = await _getRandomLocalQuote();
      await showNotification(
        id: 999,
        title: 'Test Quote 🧪',
        body: '"${quote.text}" - ${quote.author}',
      );
      print('Test notification sent');
    } catch (e) {
      print('Error showing test notification: $e');
    }
  }
}
