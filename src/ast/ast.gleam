import chomp/span.{type Span}
import gleam/option

pub type Idn =
  String

pub type Templ {
  Templ(body_stms: List(BodyStm))
}

pub type BodyStm {
  BodyStm(span: Span, node: Node, display: NodeDisplay)
}

pub type NodeDisplay {
  /// Text
  StaticDisplay
  /// Expr Tag
  Display
  /// Logic Tag
  NoDisplay
}

pub type Node {
  Text(String)

  // /// 
  // /// ```glt
  // /// {% macro <name>(<arg>: <type>) %}
  // ///  <body>
  // /// {% endmacro %}
  // /// ```
  // /// 
  // /// Using macro
  // /// ```glt
  // /// {% <name>(arg) %}
  // /// ```
  // /// 
  // /// Using macro (with body)
  // /// ```glt
  // /// {% <name>(arg) %}
  // /// {% end<name> %}
  // /// ```
  // Macro
  // /// Block with content:
  // /// ```glt
  // /// {% block <name> %}
  // ///   <body>
  // /// {% blockend %}
  // /// ```
  // Block
  // /// ```glt
  // /// {% extends "<path>" %}
  // /// ```
  // Extend
  // /// ```glt
  // /// {{ 
  // ///   case <expr> {
  // ///     <pat> -> <expr> | { <TODO> }
  // ///   }
  // /// }}
  // /// ```
  // // Case
  // /// ```glt
  // /// {{ let ?assert <pat>: <ty> = <expr> ?[as <assert_message>] }}
  // /// ```
  // Let(
  //   asserted: option.Option(Bool),
  //   pat: Pattern,
  //   ty: option.Option(Type),
  //   expr: Expr,
  //   assert_message: option.Option(String),
  // )
  /// ```glt
  /// {% assert <expr> ?[as <assert_message>] %}
  /// ```
  AssertExpr(expr: Expr, assert_message: option.Option(String))
  /// ```glt
  /// {{ <expr> }}
  /// ```
  NodeExpr(Expr)
}

// WIP
pub type Expr {
  Nil
  Int(Int)
  Float(Float)
  Bool(Bool)
  String(String)
  Variable(Idn)
  UnOp(op: UnOperator, expr: Expr)
  // BinOp(
  //   rh: Expr,
  //   op: ,
  //   lh: Expr
  // )
}

pub type UnOperator {
  /// '-'
  Minus
  /// '!'
  Negate
}

pub type Pattern {
  PVar(span: Span, name: Idn)
}

pub type Type
