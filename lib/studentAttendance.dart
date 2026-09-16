import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

class StudentAttendance extends StatefulWidget {
  final String className;

  const StudentAttendance({super.key, required this.className});

  @override
  State<StudentAttendance> createState() => _StudentAttendanceState();
}


class _StudentAttendanceState extends State<StudentAttendance> {

  final TextEditingController studentNameController = TextEditingController();
  List<String> studentNames = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchStudentNames();
  }

  TextEditingController studentName = TextEditingController();
  late ProgressDialog progressDialog;


  Future<void> fetchStudentNames() async {
    try {
      final response = await http.get(Uri.parse(
          "https://securenet.justyes.co.uk/Prod/Attendance/studentsJson.php"));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          studentNames = data.map<String>((e) => e["name"].toString()).toList();
        });
      } else {
        debugPrint("Failed to load student names");
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }



  @override
  Widget build(BuildContext context) {

    progressDialog = ProgressDialog(context);
    progressDialog = ProgressDialog(context,
        type: ProgressDialogType.normal, isDismissible: true, showLogs: true);
    progressDialog.style(message: "Marking Attendance...");

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.purple[900],
        title: Center(
          // ignore: prefer_interpolation_to_compose_strings
          child: Text(widget.className+' Class Attendance',
            style: const TextStyle(
                color: Colors.white
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          const SizedBox(
            height: 25,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17).copyWith(bottom: 10),
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              return studentNames.where((String name) {
                return name.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              // Keep in sync with your main controller
              studentNameController.text = textEditingController.text;
              studentNameController.selection = textEditingController.selection;

              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                onSubmitted: (value) => onFieldSubmitted(),
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp("[a-zA-Z ]")),
                ],
                showCursor: true,
                cursorColor: Colors.white,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                decoration: InputDecoration(
                  prefixIconConstraints: const BoxConstraints(minWidth: 45),
                  prefixIcon: const Icon(
                    Icons.drive_file_rename_outline,
                    color: Colors.white70,
                    size: 25,
                  ),
                  border: InputBorder.none,
                  hintText: ' Enter Student Name',
                  hintStyle: const TextStyle(
                    color: Colors.white60,
                    fontSize: 20,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100).copyWith(
                      bottomRight: const Radius.circular(20),
                      bottomLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      topLeft: const Radius.circular(20),
                    ),
                    borderSide: const BorderSide(color: Colors.white38),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50).copyWith(
                      bottomRight: const Radius.circular(20),
                      bottomLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      topLeft: const Radius.circular(20),
                    ),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                ),
              );
            },
            onSelected: (String selection) {
              studentNameController.text = selection;
            },
          ),
        ),
          const SizedBox(
            height: 15,
          ),
          GestureDetector(
            onTap: ()
    {
      if (studentNameController.text.toString().isEmpty) {
        Fluttertoast.showToast(
            backgroundColor: Colors.red,
            textColor: Colors.white,
            msg: "Student does not exist in database");
        return;
      }
      else
     {

       progressDialog.show();
       markAttendance();
    }
              },
            child: Container(
              height: 53,
              width: 200,
              margin: const EdgeInsets.symmetric(horizontal: 30),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 4,
                        color: Colors.black12.withOpacity(.2),
                        offset: const Offset(2, 2))
                  ],
                  borderRadius: BorderRadius.circular(100)
                      .copyWith(bottomRight: const Radius.circular(100)),
                  gradient: LinearGradient(colors: [
                    Colors.purple.shade600,
                    Colors.deepPurple,
                  ])),
              child: Text('Mark Attendance',
                  style: TextStyle(
                      color: Colors.white.withOpacity(.8),
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future markAttendance() async {
    DateTime dateToday = DateTime.now();
    String date = dateToday.toString().substring(0, 10);
    String time = dateToday.toString().substring(10, 16);

    var url = Uri.parse(
        "https://securenet.justyes.co.uk/Prod/Attendance/studentAttendance.php");
    var response = await http.post(url, body: {
      "studentName": studentNameController.text,
      "className": widget.className,
      "date": date,
      "time": time,

    });

    var data = json.decode(response.body);
    // print("response data is: $data");


    if (data['message'] == "Attendance Already Marked") {
      Fluttertoast.showToast(
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        msg: 'Attendance Already Marked',
        toastLength: Toast.LENGTH_LONG,
      );
      progressDialog.hide();
      setState(() {
        studentNameController.text = "";
      });
      return;
    }

    if (data['message'] == "Attendance recorded successfully") {
      Fluttertoast.showToast(
        backgroundColor: Colors.green,
        textColor: Colors.white,
        msg: 'Attendance Marked Successfully',
        toastLength: Toast.LENGTH_LONG,
      );
      progressDialog.hide();
      setState(() {
        studentNameController.clear(); // or studentNameController.text = "";
      });
      return;
    }
  }
}
