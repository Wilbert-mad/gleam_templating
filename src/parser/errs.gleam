pub type ParseErrorKind {
  EOFErr
  UnexpectedSimpleExpr(tk: String)
  UnexpectedToken(tk: String)
  AssertExpectedMessage
  ExpectedToken(found: String, expected: String)
}

pub fn parse_err_message(kind: ParseErrorKind) -> String {
  case kind {
    EOFErr -> "Unexpected end of input"
    AssertExpectedMessage -> "Expected a string message after `as`"
    UnexpectedToken(tk:) -> "Unexpected token occered: " <> tk
    UnexpectedSimpleExpr(tk:) -> "Unexpected expression: " <> tk
    ExpectedToken(found:, expected:) ->
      "Was expecting `" <> expected <> "` but found `" <> found <> "`"
  }
}
