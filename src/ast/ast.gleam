import chomp/span.{type Span}
import gleam/option
import ir/typings as ir

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
  /// ```glt
  /// {{ let ?assert <pat> ?[: <ty>] = <expr> ?[as <assert_message>] }}
  /// ```
  Let(
    asserted: Bool,
    pat: Pattern,
    ty: option.Option(ir.Type),
    expr: Expr,
    assert_message: option.Option(String),
  )
  /// ```glt
  /// {% assert <expr> ?[as <assert_message>] %}
  /// ```
  AssertExpr(expr: Expr, expr_span: Span, assert_message: option.Option(String))
  /// ```glt
  /// {{ <expr> }}
  /// ```
  NodeExpr(Expr, span: Span)
}

// WIP
pub type Expr {
  Nil
  Int(Int)
  Float(Float)
  Bool(Bool)
  String(String)
  Variable(Idn)
  FieldAccess(field: String, box: Expr)
  UnOp(op: UnOperator, expr: Expr)
  BinOp(lh: Expr, op: BinOperator, rh: Expr)
}

pub type UnOperator {
  /// '-'
  UnopMinus
  /// '!'
  UnopNegate
}

pub type BinOperator {
  /// '-'
  BinopMinusInt
  /// '+'
  BinopPlusInt
  /// '*'
  BinopMultInt
  /// '/'
  BinopDivInt
  /// '-.'
  BinopMinusFloat
  /// '+.'
  BinopPlusFloat
  /// '*.'
  BinopMultFloat
  /// '/.'
  BinopDivFloat
  /// '=='
  BinopEquality
  /// '!='
  BinopInEquality
}

pub type Pattern {
  PatVar(span: Span, name: Idn)
}
