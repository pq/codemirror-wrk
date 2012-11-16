// This source code is licensed under the terms described in the LICENSE file.

part of codemirror;

// Lines and supporting players

/**
 * Line objects. Lines hold state related to a line, including
 * highlighting info (the [styles] list).
 */
class Line {

  /** We give up on parsing lines longer than [MAX_LINE_LEN] */
  final MAX_LINE_LEN = 5000;

  List<String> styles; //alternating text and css (public for testing)
  String _text;
  int _height = 1;
  List<MarkedText> _marked;
  State stateAfter;
  GutterMarker _gutterMarker;
  String _className;

  Line(this._text, List<String> styles): _marked = [] {
    if (styles == null || styles.isEmpty) {
      this.styles = [_text, null];
    } else {
      this.styles = styles;
    }
  }

  Line.inheritMarks(this._text, Line orig) {
    if (orig._marked != null) {
      orig._marked.forEach((MarkedText mark) {
        if ((mark._to == null) && (mark._style != null)) {
          List<MarkedText> newmk = _marked != null ? _marked : [];
          MarkedText nmark = mark.dup();
          newmk.add(nmark);
          nmark.attach(this);
        }
      });
    }
  }

  /**
   * Run the given [Mode]'s parser over a line, update the styles
   * list, which contains alternating fragments of text and CSS classes.
   */
  bool highlight(Mode mode, State state, [int tabSize]) {
    var stream = new StringStream(_text, tabSize);
    List<String> st = styles;
    int pos = 0;
    bool changed = false;
    String curWord = st[0], prevWord;
    if (_text == "") mode.blankLine(state);
    while (!stream.eol()) {
      var style = mode.token(stream, state);
      var substr = _text.substring(stream.start, stream.pos);
      stream.start = stream.pos;
      if ((pos > 0) && st[pos-1] == style) {
        st[pos-2] = st[pos-2].concat(substr);
      } else if (substr != null) {
        if (!changed
            && (st[pos+1] != style || (pos > 0 && st[pos-2] != prevWord))) {
          changed = true;
        }
        st[pos++] = substr;
        st[pos++] = style;
        prevWord = curWord;
        curWord = pos < st.length ? st[pos] : null;
      }
      // Give up when line is ridiculously long
      if (stream.pos > MAX_LINE_LEN) {
        st[pos++] = _text.substring(stream.pos);
        st[pos++] = null;
        break;
      }
    }
    if (st.length != pos) {
      st.length = pos;
      changed = true;
    }
    if ((pos > 0) && st[pos-2] != prevWord) changed = true;
    // Short lines with simple highlights return null, and are
    // counted as changed by the driver because they are likely to
    // highlight the same way in various contexts.
    return changed || (st.length < 5 && _text.length < 10 ? null : false);
  }

  /** Replace a piece of a line, keeping the styles around it intact. */
  void replace (int from, int to_, String text) {
    // Reset line class if the whole text was replaced.
    if (from != null && (to_ == null || to_ == _text.length)) {
      _className = _gutterMarker = null;
    }
    var st = [];
    List<MarkedText> mk = _marked;
    int to = to_ == null ? _text.length : to_;
    copyStyles(0, from, styles, st);
    if (text != null) {
      st.addAll([text, null]);
    }
    copyStyles(to, _text.length, this.styles, st);
    styles = st;
    _text = '${_text.substring(0, from)}$text${_text.substring(to)}';
    stateAfter = null;
    if (mk != null) {
      int diff = text.length - (to - from);
      for (int i = 0; i < mk.length; ++i) {
        MarkedText mark = mk[i];
        mark.clipTo(from == null, from == null ?  0 : from,
            to_ == null, to, diff);
        if (mark.isDead()) {
          mark.detach(this);
          mk.removeRange(i--, 1);
        }
      }
    }
  }
}

/** Gutter marker (associated with a [Line]). */
class GutterMarker {
  final String _text, _style;
  GutterMarker(this._text, this._style);
}

/** Marked text represented as a list of [Line]s with a style. */
class MarkedText {
  int _from, _to;
  String _style;
  List<Line> _lines;

  MarkedText(this._from, this._to, this._style, this._lines);

  void attach(Line line){
    _lines.add(line);
  }

  void detach(Line line) {
    //my kindgom for _lines.remove(line)
    _lines.removeRange(_lines.indexOf(line), 1);
  }

  MarkedText split(int pos, int lenBefore) {
    if (_to <= pos && _to != null) return null;
    int from = _from < pos ||_from == null ? null
        : _from - pos + lenBefore;
    int to = _to == null ? null : _to - pos + lenBefore;
    return new MarkedText(from, to, _style, _lines);
  }

  MarkedText dup() => new MarkedText(null, null, _style, _lines);

  void clipTo(bool fromOpen, int from, bool toOpen, int to, int diff) {
    if (_from != null && _from >= from) {
      _from = max(to, _from) + diff;
    }
    if (_to != null && _to > from) {
      _to = to < _to ? _to + diff : from;
    }
    if (fromOpen && to > _from && (to < _to || _to == null)) {
      _from = null;
    }
    if (toOpen && (from < _to || _to == null)
        && (from > _from || _from == null)) {
      _to = null;
    }
  }

  bool isDead() => _from != null && _to != null && _from >= _to;

  bool sameSet(MarkedText x) => _lines == x._lines;
}

/** Utility used by [replace] and [split] */
void copyStyles(int from, int to, List<String> src, List<String> dest) {
  for (int i = 0, pos = 0, state = 0; pos < to; i+=2) {
    String part = src[i];
    int end = pos + part.length;
    if (state == 0) {
      if (end > from) {
        dest.add(part.substring(from - pos, min(part.length, to - pos)));
      }
      if (end >= from) state = 1;
    } else if (state == 1) {
      if (end > to) {
        dest.add(part.substring(0, to - pos));
      } else {
        dest.add(part);
      }
    }
    dest.add(src[i+1]);
    pos = end;
  }
}