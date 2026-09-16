import 'package:attendance_ontrack/studentAttendance.dart';
import 'package:edge_alerts/edge_alerts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

class ClassesName extends StatefulWidget {

  const ClassesName({Key? key}) : super(key: key);

  @override
  State<ClassesName> createState() => _ClassesNameState();
}

class _ClassesNameState extends State<ClassesName> {

  List<Classes> classesList = [];
  bool isLoading = false;
  late ProgressDialog progressDialog;


  @override
  void initState() {
    super.initState();
    retrieveData();
  }

  Future<void> retrieveData() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
        Uri.parse(
            "https://securenet.justyes.co.uk/Prod/Attendance/classesJson.php")
    );

    if (response.statusCode == 200) {
      final List<Classes> classesName = [];

      final data = json.decode(response.body);
      for (var productObject in data) {
        String id = productObject['class_id'];
        String className = productObject['class_name'];

        classesName.add(Classes(id, className));
      }

      setState(() {
        classesList = classesName;
        isLoading = false;
      });
    } else {
      // Handle the error here
      print("Error: ${response.statusCode}");
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    progressDialog = ProgressDialog(context);
    progressDialog = ProgressDialog(context,
        type: ProgressDialogType.normal, isDismissible: true, showLogs: true);
    progressDialog.style(message: "Adding new class...");

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.purple[900],
        title: const Center(
          child: Text('Select Class Name',
            style: TextStyle(
                color: Colors.white
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              isLoading
                  ? const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.purple,
                  ),
                ),
              )
                  : classesList.isNotEmpty
                  ? Expanded(
                child: ListView.builder(
                  itemCount: classesList.length,
                  itemBuilder: (context, index) {
                    final shift = classesList[index];
                    return GestureDetector(
                      onLongPress: ()
                      {
                        // Fluttertoast.showToast(msg: "Long Pressed${shift.className}");
                        showClassDeletionAlertDialog(context, shift.className);
                      },

                      onTap: () {
                        // Handle item click
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StudentAttendance(
                                  className: shift.className,
                                ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          const SizedBox(height: 9,),
                          ListTile(
                            title: ClipPath(
                              clipper: CustomClipPathTopContainerOne(),
                              child: Container(
                                padding: const EdgeInsets.only(
                                  top: 10.0,
                                  bottom: 10.0,
                                  //         left: 175.0, // Adjust the left padding here
                                ),
                                color: Colors.deepPurple,
                                child: Center(
                                  child: Text(
                                    shift.className,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 27,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
                  : Visibility(
                // Only show this if classesList is empty
                visible: classesList.isEmpty,
                child: Center(
                  child: Text(
                    "No Class Found",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showMyDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[900],
                ),
                label: const Text("Add New Class",
                  style: TextStyle(
                      color: Colors.white70
                  ),
                ),
                icon: const Icon(
                  Icons.add,
                  color: Colors.white70,

                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> addNewClass(String className) async {
    var url = Uri.parse(
        "https://securenet.justyes.co.uk/Prod/Attendance/addNewClass.php");

    try {
      var response = await http.post(url, body: {
        "className": className,
      });

      print("Raw response: '${response.body}'");

      // Handle empty or invalid responses
      if (response.body.isEmpty) {
        Fluttertoast.showToast(
          backgroundColor: Colors.red,
          textColor: Colors.white,
          msg: 'Server returned empty response',
          toastLength: Toast.LENGTH_LONG,
        );
        progressDialog.hide();
        Navigator.pop(context);
        return;
      }

      var data = json.decode(response.body);
      print("Decoded response: $data");

      if (data == "Class already exists") {
        print("if condition");
        Fluttertoast.showToast(
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          msg: 'Class Already Exists',
          toastLength: Toast.LENGTH_SHORT,
        );
        progressDialog.hide();
        Navigator.pop(context);
      }

      else if (data == "Success") {
        print("else condition");
        Fluttertoast.showToast(
          backgroundColor: Colors.green,
          textColor: Colors.white,
          msg: 'Class Added Successfully',
          toastLength: Toast.LENGTH_SHORT,
        );
        progressDialog.hide();
        Navigator.of(context).pop(); // Close dialog or screen

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => super.widget,
          ),
        );
        return;
      } else {
        // Handle unknown errors from server
        print("error occured: "+data.toString());
        Fluttertoast.showToast(
          backgroundColor: Colors.red,
          textColor: Colors.white,
          msg: 'Error: $data',
          toastLength: Toast.LENGTH_LONG,
        );
        progressDialog.hide();
        Navigator.pop(context);
      }
    } catch (e) {
      print("Exception: $e");
      Fluttertoast.showToast(
        backgroundColor: Colors.red,
        textColor: Colors.white,
        msg: 'Exception occurred: $e',
        toastLength: Toast.LENGTH_LONG,
      );
      progressDialog.hide();
      Navigator.pop(context);
    }
  }

  Future<void> _showMyDialog(BuildContext context) async {
    String textFieldValue = '';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Class'),
          content: TextField(
            textCapitalization: TextCapitalization.words ,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp("[a-zA-Z]")), ],

            onChanged: (value) {
              textFieldValue = value;
            },
            decoration:const  InputDecoration(
              labelText: 'Enter new class name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Do something with the text value
                print('Text entered: $textFieldValue');
                progressDialog.show();
                addNewClass(textFieldValue);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }



  showClassDeletionAlertDialog(BuildContext context, String className) {
    // Set Button
    Widget okBtn = TextButton(
      onPressed: () async {
        Navigator.pop(context);
        deleteClass(className);

      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.green,
      ),
      child: const Text("Delete Class", style: TextStyle(color: Colors.white)),
    );
    // Set Button
    Widget cancelBtn = TextButton(
      child:  Text("Cancel", style: TextStyle(color: Colors.white)
      ),
      onPressed: () {
        Navigator.pop(context);
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.red.shade800,
      ),
    );

    AlertDialog alert = AlertDialog(
      backgroundColor: Colors.red.shade500,
      title: Text(
        "Delete $className Class",
        style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold
        ),
      ),
      content: const SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,

          child: Column(
            children: [
              Text(
                "The existing attendance data associated with this class will be permanently deleted and cannot be recovered.\n\n"
                    "Are you sure you want to proceed with deleting the selected class?",

                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              //       SizedBox(height: 4), // TextField for Date of Birth

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

  Future deleteClass(String className) async {
    var url = Uri.parse(
        "https://securenet.justyes.co.uk/Prod/Attendance/deleteClass.php");
    var response = await http.post(url, body: {
      "className": className,
    });

    var data = json.decode(response.body);
    if (data == "Class already exists") {
      Fluttertoast.showToast(
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        msg: 'Class Already Exists',
        toastLength: Toast.LENGTH_SHORT,
      );
      progressDialog.hide();
      Navigator.pop(context);
      return;
    }
    else
    {
      edgeAlert(context,
          title: '$className Class Deleted',
          description:
          'Selected class has been deleted successfully.',
          gravity: Gravity.bottom,
          duration: 3,
          icon: Icons.done_outline,
          backgroundColor: Colors.green);
      progressDialog.hide();
      Navigator.of(context).pop(); // Close the dialog

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => super.widget));
    }
  }
}

class Classes {
  final String classID;
  final String className;
  Classes(this.classID,this.className);
}

class CustomClipPathTopContainerOne extends CustomClipper<Path> {

  @override
  Path getClip(Size size) {
    double w = size.width;
    double h = size.height;

    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth=10.0
      ..color = Colors.black;

    Path path0 = Path();
    path0.moveTo(0,size.height);
    path0.lineTo(0,size.height*0.4890143);
    path0.lineTo(0,0);
    path0.lineTo(size.width*0.8545167,0);
    path0.lineTo(size.width,size.height*0.4991714);
    path0.lineTo(size.width*0.8551250,size.height);
    path0.lineTo(0,size.height);
    path0.lineTo(size.width*0.0013417,size.height);
    path0.lineTo(0,size.height);
    path0.close();
    return path0;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}