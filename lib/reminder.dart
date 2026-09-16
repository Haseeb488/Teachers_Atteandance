import 'package:attendance_ontrack/dashboard.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'main.dart';

class Reminder extends StatefulWidget {

  final String username;
  const Reminder({Key? key, required this.username}) : super(key: key);

  @override
  State<Reminder> createState() => _ReminderState();
}

class _ReminderState extends State<Reminder> {
  var hour = 6;
  var minute = 0;
  var timeFormat = "AM";

  String savedHour = "";
  String savedMins = "";
  String savedFormat = "";

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late SharedPreferences prefs;

  getValue() async {
    prefs = await _prefs;

    setState(() {
      savedHour = (prefs.containsKey("savedHour")
          ? prefs.getString("savedHour")
          : "no Hour")!;

      savedMins = (prefs.containsKey("savedMins")
          ? prefs.getString("savedMins")
          : "no Mins")!;

      savedFormat = (prefs.containsKey("savedFormat")
          ? prefs.getString("savedFormat")
          : "PM")!;

      if(savedHour == "no Hour") {
        hour = 6;
        minute = 0;
        timeFormat = savedFormat;
        savedHour = "18";
        savedMins ="00";
        timeFormat = "PM";
      }
    });

    hour = int.parse(savedHour) - 12;
    minute = int.parse(savedMins);
    timeFormat = savedFormat;

    // Fluttertoast.showToast(msg: "Reminder: " + savedHour + ":" + savedMins);
  }

  Future<void> requestNotificationPermission() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    late final Map<Permission, PermissionStatus> statusess;

    if (androidInfo.version.sdkInt > 32) {
      statusess = await [Permission.notification,Permission.location].request();
    }
  }


  @override
  void initState() {
    getValue();
    requestNotificationPermission();
    tz.initializeTimeZones(); // Initialize timezone
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return  WillPopScope(
      onWillPop: () async
      {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Dashboard(
              username: widget.username,
            ),
          ),
        );
        return false;
      },

      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.purple[900],
          title: const Center(
            child: Text('Attendance Reminder',
              style: TextStyle(
                  color: Colors.white
              ),
            ),
          ),
        ),
        backgroundColor: Colors.black,
        body: Container(
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.black26, Colors.purple.shade900])),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    "When shall app remind you? ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, "0")} ${timeFormat}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white)),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      NumberPicker(
                        minValue: 1 ,
                        maxValue: 12,
                        value: hour,
                        zeroPad: true,
                        infiniteLoop: true,
                        itemWidth: 80,
                        itemHeight: 60,
                        onChanged: (value) {
                          setState(() {
                            hour = value;
                          });
                        },
                        textStyle:
                        const TextStyle(color: Colors.grey, fontSize: 20),
                        selectedTextStyle:
                        const TextStyle(color: Colors.white, fontSize: 30),
                        decoration: const BoxDecoration(
                          border: Border(
                              top: BorderSide(
                                color: Colors.white,
                              ),
                              bottom: BorderSide(color: Colors.white)),
                        ),
                      ),
                      NumberPicker(
                        minValue: 0,
                        maxValue: 59,
                        value: minute,
                        zeroPad: true,
                        infiniteLoop: true,
                        itemWidth: 80,
                        itemHeight: 60,
                        onChanged: (value) {
                          setState(() {
                            minute = value;
                          });
                        },
                        textStyle:
                        const TextStyle(color: Colors.grey, fontSize: 20),
                        selectedTextStyle:
                        const TextStyle(color: Colors.white, fontSize: 30),
                        decoration: const BoxDecoration(
                          border: Border(
                              top: BorderSide(
                                color: Colors.white,
                              ),
                              bottom: BorderSide(color: Colors.white)),
                        ),
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                timeFormat = "AM";
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                  color: timeFormat == "AM"
                                      ? Colors.grey.shade900
                                      : Colors.grey.shade700,
                                  border: Border.all(
                                    color: timeFormat == "AM"
                                        ? Colors.grey
                                        : Colors.grey.shade700,
                                  )),
                              child: const Text(
                                "AM",
                                style:
                                TextStyle(color: Colors.white, fontSize: 25),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                timeFormat = "PM";
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: timeFormat == "PM"
                                    ? Colors.grey.shade900
                                    : Colors.grey.shade700,
                                border: Border.all(
                                  color: timeFormat == "PM"
                                      ? Colors.grey
                                      : Colors.grey.shade700,
                                ),
                              ),
                              child: const Text(
                                "PM",
                                style:
                                TextStyle(color: Colors.white, fontSize: 25),
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                TextButton(
                  onPressed: () {

                    if(timeFormat == "AM" && hour == 12)
                    {
                      hour = hour - 12;
                    }

                    if(timeFormat == "PM" && hour == 12)
                    {
                      hour = hour;
                    }

                    if (timeFormat == "PM" && hour != 12) {
                      hour = hour + 12;
                    }

                    Fluttertoast.showToast(
                        msg: "Reminder Set for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}");

                    scheduleDailyNotification(hour,minute);

                    prefs.setString(
                        "savedHour", hour.toString().padLeft(2, '0'));
                    prefs.setString(
                        "savedMins", minute.toString().padLeft(2, '0'));
                    prefs.setString(
                        "savedFormat", timeFormat);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Dashboard(
                          username: widget.username,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(5.0),
                    child: Text(
                      "Set Reminder",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }



  Future<void> scheduleDailyNotification(int hour, int minutes) async {

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Notification ID
      'Attendance Reminder', // Title
      "Have you marked today's attendance!", // Body
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


  Future<void> checkExactAlarmPermission() async {
    try {
      const platform = MethodChannel('com.example.exact_alarm');
      await platform.invokeMethod('checkExactAlarmPermission');
    } on PlatformException catch (e) {
      debugPrint("Error: ${e.message}");
    }
  }



}