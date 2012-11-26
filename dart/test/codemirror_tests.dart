// This source code is licensed under the terms described in the LICENSE file.

library codemirror_tests;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

import '../lib/codemirror.dart';
import '../mode/diff/diff.dart';


/** A no-op state for testing */
class NoOpState extends State {
  NoOpState copy() { return this; }
}

void main() {

 useHtmlConfiguration();

 test('StringStream_basic', () {
   String text = 'text';
   StringStream str = stream(text);
   expect(str.sol(), isTrue);
   expect(str.eol(), isFalse);
   for (int i=0; i < text.length; ++i){
     expect(str.peek(), equals(text[i]));
     expect(str.next(), equals(text[i])); //advances
   }
   expect(str.sol(), isFalse);
   expect(str.eol(), isTrue);
   expect(str.peek(), isNull);
 });

 test('StringStream_eat', () {
   StringStream str = stream('abcd');
   expect(str.eat('a'), equals('a'));
   expect(str.peek(), equals('b'));
 });

 test('StringStream_eatWhile', () {
   StringStream str = stream('aabc');
   expect(str.eatWhile('a'), isTrue);
   expect(str.peek(), equals('b'));
 });

 test('StringStream_eatSpace', () {
   StringStream str = stream('   abcdef');
   expect(str.eatSpace(), isTrue);
   expect(str.peek(), equals('a'));
 });

 test('StringStream_skipTo', () {
   StringStream str = stream('abc def');
   expect(str.skipTo('d'), isTrue);
   expect(str.peek(), equals('d'));
 });

 test('StringStream_match', () {
   expect(stream('abcdef').match('abc'), isTrue);
   expect(stream('abcdef').match('ABC', caseInsensitive: true), isTrue);
   expect(stream('abcdef').match('xxx'), isFalse);
   StringStream str = stream('abcdef');
   expect(str.match('abc', consume: true), isTrue);
   expect(str.peek(), equals('d'));
   str = stream('abcdef');
   expect(str.match('abc', consume: false), isTrue);
   expect(str.peek(), equals('a'));
 });

 test('Line_highlightDiff', () {
   expect(apply("+Text.", diff()), orderedEquals(["+Text.", "plus"]));
   expect(apply("-Text.", diff()), orderedEquals(["-Text.", "minus"]));
   expect(apply("@Text.", diff()), orderedEquals(["@Text.", "rangeinfo"]));
   expect(apply("Text.", diff()), orderedEquals(["Text."]));
//   expectText("-Text.").styledWith(diff()).yields(["-Text.", "minus"]);
//   expectText("@Text.").styledWith(diff()).yields(["@Text.", "rangeinfo"]);
//   expectText("Text.").styledWith(diff()).yields(["Text.", null]);
 });

 test('countColumn', () {
   expect(countColumn('0123456789'), equals(10));
   expect(countColumn('a\tb'), equals(9)); //default tabCount = 8
 });

 test('copyStyles', () {
   List<String> src = ["foo", "kw"];
   List<String> dest = [];
   copyStyles(0, 3, src, dest);
   expect(dest, orderedEquals(src));
   dest = [];
   copyStyles(1, 3, src, dest);
   expect(dest, orderedEquals(["oo", "kw"]));
 });

}

List<String> apply(String text, Mode mode, [State state]) => highlight(text, mode, state).styles;

///** An expectation tailored for making assertions about styled lines. */
//class StyledTextExpectation extends Expectation {
//  StyledTextExpectation(String text, Mode mode, [State state]):
//        super(highlight(text, mode, state).styles);
//  void yields(List<String> styles) {
//    equalsCollection(styles);
//  }
//}

/** An expectation builder for [StyledTextExpectation]s. */
//class ExpectationBuilder {
//  String _text;
//  ExpectationBuilder(this._text);
//  StyledTextExpectation styledWith(Mode mode, [State state]){
//    return new StyledTextExpectation(_text, mode, state);
//  }
//}

/** Creates an expectation builder for the given [String] value. */
//ExpectationBuilder expectText(String text) => new ExpectationBuilder(text);

/** Returns a highlighted line for the given [String] text */
Line highlight(String text, Mode mode, [State state]){
  Line l = line(text);
  l.highlight(mode, state != null ? state : new NoOpState());
  return l;
}

/** Convenience line builder */
Line line(String text) => new Line(text, []);

/** Convenience string stream builder */
StringStream stream(String str) => new StringStream(str);

/** Convenience diff mode builder */
DiffMode diff() => new DiffMode();