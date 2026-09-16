import 'dart:convert';

import 'package:edge_alerts/edge_alerts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;


class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {

  TextEditingController user = TextEditingController();
  TextEditingController pass = TextEditingController();

  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        body: Container(
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.black, Colors.purple.shade900])
          ),

          child: SingleChildScrollView(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 80,
                    width: 300,
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Colors.purple, Colors.black87]),
                        boxShadow: [
                          BoxShadow(
                              blurRadius: 4,
                              spreadRadius: 3,
                              color: Colors.black12)
                        ],
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(200),
                            bottomRight: Radius.circular(200))),
                    child: const Center(
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  color: Colors.black45,
                                  offset: Offset(4, 1),
                                  blurRadius: 5)
                            ]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 60,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30)
                      .copyWith(bottom: 10),
                  child: TextField(
                    controller: user,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.white, fontSize: 14.5),
                    decoration: InputDecoration(
                        prefixIconConstraints:
                        const BoxConstraints(minWidth: 45),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 22,
                        ),
                        //  border: InputBorder.none,
                        hintText: 'Enter Username',
                        hintStyle: const TextStyle(
                            color: Colors.white60, fontSize: 15),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide:
                            const BorderSide(color: Colors.white38)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide:
                            const BorderSide(color: Colors.white70))),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30)
                      .copyWith(bottom: 10),
                  child: TextField(
                    controller: pass,
                    style: const TextStyle(color: Colors.white, fontSize: 14.5),
                    obscureText: isPasswordVisible ? false : true,
                    decoration: InputDecoration(
                        prefixIconConstraints:
                        const BoxConstraints(minWidth: 45),
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Colors.white70,
                          size: 22,
                        ),
                        suffixIconConstraints:
                        const BoxConstraints(minWidth: 45, maxWidth: 46),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                          child: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                            size: 22,
                          ),
                        ),
                        border: InputBorder.none,
                        hintText: 'Enter Password',
                        hintStyle: const TextStyle(
                            color: Colors.white60, fontSize: 15),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide:
                            const BorderSide(color: Colors.white38)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100).copyWith(
                                bottomRight: const Radius.circular(0)),
                            borderSide:
                            const BorderSide(color: Colors.white70))),
                  ),
                ),
                const SizedBox(
                  height: 35,
                ),
                GestureDetector(
                  onTap: () {
                    if(user.text.isEmpty)
                      {
                        Fluttertoast.showToast(msg: "Please enter username");
                        return;
                      }

                    if(pass.text.isEmpty)
                      {
                        Fluttertoast.showToast(msg: "Please enter password");
                        return;
                      }
                    register();
                  },
                  child: Container(
                    height: 53,
                    width: double.infinity,
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
                            .copyWith(bottomRight: const Radius.circular(0)),
                        gradient: LinearGradient(colors: [
                          Colors.purple.shade600,
                          Colors.deepPurple,
                        ])),
                    child: Text('Create Account',
                        style: TextStyle(
                            color: Colors.white.withOpacity(.8),
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> register() async {
    try {
      showCircularProgress(context);

      var url = Uri.parse(
          "https://securenet.justyes.co.uk/Prod/Attendance/registerUsers.php");

      var response = await http.post(url, body: {
        "username": user.text.trim(),
        "password": pass.text.trim(),
      });

      // Dismiss progress dialog before handling responses
      Navigator.pop(context);

      var data = json.decode(response.body);

      if (response.statusCode == 201 && data['status'] == 'success') {
        edgeAlert(
          context,
          title: 'Account Created Successfully',
          description: 'Login now using your username and password',
          gravity: Gravity.bottom,
          duration: 4,
          icon: Icons.check_circle,
          backgroundColor: Colors.green,
        );

        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.pop(context); // Close registration screen
      } else if (response.statusCode == 409) {
        // Handles duplicate username conflict
        Fluttertoast.showToast(msg: data['message'] ?? "Username already exists");
      } else {
        // Handles validation errors (400) or server errors (500)
        Fluttertoast.showToast(
            msg: data['message'] ?? "An unexpected error occurred");
      }
    } catch (error) {
      // Dismiss progress dialog if an exception occurs
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Fluttertoast.showToast(msg: "Network connection error");
      print("Registration Error: $error");
    }
  }

  void showCircularProgress(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      // Prevent the user from dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }


}
