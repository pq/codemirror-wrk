// This source code is licensed under the terms described in the LICENSE file.

library diff_mode;

import '../../lib/codemirror.dart';

import 'dart:html';

/** A [Mode] for diff. */
class DiffMode extends Mode {
  String token(StringStream stream, State state) {
    var ch = stream.next();
    stream.skipToEnd();
    if (ch == "+") return "plus";
    if (ch == "-") return "minus";
    if (ch == "@") return "rangeinfo";
    return null;
  }
}

//TODO move the editor hook up into an HTML script tag
void main() {
  var code = query("#code").text;
  query("#code").text = '${code} !!!!'; 
  //var editor = CodeMirror.fromTextArea(document.getElementById("code"), {});
  var editor = CodeMirror.fromTextArea(query("#code"));
}