part of codemirror;


abstract class Chunk {

  int height = 0;
  var parent;

  bool iterN(int at, int n, bool op(Line line));

}


class LeafChunk extends Chunk {

  List<Line> lines;

  LeafChunk(this.lines) {
    for (var i = 0, e = lines.length, height = 0; i < e; ++i) {
      lines[i].parent = this;
      height += lines[i].height;
    }
  }

  int chunkSize() => lines.length;

//  remove: function(at, n, callbacks) {
//    for (var i = at, e = at + n; i < e; ++i) {
//      var line = this.lines[i];
//      this.height -= line.height;
//      line.cleanUp();
//      if (line.handlers)
//        for (var j = 0; j < line.handlers.length; ++j) callbacks.push(line.handlers[j]);
//    }
//    this.lines.splice(at, n);
//  },
//  collapse: function(lines) {
//    lines.splice.apply(lines, [lines.length, 0].concat(this.lines));
//  },
//  insertHeight: function(at, lines, height) {
//    this.height += height;
//    this.lines = this.lines.slice(0, at).concat(lines).concat(this.lines.slice(at));
//    for (var i = 0, e = lines.length; i < e; ++i) lines[i].parent = this;
//  },

  bool iterN(int at, int n, bool op(Line line)) {
    for (var e = at + n; at < e; ++at) {
      if (op(lines[at])) {
        return true;
      }
    }
    return false;
  }

}

class BranchChunk extends Chunk {

  List<LeafChunk>/*Chunk or Leaf?*/ children;

  int size = 0;

  BranchChunk(this.children) {
    var size = 0, height = 0;
    for (var i = 0, e = children.length; i < e; ++i) {
      var ch = children[i];
      size += ch.chunkSize(); height += ch.height;
      ch.parent = this;
    }
    parent = null;
  }

  int chunkSize() => size;

//    remove: function(at, n, callbacks) {
//      this.size -= n;
//      for (var i = 0; i < this.children.length; ++i) {
//        var child = this.children[i], sz = child.chunkSize();
//        if (at < sz) {
//          var rm = Math.min(n, sz - at), oldHeight = child.height;
//          child.remove(at, rm, callbacks);
//          this.height -= oldHeight - child.height;
//          if (sz == rm) { this.children.splice(i--, 1); child.parent = null; }
//          if ((n -= rm) == 0) break;
//          at = 0;
//        } else at -= sz;
//      }
//      if (this.size - n < 25) {
//        var lines = [];
//        this.collapse(lines);
//        this.children = [new LeafChunk(lines)];
//        this.children[0].parent = this;
//      }
//    },
//    collapse: function(lines) {
//      for (var i = 0, e = this.children.length; i < e; ++i) this.children[i].collapse(lines);
//    },
//    insert: function(at, lines) {
//      var height = 0;
//      for (var i = 0, e = lines.length; i < e; ++i) height += lines[i].height;
//      this.insertHeight(at, lines, height);
//    },
//    insertHeight: function(at, lines, height) {
//      this.size += lines.length;
//      this.height += height;
//      for (var i = 0, e = this.children.length; i < e; ++i) {
//        var child = this.children[i], sz = child.chunkSize();
//        if (at <= sz) {
//          child.insertHeight(at, lines, height);
//          if (child.lines && child.lines.length > 50) {
//            while (child.lines.length > 50) {
//              var spilled = child.lines.splice(child.lines.length - 25, 25);
//              var newleaf = new LeafChunk(spilled);
//              child.height -= newleaf.height;
//              this.children.splice(i + 1, 0, newleaf);
//              newleaf.parent = this;
//            }
//            this.maybeSpill();
//          }
//          break;
//        }
//        at -= sz;
//      }
//    },
//    maybeSpill: function() {
//      if (this.children.length <= 10) return;
//      var me = this;
//      do {
//        var spilled = me.children.splice(me.children.length - 5, 5);
//        var sibling = new BranchChunk(spilled);
//        if (!me.parent) { // Become the parent node
//          var copy = new BranchChunk(me.children);
//          copy.parent = me;
//          me.children = [copy, sibling];
//          me = copy;
//        } else {
//          me.size -= sibling.size;
//          me.height -= sibling.height;
//          var myIndex = indexOf(me.parent.children, me);
//          me.parent.children.splice(myIndex + 1, 0, sibling);
//        }
//        sibling.parent = me.parent;
//      } while (me.children.length > 10);
//      me.parent.maybeSpill();
//    },

    iter(int from, int to, bool op(Line line)) {
      iterN(from, to - from, op);
    }

    bool iterN(int at, int n, bool op(Line line)) {
      for (var i = 0, e = children.length; i < e; ++i) {
        var child = children[i], sz = child.chunkSize();
        if (at < sz) {
          var used = min(n, sz - at);
          if (child.iterN(at, used, op)) return true;
          if ((n -= used) == 0) break;
          at = 0;
        } else {
          at -= sz;
        }
      }
      return false;
    }

}
