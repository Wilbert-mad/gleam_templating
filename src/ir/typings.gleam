import chomp/span.{type Span}
import gleam/option.{type Option}

pub type Type {
  Type(kind: TyKind, span: Span)
}

pub type TyKind {
  /// `<name>?[(...params)]`
  TyNamed(name: String, module: Option(String), params: List(Type))
  /// #(<of>, <...of>)
  TyTuple(of: List(Type))
  /// [<...of>]
  TyArray(of: Type)

  // /// fn(<args>) -> <retn>
  // TyNudeFn(retn: Type, args: List(Type))
  // TyVar(todo)
  // TyHole(name: String)
  /// Tells the ir phase to infer type
  TyInfer
  /// Type can't be determined
  TyUnknown
}
