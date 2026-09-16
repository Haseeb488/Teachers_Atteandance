import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'main.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones(); // Initialize timezone
    checkExactAlarmPermission();
  //  requestNotificationPermissions();
  }

  Future<void> scheduleDailyNotification(TimeOfDay time) async {
    final int hour = time.hour;
    final int minute = time.minute;

    Fluttertoast.showToast(msg: "Hour: "+hour.toString() +"Min: "+minute.toString());


    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Notification ID
      'Reminder', // Title
      'This is your daily reminder!', // Body
      tz.TZDateTime.now(tz.local).add(Duration(
          hours: hour - DateTime.now().hour,
          minutes: minute - DateTime.now().minute)), // Scheduled Time
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_notifications', // Channel ID
          'Daily Notifications', // Channel Name
          channelDescription: 'This channel is for daily reminders.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, // Daily trigger
    );
  }

  void pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
      await scheduleDailyNotification(picked);
    }
  }

  Future<void> checkExactAlarmPermission() async {
    try {
      const platform = MethodChannel('com.example.exact_alarm');
      await platform.invokeMethod('checkExactAlarmPermission');
    } on PlatformException catch (e) {
      debugPrint("Error: ${e.message}");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daily Notifications')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: pickTime,
              child: Text('Pick Notification Time'),
            ),
            if (selectedTime != null)
              Text('Scheduled for: ${selectedTime!.format(context)}'),
          ],
        ),
      ),
    );
  }
}
