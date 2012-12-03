part of codemirror;

/**
 * Codemirror editor configuration options.
 */ 
class Options {
    
  
  Mode _mode;
  
  /**
   * The starting value of the editor.  Default is 4.
   */
  String value = "";
  
  /**
   * The indent unit (e.g., how many spaces a "block") should be indented). 
   * Default is 2.
   */ 
  int indentUnit = 2;
  
  /**
   * The width of the tab character.  Default is 4.
   */ 
  int tabSize = 4;
  
  /**
   * The mode to use.
   */  
  Mode get mode => _mode;
  
  /**
   * Set the mode to use.
   */ 
  set mode(Mode mode) => _mode = mode;
  
  /**
   * Whether CodeMirror should scroll or wrap for long lines. Default is 
   * false (scroll).
   */
  bool lineWrapping = false;
  
}


