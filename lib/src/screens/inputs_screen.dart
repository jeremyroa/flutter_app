import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
import 'package:wolfcustominput/src/components/json_schema.dart';

Future<dynamic> fetchInputs() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var connectivityResult = await (Connectivity().checkConnectivity());

  if (!(connectivityResult == ConnectivityResult.mobile ||
      connectivityResult == ConnectivityResult.wifi)) {
    var inputs = prefs.getString('inputs');
    if (!(inputs == null)) {
      print(inputs.runtimeType);
      final decode = jsonDecode(inputs);
      return decode.runtimeType == String ? jsonDecode(decode) : decode;
    }
  }

  final response = await http.get(
    'https://www.ondemandstaffing.app/api/v1/jobseeker/get_custom_onboarding?tenant=vetsny_db',
    headers: {HttpHeaders.authorizationHeader: "Bearer Yu7xPZ4eKxb1VedgxDqm"},
  );

  if (response.statusCode == 200) {
    prefs.setString('inputs', jsonEncode(response.body));
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load inputs');
  }
}

class AllFields extends StatefulWidget {
  AllFields({Key key}) : super(key: key);
  @override
  _AllFields createState() => _AllFields();
}

class _AllFields extends State<AllFields> {
  Future<dynamic> form;
  dynamic response;
  bool failNetworkSendData = false;
  bool hasInternet = true;
  bool isSync = false;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  void _sendInputs(dynamic data) async {
    print(data.runtimeType);
    var connectivityResult = await (Connectivity().checkConnectivity());

    if (!(connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi)) {
      setState(() {
        failNetworkSendData = true;
      });
      Toast.show("Failed", context,
          duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
      throw Exception("Failed don't have Internet");
    }
    setState(() {
      isSync = true;
    });
    try {
      for (var i = 0; i < data.length; i++) {
        final response = await http.post(
          "https://www.ondemandstaffing.app/api/v1/jobseeker/get_custom_onboarding?tenant=vetsny_db&custom_requirement_id=${data[i]['custom_requirement_id']}&value=${data[i]['value']}",
          headers: {
            HttpHeaders.authorizationHeader: "Bearer Yu7xPZ4eKxb1VedgxDqm"
          },
        );
      }
    } catch (e) {
      setState(() {
        failNetworkSendData = true;
      });
      Toast.show("failed", context,
          duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
      return;
    }
    setState(() {
      isSync = false;
    });
    Toast.show("Success", context,
        duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
  }

  @override
  void initState() {
    super.initState();
    form = fetchInputs();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi) {
      setState(() {
        hasInternet = true;
      });

      if (failNetworkSendData) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        var inputs = prefs.getString('inputs');
        if (inputs == null) {
          return;
        }

        final decode = jsonDecode(inputs);
        var inputsDecoded =
            decode.runtimeType == String ? jsonDecode(decode) : decode;
        _sendInputs(inputsDecoded);
        setState(() {
          failNetworkSendData = false;
        });
      }
    } else {
      setState(() {
        hasInternet = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text("Custom Inputs Wolf ${hasInternet ? '' : '- No Internet'}"),
      ),
      floatingActionButton: isSync
          ? FloatingActionButton(
              child: CircularProgressIndicator(
                backgroundColor: Colors.white,
              ),
            )
          : null,
      body: SingleChildScrollView(
          child: FutureBuilder<dynamic>(
        future: form,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            print(snapshot.data);
            return Container(
              child: Column(children: <Widget>[
                JsonSchema(
                  form: jsonEncode({
                    'title': 'Complete the form',
                    'description': '',
                    'fields': snapshot.data
                  }),
                  onChanged: (dynamic response) {
                    this.response = response;
                  },
                  actionSave: (data) async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    prefs.setString('inputs', jsonEncode(data['fields']));
                    _sendInputs(data['fields']);
                  },
                  buttonSave: Container(
                    height: 40.0,
                    color: Colors.blueAccent,
                    child: Center(
                      child: Text("Update",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ]),
            );
          } else if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }

          // By default, show a loading spinner.
          return Container(
            height: MediaQuery.of(context).size.height - 100,
            child: Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator()),
          );
        },
      )),
    );
  }
}
