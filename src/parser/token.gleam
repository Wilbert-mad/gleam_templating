pub type Token {
  Text(String)
  /// '{{'
  LeftExprTag
  /// '}}'
  RightExprTag
  /// '{%'
  LeftLogicTag
  /// '%}'
  RightLogicTag
  /// '{#'
  LeftComentTag
  /// '#}'
  RightComentTag
  /// '}'
  LeftBracket
  /// '{'
  RightBracket
  /// '('
  LeftCurly
  /// ')'
  RightCurly
  /// '['
  LeftBrace
  /// ']'
  RightBrace
  /// '.'
  Dot
  /// '..'
  DotDot
  /// ','
  Cama
  /// '-'
  Minus
  /// '+'
  Plus
  /// '*'
  Mult
  /// '/'
  Slash
  /// '|>'
  Pipe
  /// ':'
  Colon
  /// '->'
  RightArrow
  /// '<-'
  LeftArrow
  /// '=='
  EqualEqual

  /// '>'
  Gt
  /// '<'
  Lt
  /// '>='
  Gte
  /// '<='
  Lte
  /// '='
  Equal

  Ident(String)
  String(String)

  // Int(String)
  // Float(String)
  /// Special type of ident
  KW(KWToken)
}

pub type KWToken {
  Macro
  Let
  End
  Case
  Extends
  Assert
  Use
  Todo
  Panic
}
