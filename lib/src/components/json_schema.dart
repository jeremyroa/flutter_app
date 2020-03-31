import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

class JsonSchema extends StatefulWidget {
  const JsonSchema({
    @required this.form,
    @required this.onChanged,
    this.padding,
    this.formMap,
    this.errorMessages = const {},
    this.validations = const {},
    this.decorations = const {},
    this.buttonSave,
    this.actionSave,
  });

  final Map errorMessages;
  final Map validations;
  final Map decorations;
  final String form;
  final Map formMap;
  final double padding;
  final Widget buttonSave;
  final Function actionSave;
  final ValueChanged<dynamic> onChanged;

  @override
  _CoreFormState createState() =>
      new _CoreFormState(formMap ?? json.decode(form));
}

class _CoreFormState extends State<JsonSchema> {
  final dynamic formGeneral;

  int radioValue;

  String isRequired(item, value) {
    if (value.isEmpty) {
      return widget.errorMessages[item['custom_requirement_id']] ??
          'Please enter some text';
    }
    return null;
  }

  bool labelHidden(item) {
    if (item.containsKey('hiddenLabel')) {
      if (item['hiddenLabel'] is bool) {
        return !item['hiddenLabel'];
      }
    } else {
      return true;
    }
    return false;
  }

  // Return widgets

  List<Widget> jsonToForm() {
    List<Widget> listWidget = new List<Widget>();
    if (formGeneral['title'] != null) {
      listWidget.add(Text(
        formGeneral['title'],
        style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
      ));
    }
    if (formGeneral['description'] != null) {
      listWidget.add(Text(
        formGeneral['description'],
        style: new TextStyle(fontSize: 14.0, fontStyle: FontStyle.italic),
      ));
    }

    for (var count = 0; count < formGeneral['fields'].length; count++) {
      Map item = formGeneral['fields'][count];

      if (item['field_type'] == "Freetext") {
        Widget label = SizedBox.shrink();
        if (labelHidden(item)) {
          label = new Container(
            child: new Text(
              "${item['question']}: ${item['description']}",
              style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
            ),
          );
        }

        listWidget.add(new Container(
          margin: new EdgeInsets.only(top: 5.0),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              label,
              new TextFormField(
                controller: null,
                initialValue: formGeneral['fields'][count]['value'] ?? null,
                decoration: item['decoration'] ??
                    widget.decorations[item['custom_requirement_id']] ??
                    new InputDecoration(
                      hintText: item['placeholder'] ?? "",
                      helperText: "Units: ${item['units']}" ?? "",
                    ),
                maxLines: item['field_type'] == "TextArea" ? 10 : 1,
                onChanged: (String value) {
                  formGeneral['fields'][count]['value'] = value;
                  _handleChanged();
                },
                validator: (value) {
                  if (widget.validations
                      .containsKey(item['custom_requirement_id'])) {
                    return widget.validations[item['custom_requirement_id']](
                        item, value);
                  }

                  if (item['required_level'] == 'required') {
                    return isRequired(item, value);
                  }

                  return null;
                },
              ),
            ],
          ),
        ));
      }

      if (item['field_type'] == "Integer") {
        Widget label = SizedBox.shrink();
        if (labelHidden(item)) {
          label = new Container(
            child: new Text(
              "${item['question']}: ${item['description']}",
              style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
            ),
          );
        }

        listWidget.add(new Container(
          margin: new EdgeInsets.only(top: 5.0),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              label,
              new TextFormField(
                controller: null,
                initialValue: formGeneral['fields'][count]['value'] ?? null,
                decoration: item['decoration'] ??
                    widget.decorations[item['custom_requirement_id']] ??
                    new InputDecoration(
                      hintText: item['placeholder'] ?? "",
                      helperText: "Units: ${item['units']}" ?? "",
                    ),
                maxLines: item['field_type'] == "TextArea" ? 10 : 1,
                onChanged: (String value) {
                  formGeneral['fields'][count]['value'] = value;
                  _handleChanged();
                },
                keyboardType: TextInputType.number,
                inputFormatters: [
                  WhitelistingTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (widget.validations
                      .containsKey(item['custom_requirement_id'])) {
                    return widget.validations[item['custom_requirement_id']](
                        item, value);
                  }

                  if (item['required_level'] == 'required') {
                    return isRequired(item, value);
                  }

                  return null;
                },
              ),
            ],
          ),
        ));
      }

      if (item['field_type'] == "Checkbox") {
        List<Widget> checkboxes = [];
        if (labelHidden(item)) {
          checkboxes.add(new Text("${item['question']}: ${item['description']}",
              style:
                  new TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)));
        }
        for (var i = 0; i < item['options'].length; i++) {
          checkboxes.add(
            new Row(
              children: <Widget>[
                new Expanded(
                  child: new CheckboxListTile(
                    title: new Text(formGeneral['fields'][count]['options'][i]),
                    value: formGeneral['fields'][count]['value']
                        .contains(formGeneral['fields'][count]['options'][i]),
                    dense: true,
                    onChanged: (bool value) {
                      this.setState(
                        () {
                          if (value) {
                            formGeneral['fields'][count]['value'] +=
                                ", ${formGeneral['fields'][count]['options'][i]}";
                          } else {
                            print(formGeneral['fields'][count]['value']
                                .replaceFirst(
                                    ", ${formGeneral['fields'][count]['options'][i]}",
                                    ''));
                            formGeneral['fields'][count]
                                ['value'] = formGeneral['fields'][count]
                                    ['value']
                                .replaceFirst(
                                    ", ${formGeneral['fields'][count]['options'][i]}",
                                    '');
                          }
                          _handleChanged();
                        },
                      );
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.green,
                    secondary: Text(formGeneral['fields'][count]['units']),
                  ),
                )
              ],
            ),
          );
        }

        listWidget.add(
          new Container(
            margin: new EdgeInsets.only(top: 5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: checkboxes,
            ),
          ),
        );
      }

      if (item['field_type'] == "Dropdown") {
        Widget label = SizedBox.shrink();
        if (labelHidden(item)) {
          label = new Text("${item['question']}: ${item['description']}",
              style:
                  new TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0));
        }

        listWidget.add(new Container(
          margin: new EdgeInsets.only(top: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              label,
              new DropdownButtonFormField<String>(
                value: formGeneral['fields'][count]['value'],
                validator: (value) {
                  if (widget.validations
                      .containsKey(item['custom_requirement_id'])) {
                    return widget.validations[item['custom_requirement_id']](
                        item, value);
                  }

                  if (item['required_level'] == 'required') {
                    return isRequired(item, value);
                  }

                  return null;
                },
                onChanged: (String newValue) {
                  setState(() {
                    formGeneral['fields'][count]['value'] = newValue;
                    _handleChanged();
                  });
                },
                items: item['options']
                    .map<DropdownMenuItem<String>>((dynamic data) {
                  return DropdownMenuItem<String>(
                    value: data,
                    child: new Text(
                      data,
                      style: new TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ));
      }
      if (item['field_type'] == "File") {
        Widget label = SizedBox.shrink();
        if (labelHidden(item)) {
          label = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Text("${item['question']}:",
                  style: new TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  )),
              new Text("${item['description']}. Units: ${item['units']}"),
              new Text("${item['value'] == 'null' ? '' : item['value']}")
            ],
          );
        }

        listWidget.add(new Container(
          margin: new EdgeInsets.only(top: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(child: label),
              RaisedButton(
                child: Text('Upload'),
                onPressed: () async {
                  var file = await FilePicker.getFile();
                  setState(() {
                    formGeneral['fields'][count]['value'] = file.toString();
                    _handleChanged();
                  });
                },
              )
            ],
          ),
        ));
      }
    }
    if (widget.buttonSave != null) {
      listWidget.add(new Container(
        margin: EdgeInsets.only(top: 10.0),
        child: InkWell(
          onTap: () {
            if (_formKey.currentState.validate()) {
              widget.actionSave(formGeneral);
            }
          },
          child: widget.buttonSave,
        ),
      ));
    }
    return listWidget;
  }

  _CoreFormState(this.formGeneral);

  void _handleChanged() {
    widget.onChanged(formGeneral);
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidate: formGeneral['autoValidated'] ?? false,
      key: _formKey,
      child: new Container(
        padding: new EdgeInsets.all(widget.padding ?? 8.0),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: jsonToForm(),
        ),
      ),
    );
  }
}
