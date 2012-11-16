// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//style constants
var KW    = "keyword";
var UNDEF = undefined;
var STR   = "string";
var VAR   = "variable";
var WS    = null;

testTokens("class_def",
  ["class", KW,
   " ", WS,
   "Foo", VAR,
   "{", UNDEF]);

testTokens("simple_string",
  ["var", KW,
   " ", WS,
   "v", VAR,
   " ",WS,
   "=", UNDEF,
   " ", WS,
   "\"str\"", STR,
   ";", UNDEF]);

function testTokens(name, pairs) {
  test(name, function() {
    assertTokens(pairs);
  });
}

function assertTokens(pairs) {
  var stringCount = pairs.length;
  assert(stringCount % 2 == 0);
  var expectedCount = stringCount / 2;
  var buf = new StringBuffer();
  for (var i = 0; i < expectedCount; i++) {
    buf.append(pairs[i * 2]);
  }

  var sourceString = buf.toString();
  var index = 1;
  runMode(sourceString, "text/dart", function(token, style) {
    try {
      eq(style, pairs[index]);
    } catch (err) {
      //attach error details
      err.details = sourceString;
      err.tokenIndex = (index-1)/2;
      throw err;
    }
    index += 2;
  });
}
