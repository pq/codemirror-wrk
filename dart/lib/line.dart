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
  String text;
  int height = 1;
  List<MarkedText> _marked;
  State stateAfter;
  GutterMarker _gutterMarker;
  String className;
  String bgClassName;
  bool hidden;

  var parent;

  Line(this.text, [List<String> styles]): _marked = [] {
    if (styles == null || styles.isEmpty) {
      this.styles = [text, null];
    } else {
      this.styles = styles;
    }
  }

  Line.inheritMarks(this.text, Line orig) {
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
   * Produces an HTML fragment for the line, taking selection, marking, and
   * highlighting into account.
   */
  String getHTML(makeTab, [wrapAt, wrapId, wrapWBR]) {

    var html = [], first = true, col = 0;

    span_(String text, String style) {

      if (text == null) {
        return;
      }
      // Work around a bug where, in some compat modes, IE ignores leading spaces
      //if (first && ie && text.charAt(0) == " ") text = "\u00a0" + text.slice(1);
      first = false;
      StringBuffer escaped = new StringBuffer('');
      if (text.indexOf('\t') == -1) {
        col += text.length;
        escaped.add(htmlEscape(text));
      } else {
        for (var pos = 0;;) {
          var idx = text.indexOf('\t', pos);
          if (idx == -1) {
            escaped.add(htmlEscape(text.substring(pos)));
            col += text.length - pos;
            break;
          } else {
            col += idx - pos;
            var tab = makeTab(col);
            escaped.add(htmlEscape(text.substring(pos, idx))).add(tab.html);
            col += tab.width;
            pos = idx + 1;
          }
        }
      }

      if (style != null) {
        var span = new StringBuffer()
          ..add('<span class="')
          ..add(style)
          ..add('">')
          ..add(escaped)
          ..add('</span>');
        html.add(span.toString());
      } else {
        html.add(escaped.toString());
      }
    };

    var span = span_;

    if (wrapAt != null) {

      var outPos = 0, open = '<span id=" ${wrapId} "\">';

      span = function(text, style) {
        var l = text.length;
        if (wrapAt >= outPos && wrapAt < outPos + l) {
          if (wrapAt > outPos) {
            span_(text.slice(0, wrapAt - outPos), style);
            // See comment at the definition of spanAffectsWrapping
            if (wrapWBR) {
              html.add("<wbr>");
            }
          }
          html.add(open);
          var cut = wrapAt - outPos;
          span_(opera ? text.slice(cut, cut + 1) : text.slice(cut), style);
          html.add("</span>");
          if (opera) span_(text.slice(cut + 1), style);
          wrapAt--;
          outPos += l;
        } else {
          outPos += l;
          span_(text, style);
          // Output empty wrapper when at end of line
          if (outPos == wrapAt && outPos == len) {
            var eol = new StringBuffer()
               ..add(open)
               ..add(gecko ? "&#x200b;" : " ")
               ..add("</span>");
            html.add(eol.toString());
          }
//          // Stop outputting HTML when gone sufficiently far beyond measure
//          else if (outPos > wrapAt + 10 && /\s/.test(text)) {
//            span = function(){};
//          }
        }
      };
    }
  }



  /**
   * Run the given [Mode]'s parser over a line, update the styles
   * list, which contains alternating fragments of text and CSS classes.
   *
   * Short lines with simple highlights return [null], and are counted as changed
   * by the driver because they are likely to highlight the same way in various contexts.
   *
   */
  bool highlight(Mode mode, State state, [int tabSize]) {
    var stream = new StringStream(text, tabSize);
    List<String> st = styles;
    int pos = 0;
    bool changed = false;
    String curWord = st[0], prevWord;
    if (text == "") mode.blankLine(state);
    while (!stream.eol()) {
      var style = mode.token(stream, state);
      var substr = text.substring(stream.start, stream.pos);
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
        st[pos++] = text.substring(stream.pos);
        st[pos++] = null;
        break;
      }
    }
    if (st.length != pos) {
      st.length = pos;
      return true;
    }
    if ((pos > 0) && st[pos-2] != prevWord) {
      return true;
    }
    // Short lines with simple highlights return null
    return (st.length < 5 && text.length < 10) ? null : false;
  }

  /** Replace a piece of a line, keeping the styles around it intact. */
  void replace (int from, int to_, String newText) {
    // Reset line class if the whole text was replaced.
    if (from != null && (to_ == null || to_ == text.length)) {
      className = _gutterMarker = null;
    }
    var st = [];
    List<MarkedText> mk = _marked;
    int to = to_ == null ? text.length : to_;
    copyStyles(0, from, styles, st);
    if (newText != null) {
      st.addAll([newText, null]);
    }
    copyStyles(to, text.length, this.styles, st);
    styles = st;
    text = '${text.substring(0, from)}$newText${text.substring(to)}';
    stateAfter = null;
    if (mk != null) {
      int diff = newText.length - (to - from);
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

class _TabbedHtml {
  String html;
  int width;
  _TabbedHtml(this.html, this.width);
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

//TODO: move and calculate these
final opera = false, gecko = false;

final _escapeElement = new PreElement();

String htmlEscape(str) {
  //TODO: add special handling for Opera and IE
  _escapeElement.textContent = str;
  return _escapeElement.innerHTML;
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