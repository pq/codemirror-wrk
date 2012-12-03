// This source code is licensed under the terms described in the LICENSE file.

library codemirror;

import 'dart:core' hide Options;
import 'dart:html';
import 'dart:math';



part 'document.dart';
part 'line.dart';
part 'mode.dart';
part 'options.dart';

/**
 * The CodeMirror editor.
 */
class CodeMirror {

  //TODO(pquitslund): consider migrating editing to a new _Editor class

  Mode _mode;
  Options _options;

  Element _element;

  //The element in which the editor lives.
  Element _wrapper;

  // Lines to be parsed
  List<Line> _work;

  BranchChunk _doc = new BranchChunk([new LeafChunk([new Line('')])]);

  //Used in operations
  bool _updateInput;

  bool _suppressEdits = false;

  Element _lineDiv;

  /**
   * Create a new [CodeMirror], with optional configuration [options],
   * replacing the given text area [Element].
   */
  factory CodeMirror.fromTextArea(Element textArea, [Options options]) {

    var editor = new _TextAreaCodeMirror(textArea, options);

    //update text
    //textArea.text = 'UPDATED! :) ==>\n ${textArea.text}';

    return editor;
  }

  /**
   * Create a new [CodeMirror], with optional configuration [options],
   * replacing the given [place].
   */
  CodeMirror(Element place, [Options options]) :  _element = place {

    _inititalizeOptions(options);
    _createEditorDOM();

  }

  _inititalizeOptions(Options options) {
    _options = (options != null) ? options : new Options();
  }

  _createEditorDOM() {

    _wrapper = new DivElement();
    _wrapper.classes.add('CodeMirror${_options.lineWrapping ? ' CodeMirror-wrap' : ''}');

    // This mess creates the base DOM structure for the editor.
    _wrapper.innerHTML =
      //(inputDiv)
      '<div style="overflow: hidden; position: relative; width: 3px; height: 0px;">'
        //(input) -- Wraps and hides input textarea
        '<textarea style="position: absolute; padding: 0; width: 1px; height: 1em" wrap="off" '
          'autocorrect="off" autocapitalize="off">'
        '</textarea>'
      '</div>'
      // The vertical scrollbar. Horizontal scrolling is handled by the scroller itself.
      '<div class="CodeMirror-scrollbar">'
        '<div class="CodeMirror-scrollbar-inner"/></div>' // The empty scrollbar content, used solely for managing the scrollbar thumb.
      '</div>' // This must be before the scroll area because it's float-right.
      //(scroller)
      '<div class="CodeMirror-scroll" tabindex="-1">'
        //(code)
        '<div style="position: relative">' // Set to the height of the text, causes scrolling
          //(mover)
          '<div style="position: relative">' // Moved around its parent to cover visible view
            //(gutter)
            '<div class="CodeMirror-gutter">'
              //(gutterText)
              '<div class="CodeMirror-gutter-text"></div>'
            '</div>'
            //Provides positioning relative to (visible) text origin
            '<div class="CodeMirror-lines">'
              //(lineSpace)
              '<div style="position: relative; z-index: 0">'
                //(measure) Used to measure text size
                '<div style="position: absolute; width: 100%; height: 0px; overflow: hidden; visibility: hidden;"></div>'
                //(cursor)
                '<pre class="CodeMirror-cursor">&#160;</pre>' // Absolutely positioned blinky cursor
                //(widthForcer)
                '<pre class="CodeMirror-cursor" style="visibility: hidden">&#160;</pre>'
                //(selectionDiv)
                '<div style="position: relative; z-index: -1"></div>'
                //(lineDiv)
                '<div></div>' // DIVs containing the selection and the actual code
              '</div>'
            '</div>'
          '</div>'
        '</div>'
      '</div>';

    _element.nodes.add(_wrapper);

    var inputDiv = _wrapper.nodes.first,
        input = inputDiv.nodes.first,
        scroller = _wrapper.nodes.last,
        code = scroller.nodes.first,
        mover = code.nodes.first,
        gutter = mover.nodes.first,
        gutterText = gutter.nodes.first,
        lineSpace = gutter.nextNode.nodes.first,
        measure = lineSpace.nodes.first,
        cursor = measure.nextNode,
        widthForcer = cursor.nextNode,
        selectionDiv = widthForcer.nextNode,
        //lineDiv = selectionDiv.nextNode,
        scrollbar = inputDiv.nextNode,
        scrollbarInner = scrollbar.nodes.first;

    _lineDiv = selectionDiv.nextNode;

    //themeChanged();
    //keyMapChanged();

//    // Needed to hide big blue blinking cursor on Mobile Safari
//    if (ios) input.style.width = "0px";
//    if (!webkit) scroller.draggable = true;
//    lineSpace.style.outline = "none";
//    if (options.tabindex != null) input.tabIndex = options.tabindex;
//    if (options.autofocus) focusInput();
//    if (!options.gutter && !options.lineNumbers) gutter.style.display = "none";
//    // Needed to handle Tab key in KHTML
//    if (khtml) inputDiv.style.height = "1px", inputDiv.style.position = "absolute";
//
//    // Check for OS X >= 10.7. If so, we need to force a width on the scrollbar, and
//    // make it overlap the content. (But we only do this if the scrollbar doesn't already
//    // have a natural width. If the mouse is plugged in or the user sets the system pref
//    // to always show scrollbars, the scrollbar shouldn't overlap.)
//    if (mac_geLion) {
//      scrollbar.className += (overlapScrollbars() ? " cm-sb-overlap" : " cm-sb-nonoverlap");
//    } else if (ie_lt8) {
//      // Need to set a minimum width to see the scrollbar on IE7 (but must not set it on IE8).
//      scrollbar.className += " cm-sb-ie7";
//    }
//
//    // Check for problem with IE innerHTML not working when we have a
//    // P (or similar) parent node.
//    try { stringWidth("x"); }
//    catch (e) {
//      if (e.message.match(/runtime/i))
//        e = new Error("A CodeMirror inside a P-style element does not work in Internet Explorer. (innerHTML bug)");
//      throw e;
//    }

//    // Delayed object wrap timeouts, making sure only one is active. blinker holds an interval.
//    var poll = new Delayed(), highlight = new Delayed(), blinker;

    _loadMode();

//    // The selection. These are always maintained to point at valid
//    // positions. Inverted is used to remember that the user is
//    // selecting bottom-to-top.
//    var sel = {from: {line: 0, ch: 0}, to: {line: 0, ch: 0}, inverted: false};
//    // Selection-related flags. shiftSelecting obviously tracks
//    // whether the user is holding shift.
//    var shiftSelecting, lastClick, lastDoubleClick, lastScrollTop = 0, lastScrollLeft = 0, draggingText,
//        overwrite = false, suppressEdits = false;

//    // Current visible range (may be bigger than the view window).
//    var displayOffset = 0, showingFrom = 0, showingTo = 0, lastSizeC = 0;
//    // bracketHighlighted is used to remember that a bracket has been
//    // marked.
//    var bracketHighlighted;
//    // Tracks the maximum line length so that the horizontal scrollbar
//    // can be kept static when scrolling.
//    var maxLine = "", updateMaxLine = false, maxLineChanged = true;
//    var tabCache = {};


    // Initialize the content.
    _operation(() {
      var value = _options.value;
      setValue(value != null ? value : '');
      _updateInput = false;
     })();

    //var history = new History();

  }

  var _nestedOperation = 0;


  Function _operation(Function f) {
    return () {
      _startOperation();
      f();
      _endOperation();
     };
  }

  _startOperation() {
    //Fill in...
  }

  _endOperation() {

    //Fill in...

    //_updateDisplay(changes, true, (newScrollPos ? newScrollPos.scrollTop : null));
    _updateDisplay(null /*changes*/, true, null);

    //...
  }

  // Uses a set of changes plus the current scroll position to
  // determine which DOM updates have to be made, and makes the
  // updates.
  _updateDisplay(changes, bool suppressCallback, scrollTop) {
//    if (!scroller.clientWidth) {
//      showingFrom = showingTo = displayOffset = 0;
//      return;
//    }
//    // Compute the new visible window
//    // If scrollTop is specified, use that to determine which lines
//    // to render instead of the current scrollbar position.
//    var visible = visibleLines(scrollTop);
//    // Bail out if the visible area is already rendered and nothing changed.
//    if (changes !== true && changes.length == 0 && visible.from > showingFrom && visible.to < showingTo) {
//      updateVerticalScroll(scrollTop);
//      return;
//    }
//    var from = Math.max(visible.from - 100, 0), to = Math.min(doc.size, visible.to + 100);
//    if (showingFrom < from && from - showingFrom < 20) from = showingFrom;
//    if (showingTo > to && showingTo - to < 20) to = Math.min(doc.size, showingTo);
//
//    // Create a range of theoretically intact lines, and punch holes
//    // in that using the change info.
//    var intact = changes === true ? [] :
//      computeIntact([{from: showingFrom, to: showingTo, domStart: 0}], changes);
//    // Clip off the parts that won't be visible
//    var intactLines = 0;
//    for (var i = 0; i < intact.length; ++i) {
//      var range = intact[i];
//      if (range.from < from) {range.domStart += (from - range.from); range.from = from;}
//      if (range.to > to) range.to = to;
//      if (range.from >= range.to) intact.splice(i--, 1);
//      else intactLines += range.to - range.from;
//    }
//    if (intactLines == to - from && from == showingFrom && to == showingTo) {
//      updateVerticalScroll(scrollTop);
//      return;
//    }
//    intact.sort(function(a, b) {return a.domStart - b.domStart;});
//
//    var th = textHeight(), gutterDisplay = gutter.style.display;
//    lineDiv.style.display = "none";

    _patchDisplay(/*from*/ 0, /*to*/ _doc.size, /*intact*/ []);

//    lineDiv.style.display = gutter.style.display = "";
//
//    var different = from != showingFrom || to != showingTo || lastSizeC != scroller.clientHeight + th;
//    // This is just a bogus formula that detects when the editor is
//    // resized or the font size changes.
//    if (different) lastSizeC = scroller.clientHeight + th;
//    showingFrom = from; showingTo = to;
//    displayOffset = heightAtLine(doc, from);
//
//    // Since this is all rather error prone, it is honoured with the
//    // only assertion in the whole file.
//    if (lineDiv.childNodes.length != showingTo - showingFrom)
//      throw new Error("BAD PATCH! " + JSON.stringify(intact) + " size=" + (showingTo - showingFrom) +
//          " nodes=" + lineDiv.childNodes.length);
//
//    function checkHeights() {
//      var curNode = lineDiv.firstChild, heightChanged = false;
//      doc.iter(showingFrom, showingTo, function(line) {
//        if (!line.hidden) {
//          var height = Math.round(curNode.offsetHeight / th) || 1;
//          if (line.height != height) {
//            updateLineHeight(line, height);
//            gutterDirty = heightChanged = true;
//          }
//        }
//        curNode = curNode.nextSibling;
//      });
//      return heightChanged;
//    }
//
//    if (options.lineWrapping) {
//      checkHeights();
//      var shouldHaveScrollbar = needsScrollbar() ? "block" : "none";
//      if (scrollbar.style.display != shouldHaveScrollbar) {
//        scrollbar.style.display = shouldHaveScrollbar;
//        checkHeights();
//      }
//    }
//
//    gutter.style.display = gutterDisplay;
//    if (different || gutterDirty) {
//      // If the gutter grew in size, re-check heights. If those changed, re-draw gutter.
//      updateGutter() && options.lineWrapping && checkHeights() && updateGutter();
//    }
//    updateVerticalScroll(scrollTop);
//    updateSelection();
//    if (!suppressCallback && options.onUpdate) options.onUpdate(instance);
//    return true;
  }

  _patchDisplay(int from, int to, List<Line> intact) {

    // The first pass removes the DOM nodes that aren't intact.
    if (intact.isEmpty) {
      _lineDiv.innerHTML = "";
    } else {
//      function killNode(node) {
//        var tmp = node.nextSibling;
//        node.parentNode.removeChild(node);
//        return tmp;
//      }
//      var domPos = 0, curNode = lineDiv.firstChild, n;
//      for (var i = 0; i < intact.length; ++i) {
//        var cur = intact[i];
//        while (cur.domStart > domPos) {curNode = killNode(curNode); domPos++;}
//        for (var j = 0, e = cur.to - cur.from; j < e; ++j) {curNode = curNode.nextSibling; domPos++;}
//      }
//      while (curNode) curNode = killNode(curNode);
    }

    // This pass fills in the lines that actually changed.
    var nextIntact = intact.shift(), curNode = _lineDiv.firstChild, j = from;
    var scratch = new DivElement();

    _doc.iter(from, to, function(line) {

      if (nextIntact && nextIntact.to == j) {
        nextIntact = intact.shift();
      }

      if (!nextIntact || nextIntact.from > j) {

        var html;

        if (line.hidden) {
          var html = scratch.innerHTML = "<pre></pre>";
        } else {

          StringBuffer sb = new StringBuffer();
          sb.add('<pre');
          if (line.className != null) {
            sb.add(' class="${line.className}');
          }
          sb.add('>');
          sb.add(line.getHTML(_makeTab));
          sb.add('</pre>');

          html = sb.toString();

          //TODO: handle styling and selections
//          // Kludge to make sure the styled element lies behind the selection (by z-index)
//          if (line.bgClassName != null) {
//            html = '<div style="position: relative"><pre class="' + line.bgClassName +
//              '" style="position: absolute; left: 0; right: 0; top: 0; bottom: 0; z-index: -2">&#160;</pre>' + html + "</div>";
//          }
        }

        scratch.innerHTML = html;
        _lineDiv.insertBefore(scratch.firstChild, curNode);

      } else {
          curNode = curNode.nextSibling;
      }
      ++j;

    });
  }

  _makeTab(col) {
    //TODO: tabcache
    var w = _options.tabSize - col % _options.tabSize;//, cached = tabCache[w];
    //if (cached) return cached;
    var html = new StringBuffer('<span class="cm-tab">');
    for (var i = 0; i < w; ++i) {
      html.add(' ');
    }
    html.add('</span>');
    //return (tabCache[w] = {html: str + "</span>", width: w});
    return new _TabbedHtml(html.toString(), w);
  }


  _loadMode() {
      _mode = _getMode(_options, _options.mode);
      _doc.iter(0, _doc.size, function(line) { line.stateAfter = null; });
      _work = [0];
      _startWorker();
  }

  Mode _getMode(Options options, Mode mode) {
//    var spec = CodeMirror.resolveMode(spec);
//    var mfactory = modes[spec.name];
//    if (!mfactory) return CodeMirror.getMode(options, "text/plain");
//    return mfactory(options, spec);
    return mode;
  }

  _startWorker([num time]) {
    if (!_work.isEmpty) return;
    //highlight.set(time, operation(highlightWorker));
  }

  save() {

  }


  /**
   * Get the current editor content.  If an optional [lineSeparator] is not
   * specified, the default '\n' will be used.
   */
  String getValue([String lineSeparator='\n']) {
    var text = [];
    //doc.iter(0, doc.size, function(line) { text.push(line.text); });
    //return text.join(lineSeparator);
    return Strings.join(text, lineSeparator);
  }

  /**
   * Set the editor content.
   */
  setValue(String code) {
    var top = new _Coord(line: 0, ch: 0);
    _updateLines(top, new _Coord(line: _doc.size - 1, ch: _getLine(_doc.size-1).text.length),
        _splitLines(code), top, top);
    _updateInput = true;
  }

  _splitLines(String str) {
    //NOTE: need to provide alt impl for IE
    return str.split(new RegExp('\r\n?|\n'));
  }

  Line _getLine(n) => _getLineAt(_doc, n);

  Line _getLineAt(BranchChunk chunk, n) {
//    while (!chunk.lines) {
//      for (var i = 0;; ++i) {
//        var child = chunk.children[i], sz = child.chunkSize();
//        if (n < sz) { chunk = child; break; }
//        n -= sz;
//      }
//    }
//    return chunk.lines[n];

    //TODO(for testing)
    return chunk.children.first.lines[0];
  }


  // Replace the range from from to to by the strings in newText.
  // Afterwards, set the selection to selFrom, selTo.
  _updateLines(from, to, newText, selFrom, selTo) {
    if (_suppressEdits) return;

//    if (history) {
//      var old = [];
//      doc.iter(from.line, to.line + 1, function(line) { old.push(line.text); });
//      history.addChange(from.line, newText.length, old);
//      while (history.done.length > options.undoDepth) history.done.shift();
//    }

    _updateLinesNoUndo(from, to, newText, selFrom, selTo);
  }


  _updateLinesNoUndo(from, to, newText, selFrom, selTo) {
    if (_suppressEdits) return;
//    var recomputeMaxLength = false, maxLineLength = maxLine.length;
//    if (!_options.lineWrapping)
//      _doc.iter(from.line, to.line + 1, function(line) {
//        if (!line.hidden && line.text.length == maxLineLength) {recomputeMaxLength = true; return true;}
//      });
//    if (from.line != to.line || newText.length > 1) gutterDirty = true;
//
//    var nlines = to.line - from.line, firstLine = getLine(from.line), lastLine = getLine(to.line);
//
//    // First adjust the line structure, taking some care to leave highlighting intact.
//    if (from.ch == 0 && to.ch == 0 && newText[newText.length - 1] == "") {
//      // This is a whole-line replace. Treated specially to make
//      // sure line objects move the way they are supposed to.
//      var added = [], prevLine = null;
//      if (from.line) {
//        prevLine = getLine(from.line - 1);
//        prevLine.fixMarkEnds(lastLine);
//      } else lastLine.fixMarkStarts();
//      for (var i = 0, e = newText.length - 1; i < e; ++i)
//        added.push(Line.inheritMarks(newText[i], prevLine));
//      if (nlines) _doc.remove(from.line, nlines, callbacks);
//      if (added.length) _doc.insert(from.line, added);
//    } else if (firstLine == lastLine) {
//      if (newText.length == 1)
//        firstLine.replace(from.ch, to.ch, newText[0]);
//      else {
//        lastLine = firstLine.split(to.ch, newText[newText.length-1]);
//        firstLine.replace(from.ch, null, newText[0]);
//        firstLine.fixMarkEnds(lastLine);
//        var added = [];
//        for (var i = 1, e = newText.length - 1; i < e; ++i)
//          added.push(Line.inheritMarks(newText[i], firstLine));
//        added.push(lastLine);
//        _doc.insert(from.line + 1, added);
//      }
//    } else if (newText.length == 1) {
//      firstLine.replace(from.ch, null, newText[0]);
//      lastLine.replace(null, to.ch, "");
//      firstLine.append(lastLine);
//      _doc.remove(from.line + 1, nlines, callbacks);
//    } else {
//      var added = [];
//      firstLine.replace(from.ch, null, newText[0]);
//      lastLine.replace(null, to.ch, newText[newText.length-1]);
//      firstLine.fixMarkEnds(lastLine);
//      for (var i = 1, e = newText.length - 1; i < e; ++i)
//        added.push(Line.inheritMarks(newText[i], firstLine));
//      if (nlines > 1) _doc.remove(from.line + 1, nlines - 1, callbacks);
//      _doc.insert(from.line + 1, added);
//    }
//    if (_options.lineWrapping) {
//      var perLine = Math.max(5, scroller.clientWidth / charWidth() - 3);
//      _doc.iter(from.line, from.line + newText.length, function(line) {
//        if (line.hidden) return;
//        var guess = Math.ceil(line.text.length / perLine) || 1;
//        if (guess != line.height) updateLineHeight(line, guess);
//      });
//    } else {
//      _doc.iter(from.line, from.line + newText.length, function(line) {
//        var l = line.text;
//        if (!line.hidden && l.length > maxLineLength) {
//          maxLine = l; maxLineLength = l.length; maxLineChanged = true;
//          recomputeMaxLength = false;
//        }
//      });
//      if (recomputeMaxLength) updateMaxLine = true;
//    }
//
//    // Add these lines to the work array, so that they will be
//    // highlighted. Adjust work lines if lines were added/removed.
//    var newWork = [], lendiff = newText.length - nlines - 1;
//    for (var i = 0, l = work.length; i < l; ++i) {
//      var task = work[i];
//      if (task < from.line) newWork.push(task);
//      else if (task > to.line) newWork.push(task + lendiff);
//    }

    var hlEnd = from.line + min(newText.length, 500);

    _highlightLines(from.line, hlEnd);

//    newWork.push(hlEnd);
//    work = newWork;
//    startWorker(100);
//    // Remember that these lines changed, for updating the display
//    changes.push({from: from.line, to: to.line + 1, diff: lendiff});
//    var changeObj = {from: from, to: to, text: newText};
//    if (textChanged) {
//      for (var cur = textChanged; cur.next; cur = cur.next) {}
//      cur.next = changeObj;
//    } else textChanged = changeObj;

//    // Update the selection
//    function updateLine(n) {return n <= min(to.line, to.line + lendiff) ? n : n + lendiff;}
//    setSelection(clipPos(selFrom), clipPos(selTo),
//        updateLine(sel.from.line), updateLine(sel.to.line));
  }

  _highlightLines(start, end) {
    var state = _getStateBefore(start);
    _doc.iter(start, end, function(line) {
      line.highlight(_mode, state, _options.tabSize);
      line.stateAfter = _copyState(_mode, state);
      return true;
    });
  }


  _getStateBefore(n) {
//    var start = findStartLine(n), state = start && getLine(start-1).stateAfter;
//    if (!state) state = startState(mode);
//    else state = copyState(mode, state);
//    doc.iter(start, n, function(line) {
//      line.highlight(mode, state, options.tabSize);
//      line.stateAfter = copyState(mode, state);
//    });
//    if (start < n) changes.push({from: start, to: n});
//    if (n < doc.size && !getLine(n).stateAfter) work.push(n);
//    return state;
  }



  _copyState(mode, state) {
//    if (state === true) return state;
//    if (mode.copyState) return mode.copyState(state);
//    var nstate = {};
//    for (var n in state) {
//      var val = state[n];
//      if (val instanceof Array) val = val.concat([]);
//      nstate[n] = val;
//    }
//    return nstate;
    return state;
  }


}




class _TextAreaCodeMirror extends CodeMirror {

  _TextAreaCodeMirror(Element element, [Options options]) : super(element, options) {

  }

  save() {
    //hack to make form submits do the right thing
    //...
  }

}


class _Coord {

  int line;
  int ch;

  _Coord({this.line, this.ch});

}

class _Position {

  int top;
  int bottom;

}


/**
 * Utils for device detection.
 */
class _Device {

  static final PLATFORM = window.navigator.platform;
  static final USER_AGENT = window.navigator.userAgent;

  static final WEBKIT = USER_AGENT.contains('AppleWebKit');
  static final MOBILE = USER_AGENT.contains('Mobile');

  static final WIN = PLATFORM.contains('Win');
  static final MAC = PLATFORM.contains('Mac');
  static final IOS = WEBKIT && MOBILE;

}