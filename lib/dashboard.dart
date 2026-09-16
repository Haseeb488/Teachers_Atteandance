import 'dart:convert';
import 'dart:io';
import 'package:attendance_ontrack/classesNames.dart';
import 'package:attendance_ontrack/main.dart';
import 'package:attendance_ontrack/reminder.dart';
import 'package:attendance_ontrack/web_user_agent_stub.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:edge_alerts/edge_alerts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart' as AppSettings;
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';


class Dashboard extends StatefulWidget {
  final String username;

  const Dashboard({Key? key, required this.username}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Position? userCurrentLocation;

  TextEditingController studentNameController = TextEditingController();
  late ProgressDialog progressDialog;

  var geolocator = Geolocator();


  late double latitude;

  late double longitude;

  String deviceIdentifier = "";

  Future<void> _getDeviceDetails() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        var build = await deviceInfoPlugin.androidInfo;
        setState(() {
          deviceIdentifier = build.id;
        });
      } else if (Platform.isIOS) {
        var data = await deviceInfoPlugin.iosInfo;
        setState(() {
          deviceIdentifier = data.identifierForVendor!;
        });
      }
    } on PlatformException {
      Fluttertoast.showToast(msg: "Failed to get Device info");
    }
  }

  // checkLocationPermission() async {
  //   //_locationPermission = await Geolocator.requestPermission();
  //   late final Map<Permission, PermissionStatus> statusess;
  //
  //   statusess = await [Permission.notification, Permission.location].request();
  //
  //   if (_locationPermission == LocationPermission.denied) {
  //     //  Fluttertoast.showToast(msg: "status" + _locationPermission.toString());
  //     //  _locationPermission = await Geolocator.requestPermission();
  //   } else {
  //     //  locateUserLocation();
  //   }
  // }


  Future<void> checkLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled

      if (kIsWeb && getUserAgent().contains("iPhone")) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Location Permission on iPhone"),
            content: const Text(
              "To enable location:\n\n"
                  "1. Tap 'aA' in Safari’s address bar.\n"
                  "2. Choose 'Website Settings'.\n"
                  "3. Set 'Location' to 'Allow'.\n"
                  "4. Reload the page.",
            ),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        return;
      }

    if (kIsWeb) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Device Location Turned Off"),
            content: const Text("Please turn on location services to proceed."),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
      return;
    }

    // 2. Check permission status
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(
          msg: 'Location permission denied',
          backgroundColor: Colors.red,
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permission permanently denied

      Fluttertoast.showToast(msg: "Permission Denied Forever");


      if (kIsWeb) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Location Permission Denied"),
            content: const Text(
              "Please enable location permission manually:\n\n"
                  "1. Click the lock icon near the browser address bar.\n"
                  "2. Go to 'Site settings'.\n"
                  "3. Find 'Location' and set it to 'Allow'.\n"
                  "4. Reload the page.",
            ),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        return;
      }

      else {
        showDialog(
          context: context,
          builder: (_) =>
              AlertDialog(
                title: const Text("Permission Permanently Denied"),
                content: const Text(
                    "Please go to settings and enable location permission manually."),
                actions: [
                  TextButton(
                    child: const Text("Open Settings"),
                    onPressed: () {
                      Navigator.pop(context);
                      AppSettings.openAppSettings();
                    },
                  ),
                  TextButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
        Fluttertoast.showToast(
          msg: 'Location permission permanently denied',
          backgroundColor: Colors.red,
        );
        return;
      }
    }
  }


  // locateUserLocation() async {
  //   progressDialog.show();
  //
  //   Position currentLocation = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high);
  //   userCurrentLocation = currentLocation;
  //
  //   latitude = userCurrentLocation!.latitude;
  //   longitude = userCurrentLocation!.longitude;
  //   markAttendance();
  // }

  locateUserLocation() async {
    try {
      progressDialog.show();

      Position currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      userCurrentLocation = currentLocation;

      latitude = userCurrentLocation!.latitude;
      longitude = userCurrentLocation!.longitude;

      progressDialog.hide();
      markAttendance();
    } catch (e) {
      progressDialog.hide();
      Navigator.pop(context);
      print('Error fetching location: $e');


      if(kIsWeb)
      {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Location Permission Required"),
            content: const Text("Please grant location permission from browser."),
            actions: [

              TextButton(
                child: const Text("ok"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        return;
      }
      else
        {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Permission Permanently Denied"),
              content: const Text("Please go to settings and enable location permission manually."),
              actions: [
                TextButton(
                  child: const Text("Open Settings"),
                  onPressed: () {
                    Navigator.pop(context);
                    AppSettings.openAppSettings();
                  },
                ),
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
          return;
        }
    }
  }

  Future markAttendance() async {
    DateTime dateToday = DateTime.now();
    String date = dateToday.toString().substring(0, 10);
    String time = dateToday.toString().substring(10, 16);

    var url = Uri.parse(
        "https://securenet.justyes.co.uk/Prod/Attendance/teachersAttendance.php");
    var response = await http.post(url, body: {
      "username": widget.username,
      "date": date,
      "time": time,
      "deviceID": deviceIdentifier,
      "latitude": latitude.toString(),
      "longitude": longitude.toString()
    });

    var data = json.decode(response.body);

    print("response is: " + data.toString());

    if (data == "Attendance already marked") {
      Fluttertoast.showToast(
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        msg: 'Attendance Already Marked!',
        toastLength: Toast.LENGTH_SHORT,
      );
      progressDialog.hide();
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
        backgroundColor: Colors.green,
        textColor: Colors.white,
        msg: 'Attendance Marked Successfully',
        toastLength: Toast.LENGTH_SHORT,
      );
      progressDialog.hide();
      Navigator.pop(context);
    }
  }

/*
  getPrefs() async {
    SharedPreferences pre = await SharedPreferences.getInstance();
    String hours = pre.getString("savedHour") ?? "no Hour";
    String mins = pre.getString("savedMins") ?? "no Hour";

    if (hours == "no Hour") {
      hours = "18";
      mins = "00";
    }

    // Fluttertoast.showToast(msg:hours +":"+mins);

    NotificationService().showNotification(2, 'Attendance Reminder!',
        'Mark your attendance now', int.parse(hours), int.parse(mins));
  }
*/
  @override
  void initState() {
    checkLocationPermission(context);
    _getDeviceDetails();
    requestExactAlarmPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // getPrefs();
    });

    WidgetsFlutterBinding.ensureInitialized();
    // NotificationService().initializeNotification();

    progressDialog = ProgressDialog(context);
    progressDialog = ProgressDialog(context,
        type: ProgressDialogType.normal, isDismissible: true, showLogs: true);
    progressDialog.style(message: "Please wait...");

    return WillPopScope(
      onWillPop: () async {
        showAlertDialog(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.purple[900],
          title: Center(
            // ignore: prefer_interpolation_to_compose_strings
            child: Text(
              "Welcome ${widget.username}",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        backgroundColor: Colors.black,
        body: Container(
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.black54, Colors.purple.shade900])),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Wrap(
                      spacing: 4.0,
                      runSpacing: 4.0,
                      children: [
                        InkWell(
                          onTap: () {
                            showCustomAlertDialog(
                                context,
                                "REGISTER ATTENDANCE ",
                                "Register today's Attendance?");
                          },
                          child: SizedBox(
                            width: 160,
                            height: 142,
                            child: Card(
                              color: const Color.fromARGB(40, 128, 128, 128),
                              elevation: 2.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 17.0),
                                  Image.asset(
                                    "assets/teachers.png",
                                    width: 80.0,
                                  ),
                                  const SizedBox(height: 8.0),
                                  const Padding(
                                    padding: EdgeInsets.only(
                                        left: 4.0, right: 4.0),
                                    child: Text(
                                      "Teacher Attendance",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ClassesName(),
                              ),
                            );
                          },
                          child: SizedBox(
                            width: 160,
                            height: 142,
                            child: Card(
                              color: const Color.fromARGB(50, 128, 128, 128),
                              elevation: 2.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 08.0),
                                  Image.asset(
                                    "assets/student.png",
                                    width: 80.0,
                                  ),
                                  const SizedBox(height: 17.2),
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(left: 4.0, right: 4.0),
                                    child: Text(
                                      "Student Attendance",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                          _showNewStudentDialog(context);
                          },
                          child: SizedBox(
                            width: 160,
                            height: 142,
                            child: Card(
                              color: const Color.fromARGB(50, 128, 128, 128),
                              elevation: 2.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 08.0),
                                  Image.asset(
                                    "assets/newStudent.png",
                                    width: 80.0,
                                  ),
                                  const SizedBox(height: 17.2),
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(left: 4.0, right: 4.0),
                                    child: Text(
                                      "Register Student",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Reminder(
                                  username: widget.username,
                                ),
                              ),
                            );

                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) =>
                            //         NotificationPage(
                            //         ),
                            //   ),
                            // );
                          },
                          child: SizedBox(
                            width: 160,
                            height: 142,
                            child: Card(
                              color: const Color.fromARGB(50, 128, 128, 128),
                              elevation: 2.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 15.0),
                                  Image.asset(
                                    "assets/reminder.png",
                                    width: 80.0,
                                  ),
                                  const SizedBox(height: 10.0),
                                  const Text(
                                    "Reminder",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                            showAccountDeletionAlertDialog(context);
                          },
                          child: SizedBox(
                            width: 160,
                            height: 142,
                            child: Card(
                              color: const Color.fromARGB(50, 128, 128, 128),
                              elevation: 2.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 30.0),
                                  Image.asset(
                                    "assets/delete_account.png",
                                    width: 65.0,
                                  ),
                                  const SizedBox(height: 10.0),
                                  const Text(
                                    "Delete Account",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            showAlertDialog(context);
                          },
                          child: SizedBox(
                            width: 160,
                            height: 142,
                            child: Card(
                              color: const Color.fromARGB(50, 128, 128, 128),
                              elevation: 2.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 15.0),
                                  Image.asset(
                                    "assets/logout.png",
                                    width: 80.0,
                                  ),
                                  const SizedBox(height: 10.0),
                                  const Text(
                                    "Log Out",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Future<void> registerStudent(String studentName) async {
    if (studentName.trim().isEmpty) {
      Fluttertoast.showToast(
        backgroundColor: Colors.red,
        textColor: Colors.white,
        msg: 'Student name cannot be empty',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    try {
      progressDialog.show();

      var url = Uri.parse("https://securenet.justyes.co.uk/Prod/Attendance/addNewStudent.php");
      var response = await http.post(url, body: {
        "studentName": studentName,
      });

      var data = json.decode(response.body);

      if (data['status'] == "exists") {
        Fluttertoast.showToast(
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          msg: data['message'],
          toastLength: Toast.LENGTH_SHORT,
        );
        progressDialog.hide();
        Navigator.pop(context);
      } else if (data['status'] == "success") {
        Fluttertoast.showToast(
          backgroundColor: Colors.green,
          textColor: Colors.white,
          msg: "Student Registered Successfully",
          toastLength: Toast.LENGTH_SHORT,
        );
        progressDialog.hide();
        Navigator.of(context).pop(); // Close dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (BuildContext context) => super.widget),
        );
      } else {
        // Generic error
        Fluttertoast.showToast(
          backgroundColor: Colors.red,
          textColor: Colors.white,
          msg: data['message'] ?? "Something went wrong",
          toastLength: Toast.LENGTH_SHORT,
        );
        progressDialog.hide();
      }
    } catch (e) {
      Fluttertoast.showToast(
        backgroundColor: Colors.red,
        textColor: Colors.white,
        msg: "Network error: $e",
        toastLength: Toast.LENGTH_LONG,
      );
      progressDialog.hide();
    }
  }


  Future<void> _showNewStudentDialog(BuildContext context) async {

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.purple.shade900,
          title: const Center(
            child: Text('Register Student',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold
            ),),
          ),
          content: TextField(
            style: const TextStyle(
              color: Colors.white70, // This sets the input text color to white
            ),

            controller: studentNameController,
            textCapitalization: TextCapitalization.words ,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp("[a-zA-Z]")), ],

            onChanged: (value) {
            },
            decoration:const  InputDecoration(
              labelText: 'Enter student name',
              labelStyle: TextStyle(
                color: Colors.white70
              )
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel',
              style: TextStyle(
                color: Colors.red,
              ),),
            ),
            TextButton(
              onPressed: () {
                registerStudent(studentNameController.text);
              },
              child: const Text('Register',
              style: TextStyle(
                color: Colors.green
              ),),
            ),
          ],
        );
      },
    );
  }


  showAccountDeletionAlertDialog(BuildContext context) {
    // Set Button
    Widget okBtn = TextButton(
      onPressed: () async {
        Navigator.pop(context);
        edgeAlert(context,
            title: 'Request Sent',
            description:
                'Account deletion request has been sent. We will email you when it is fully removed from the system.',
            gravity: Gravity.bottom,
            duration: 6,
            icon: Icons.done_outline,
            backgroundColor: Colors.deepOrange);
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.green,
      ),
      child:
          const Text("Delete Account", style: TextStyle(color: Colors.white)),
    );
    // Set Button
    Widget cancelBtn = TextButton(
      child: const Text("Cancel", style: TextStyle(color: Colors.white)),
      onPressed: () {
        Navigator.pop(context);
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepOrange,
      ),
    );

    AlertDialog alert = AlertDialog(
      backgroundColor: Colors.black,
      title: const Text(
        "Delete My Account",
        style: TextStyle(
          color: Colors.red,
          fontSize: 16,
        ),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          // Adjusted height to accommodate keyboard
          height: MediaQuery.of(context).size.height * 0.4,
          child: const Column(
            children: [
              Text(
                "Enter your full name:",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              SizedBox(height: 8),

              // TextField for Full Name
              TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Full Name",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),

              SizedBox(height: 16),

              Text(
                "Enter your date of birth:",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              SizedBox(height: 8),

              // TextField for Date of Birth
              TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Date of Birth",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        cancelBtn,
        okBtn,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showCustomAlertDialog(BuildContext context, String title, String message) {
    //Set Button
    Widget okbtn = TextButton(
      onPressed: () {
        locateUserLocation();
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.green,
      ),
      child: const Text("Yes", style: TextStyle(color: Colors.white)),
    );
//Set Button
    Widget cancelbtn = TextButton(
      child: const Text("No", style: TextStyle(color: Colors.white)),
      onPressed: () {
        Navigator.pop(context);
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepOrange,
      ),
    );

    AlertDialog alert = AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.deepOrange,
          fontSize: 16,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      actions: [
        cancelbtn,
        okbtn,
      ],
    );

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        });
  }

  showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("No"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Yes"),
      onPressed: () {
        if (kIsWeb) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(),
            ),
          );
        }
        if (Platform.isAndroid) {
          SystemNavigator.pop();
        } else if (Platform.isIOS) {
          exit(0);
        }
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Log Out"),
      content: const Text("Are you sure to Logout  and exit the app?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      const platform = MethodChannel('exact_alarm_permission');

      try {
        final bool granted =
            await platform.invokeMethod('checkExactAlarmPermission');
        if (!granted) {
          // Prompt user to grant permission via system settings
          await platform.invokeMethod('requestExactAlarmPermission');
        }
      } on PlatformException catch (e) {
        // print("Error requesting exact alarm permission: ${e.message}");
      }
    }
  }
}
