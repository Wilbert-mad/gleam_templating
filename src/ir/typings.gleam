import chomp/span.{type Span}

pub type Type {
  Type(kind: TyKind, span: Span)
}

pub type TyKind {
  TyNamed(name: String)
  TyTuple(of: List(Type))
  TyArray(of: Type)
  /// unnamed functions
  /// fn(<args>) -> <retn> {...}
  TyNudeFn(retn: Type, args: List(Type))

  /// Tells the ir phase to infer type
  TyInfer
  /// Type can't be determined
  TyUnknown
}
