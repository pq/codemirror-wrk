part of codemirror;

/**
 * [Mode]s are responsible for parsing the content of the editor. Depending on
 * the language and the amount of functionality desired, this can be done in
 * really easy or extremely complicated ways. Some parsers can be stateless,
 * meaning that they look at one element (token) of the code at a time, with
 * no memory of what came before. Most, however, will need to remember
 * something. This is done by using a [State] object, which is an object that
 * is always passed when reading a token, and which can be mutated by the
 * tokenizer.
 */
abstract class Mode {

  /** A [String] containing all the characters that are considered electric */
  //TODO(pquitslund): link to electricChars option
  String electricChars;

  /**
   * All modes must implement this method.  Implementations should read one
   * token from the stream it is given as an argument, optionally update its
   * state, and return a style [String], or [null] for tokens that do not have
   * to be styled.
   */
  //TODO(pquitslund): consider a CSS Style type (vs. String)
  String /*Style*/ token(StringStream stream, State state);

  /**
   * Produce a [State] object to be used at the start of a document.
   * [Mode]s that use state must override this method.
   */
  State startState() {
    return null; //TODO(pquitslund): default start state
  }

  /**
   * Called whenever a blank line is passed over.  Useful for languages that
   * have significant blank lines, so the mode can update the parser state
   * appropriately.
   */
  void blankLine(State state) {
    //default is a no-op
  }

  /**
   * Override if you want to provide smart indentation.
   *
   * Implementations should inspect the given state object, and optionally the
   * textAfter [String], which contains the text on the line that is being
   * indented, and return an integer, the amount of spaces to indent. It should
   * usually take the indentUnit option into account.
   * TODO (pquitslund): revisit once options are implemented
   */
  int indent(State state, String textAfter) {
    //default is a no-op
  }
}

/**
 * State objects are passed when reading a [Token] and can be used to maintain
 * state during parsing.
 */
abstract class State {
  State copy();
}

//class Token {
//  StringStream _stream;
//  State state;
//  String className;
//  Token(this._stream, this.state, [this.className]);
//  int get start() => _stream.start;
//  int get end() => _stream.pos;
//  String get string() => _stream.current();
//}

//TODO(pquitslund): the codemirror default, surely gets overwritten... and needs
//to get moved somewhere else to boot.
int tabSize = 8;

/**
 * Counts the column offset in a [String], taking tabs into account. Used
 * mostly to find indentation.
 */
int countColumn(String string, [int end = null]) {
  if (end == null) {
    end = string.indexOf(' ');
    if (end == -1) end = string.length;
  }
  int n = 0;
  for (int i = 0; i < end; ++i) {
    if (string[i] == "\t") {
      n += tabSize - (n % tabSize);
    } else{
      ++n;
    }
  }
  return n;
}

/** The character stream used by a [Mode]'s parser. */
class StringStream {
  
  int pos = 0, start = 0;
  final String _string;
  final int _tabSize;

  /** Create a stream for the given [String]. */
  StringStream(this._string, [int tabSize]) : _tabSize = (tabSize != null) ? tabSize : 8;

  /** Returns [true] only if the stream is at the end of the line. */
  bool eol() => pos >= _string.length;

  /** Returns [true] only if the stream is at the start of the line. */
  bool sol() => pos == 0;

  /**
   * Returns the next character in the stream without advancing it.
   * Returns [null] at the end of the line.
   */
  String peek() => eol() ? null : _string[pos];

  /**
   * Returns the next character in the stream and advances it. Returns [null]
   * when no more characters are available.
   */
  String next() {
    if (pos < _string.length) return _string[pos++];
    return null;
  }

  /**
   * If the next character in the stream 'matches' the given argument, it is
   * consumed and returned. Otherwise, returns [null].
   */
  String eat(String pattern) {
    String ch = peek();
    //TODO(pquitslund): patterns?
    if (ch == pattern){
      ++pos;
      return ch;
    }
    return null;
  }

  /**
   * Repeatedly calls [eat] with the given argument, until it fails. Returns
   * [true] if any characters were eaten, [false] otherwise.
   */
  bool eatWhile(String pattern) {
    int currentPos = pos;
    while (eat(pattern) != null){}
    return pos > currentPos;
  }

  /** Shortcut for [eatWhile] when matching white-space. */
  bool eatSpace() {
    return eatWhile(' ');
  }

  /** Moves the position to the end of the line. */
  void skipToEnd() {
    pos = _string.length;
  }

  /**
   * Skips to the next occurrence of the given character, if found on the
   * current line (doesn't advance the stream if the character does not occur
   * on the line). Returns [true] if the character was found.
   */
  bool skipTo(String ch) {
    int found = _string.indexOf(ch, pos);
    if (found == -1) return false;
    pos = found;
    return true;
  }

  /**
   * Backs up the stream n characters. Backing it up further than the start of
   * the current token will cause things to break, so be careful.
   */
  void backUp(int n) {
    pos -= n;
  }

  /**
   * Returns the column (taking into account tabs) at which the current token
   * starts. Can be used to find out whether a token starts a new line.
   */
  int column() => countColumn(_string, start);

  /**
   * Returns how far the current line has been indented, in spaces. Corrects
   * for tab characters.
   */
  int indentation() => countColumn(_string);

  /**
   * Acts like a multi-character eat—if consume is [true] or not given, else as
   * a look-ahead that doesn't update the stream position.
   */
  bool match(String pattern, {bool consume: false,
                              bool caseInsensitive: false}) {

    if (caseInsensitive) {
      String cased(str) => caseInsensitive ? str.toLowerCase() : str;
      if (cased(_string).indexOf(cased(pattern), pos) != pos) return false;
    }
    else if (!_string.substring(pos).contains(pattern)) return false;

    if (consume) pos += pattern.length;
    return true;
  }

  /**
   * Get the [String] between the start of the current token and the current
   * stream position.
   */
  String current() => _string.substring(start, pos);
}