// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var tests = [];

function StringBuffer() {
  this.buffer = [];
}

StringBuffer.prototype.append = function append(string) {
  this.buffer.push(string);
  return this;
};

StringBuffer.prototype.toString = function toString() {
  return this.buffer.join("");
};

function AssertException(message) {
  this.message = message;
}

AssertException.prototype.toString = function() {
  return 'AssertException: ' + this.message;
}

function assert(exp, message) {
  if (!exp) {
    throw new AssertException(message);
  }
}

function htmlEscape(str) {
  return str.replace(/[<&]/g, function(str) {
    return str == "&" ? "&amp;" : "&lt;";
  });
}

function forEach(arr, f) {
  for (var i = 0, e = arr.length; i < e; ++i) f(arr[i]);
}

function Failure(why) {
  this.message = why;
}

function test(name, run) {
  tests.push({
    name: name,
    func: run
  });
}

function testCM(name, run, opts) {
  test(name, function() {
    var place = document.getElementById("testground"),
        cm = CodeMirror(place, opts);
    try {
      run(cm);
    } finally {
      place.removeChild(cm.getWrapperElement());
    }
  });
}

function runTests() {
  var failures = [],
      run = 0;
  for (var i = 0; i < tests.length; ++i) {
    var test = tests[i];
    try {
      test.func();
    } catch (e) {
      if (e instanceof Failure) failures.push({
        type: "failure",
        test: test.name,
        text: e.message,
        src: e.details,
        tokenIndex: e.tokenIndex
      });
      else failures.push({
        type: "error",
        test: test.name,
        text: e.toString()
      });
    }
    run++;
  }
  var html = [run + " tests run."];
  if (failures.length) forEach(failures, function(fail) {
    html.push(fail.test + ': <span class="' + fail.type + '">' + htmlEscape(fail.text) + "</span>");
    if (fail.src) {
      var accum = buildErrorText(fail.src, "text/dart", fail.tokenIndex);
      html.push(accum);
    }

  });
  else html.push('<span class="ok">All passed.</span>');

  document.getElementById("output").innerHTML = html.join("\n");
}

function emphasize(string) {
  return "<u>" + string + "</u>";
}

function buildErrorText(string, modespec, tokenIndex) {
  var mode = CodeMirror.getMode({
    indentUnit: 2
  }, modespec);
  var accum = [];
  var currentIndex = 0;
  var callback = function(string, style) {
      string = htmlEscape(string);
      if (string == "\n") accum.push("<br>");
      else if (style) {
        if (tokenIndex === currentIndex) {
          string = emphasize(string);
        }
        accum.push("<span class=\"cm-" + htmlEscape(style) + "\">" + string + "</span>");
      } else accum.push(string);
      ++currentIndex;
      }

  var lines = CodeMirror.splitLines(string),
      state = CodeMirror.startState(mode);
  for (var i = 0, e = lines.length; i < e; ++i) {
    if (i) callback("\n");
    var stream = new CodeMirror.StringStream(lines[i]);
    while (!stream.eol()) {
      var style = mode.token(stream, state);
      callback(stream.current(), style, i, stream.start);
      stream.start = stream.pos;
    }
  }
  return accum.join("");
}

function runMode(string, modespec, callback) {
  var mode = CodeMirror.getMode({
    indentUnit: 2
  }, modespec);
  var isNode = callback.nodeType == 1;
  if (isNode) {
    var node = callback,
        accum = [];
    callback = function(string, style) {
      if (string == "\n") accum.push("<br>");
      else if (style) accum.push("<span class=\"cm-" + htmlEscape(style) + "\">" + htmlEscape(string) + "</span>");
      else accum.push(htmlEscape(string));
    }
  }
  var lines = CodeMirror.splitLines(string),
      state = CodeMirror.startState(mode);
  for (var i = 0, e = lines.length; i < e; ++i) {
    if (i) callback("\n");
    var stream = new CodeMirror.StringStream(lines[i]);
    while (!stream.eol()) {
      var style = mode.token(stream, state);
      callback(stream.current(), style, i, stream.start);
      stream.start = stream.pos;
    }
  }
  if (isNode) node.innerHTML = accum.join("");
};

function eq(a, b, msg) {
  if (a != b) throw new Failure(a + " != " + b + (msg ? " (" + msg + ")" : ""));
}

function eqPos(a, b, msg) {
  if (a == b) return;
  if (a == null || b == null) throw new Failure("comparing point to null");
  eq(a.line, b.line, msg);
  eq(a.ch, b.ch, msg);
}

function is(a, msg) {
  if (!a) throw new Failure("assertion failed" + (msg ? " (" + msg + ")" : ""));
}

window.onload = runTests;