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
  Int(Int)
  Float(Float)

  /// Special type of ident
  KW(KWToken)
}

pub type KWToken {
  As
  Fn
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
