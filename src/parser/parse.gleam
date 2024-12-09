import ast/ast
import chomp/lexer as chp
import chomp/span
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import parser/errs
import parser/token as t

type TkList =
  List(chp.Token(t.Token))

pub type ParsingError {
  ParsingError(
    message: errs.ParseErrorKind,
    hint: option.Option(String),
    /// None = EOF error span
    span: option.Option(span.Span),
  )
}

pub type ParseResult {
  ParseResult(template: ast.Templ, errors: List(ParsingError))
}

pub fn parse(tokens: TkList) -> ParseResult {
  let #(tmp, errs) = parse_guard(tokens, ast.Templ(body_stms: []), [])
  ParseResult(template: tmp, errors: errs)
}

fn parse_guard(
  tokens: TkList,
  safe_temp: ast.Templ,
  errors: List(ParsingError),
) -> #(ast.Templ, List(ParsingError)) {
  case
    tokens
    |> parse_temp(safe_temp)
  {
    Ok(tmp) -> #(tmp, errors)
    Error(#(err, state_saved_tmp, remaning_toks)) ->
      // TODO: push `ast.Error` node instead?
      parse_guard(remaning_toks, state_saved_tmp, list.append(errors, [err]))
  }
}

fn parse_temp(
  tokens: TkList,
  temp: ast.Templ,
) -> Result(ast.Templ, #(ParsingError, ast.Templ, TkList)) {
  case tokens {
    [chp.Token(value: t.Text(tx), span:, ..), ..tks] -> {
      ast.Templ(body_stms: [
        ast.BodyStm(span:, node: ast.Text(tx), display: ast.StaticDisplay),
        ..temp.body_stms
      ])
      |> parse_temp(tks, _)
    }
    [chp.Token(value: t.LeftExprTag, span:, ..), ..tokr] -> {
      // Error recovery for individual tags
      case parse_expr_tag(tokr, safe_eof_erring_sp: span) {
        Ok(#(node, tok)) -> {
          ast.Templ(body_stms: [
            ast.BodyStm(span:, node: node, display: ast.Display),
            ..temp.body_stms
          ])
          |> parse_temp(tok, _)
        }
        Error(e) -> {
          case
            tokr
            |> skip_until(t.RightExprTag)
          {
            Error(Nil) -> Error(#(e, temp, []))
            Ok(toks) -> {
              Error(#(e, temp, toks))
            }
          }
        }
      }
    }
    [] -> Ok(ast.Templ(body_stms: list.reverse(temp.body_stms)))
    [tk, ..rest] -> {
      Error(#(
        ParsingError(
          message: errs.UnexpectedToken({ tk |> string.inspect }),
          hint: option.None,
          span: option.Some(tk.span),
        ),
        temp,
        rest,
      ))
    }
  }
}

fn parse_expr_tag(
  tokens: TkList,
  safe_eof_erring_sp eof_spn: span.Span,
) -> Result(#(ast.Node, TkList), ParsingError) {
  // protect from empty set of tokens (EOF error) being passed to parse_stam (which cant handle it)
  use <-
    fn(func) {
      case tokens {
        [] -> Error(eof_err(option.Some(eof_spn)))
        _ -> func()
      }
    }

  // todo parse multiple statments not just one
  use #(node, _stm_spn, tks) <- result.try(parse_stam(tokens))

  case tks {
    [chp.Token(value: t.RightExprTag, ..), ..tokens] -> Ok(#(node, tokens))
    [chp.Token(value: t.RightLogicTag, ..), ..tokens] -> Ok(#(node, tokens))
    [tk, ..] ->
      Error(ParsingError(
        message: errs.UnexpectedToken({ tk |> string.inspect }),
        hint: option.None,
        span: option.Some(tk.span),
      ))
    [] -> {
      let assert Ok(tk) = list.last(tokens)
      Error(eof_err(option.Some(tk.span)))
    }
  }
}

fn parse_stam(
  tokens: TkList,
) -> Result(#(ast.Node, span.Span, TkList), ParsingError) {
  case tokens {
    [chp.Token(value: t.KW(t.Assert), span:, ..), ..tks] -> {
      use #(n, nspan, tkrest) <- result.try(parse_assert_stm(tks))
      // Add the span of the kw 'assert'
      Ok(#(n, span.combine(span, nspan), tkrest))
    }
    [chp.Token(value: t.KW(t.Let), span:, ..), ..tks] -> {
      use #(n, nspan, tkrest) <- result.try(parse_let_stm(tks))
      // Add the span of the kw 'let'
      Ok(#(n, span.combine(span, nspan), tkrest))
    }
    [chp.Token(value: t.Ident(_), ..), ..]
    | [chp.Token(value: t.Int(_), ..), ..]
    | [chp.Token(value: t.Float(_), ..), ..]
    | [chp.Token(value: t.String(_), ..), ..] -> {
      use #(expr, sp, tk) <- result.try(parse_expr(tokens))
      Ok(#(ast.NodeExpr(expr, sp), sp, tk))
    }
    [tk, ..] ->
      Error(ParsingError(
        message: errs.UnexpectedToken({ tk |> string.inspect }),
        hint: option.None,
        span: option.Some(tk.span),
      ))
    [] -> {
      panic as "fn parse_stam() should be safe guarded from empty token lists"
    }
  }
}

fn parse_assert_stm(
  tokens: TkList,
) -> Result(#(ast.Node, span.Span, TkList), ParsingError) {
  use #(expr, sp, tokens) <- result.try(parse_expr(tokens))
  use #(message, sp_msg, tokens) <- result.try(parse_assert_stm_as(tokens))

  let assert_span = {
    case sp_msg {
      option.None -> sp
      option.Some(sp_msg) -> span.combine(sp, sp_msg)
    }
  }

  Ok(#(
    ast.AssertExpr(expr: expr, expr_span: sp, assert_message: message),
    assert_span,
    tokens,
  ))
}

fn parse_assert_stm_as(
  tokens: TkList,
) -> Result(
  #(option.Option(String), option.Option(span.Span), TkList),
  ParsingError,
) {
  case tokens {
    [chp.Token(value: t.KW(t.As), span:, ..), ..tks] -> {
      case tks {
        [chp.Token(value: t.String(str), span: sp2, ..), ..tks] -> {
          Ok(#(option.Some(str), option.Some(sp2), tks))
        }
        [t, ..] ->
          Error(ParsingError(
            message: errs.AssertExpectedMessage,
            hint: option.None,
            span: option.Some(t.span),
          ))
        [] -> Error(eof_err(option.Some(span)))
      }
    }
    tks -> Ok(#(option.None, option.None, tks))
  }
}

fn parse_let_stm(
  tokens: TkList,
) -> Result(#(ast.Node, span.Span, TkList), ParsingError) {
  let #(asserted, tokens) = {
    case tokens {
      [chp.Token(value: t.KW(t.Assert), ..), ..tks] -> #(True, tks)
      _ -> #(False, tokens)
    }
  }

  use #(pat, tokens) <- result.try(parse_pattern(tokens))

  use tokens <- check_next_tk(tokens, want: t.Equal, expecting: "=")
  use #(expr, exprspan, tokens) <- result.try(parse_expr(tokens))
  use #(message, mspan, tokens) <- result.try(parse_assert_stm_as(tokens))

  // Resturns the span of the `let` statment to either the end of the expression or
  // to the end of the `as <message>` segment.
  let let_stm_span: span.Span = {
    case mspan {
      option.Some(s) -> s
      option.None -> exprspan
    }
  }

  Ok(#(
    ast.Let(
      asserted:,
      pat: pat,
      // TODO support types
      ty: option.None,
      expr:,
      assert_message: message,
      assert_span: mspan,
    ),
    let_stm_span,
    tokens,
  ))
}

fn parse_expr(tokens) -> Result(#(ast.Expr, span.Span, TkList), ParsingError) {
  // TODO: precheck for unarys
  use #(lhs, sp, tokens) <- result.try(parse_expr_inner(tokens))

  case tokens {
    [chp.Token(value: t.EqualEqual, ..), ..tks] -> {
      use #(rhs, sp2, tokens) <- result.try(parse_expr(tks))
      let expr = ast.BinOp(lh: lhs, op: ast.BinopEquality, rh: rhs)
      Ok(#(expr, span.combine(sp, sp2), tokens))
    }
    _ -> {
      Ok(#(lhs, sp, tokens))
    }
  }
}

/// Basic inner expression
/// 1 -> Int
/// 1.0 -> Float
/// False -> Bool
/// ".." -> String
/// a -> Variable
/// a.b -> FieldAccess
fn parse_expr_inner(
  tokens: TkList,
) -> Result(#(ast.Expr, span.Span, TkList), ParsingError) {
  use #(tk, tokens) <- result.try(case list.pop(tokens, fn(_) { True }) {
    Ok(v) -> Ok(v)
    // Handle EOF error expecting expression
    Error(Nil) ->
      Error(lookahead_err(
        message: errs.ExpectedToken(found: "<EOF>", expected: "<expression>"),
        hint: option.None,
        span: option.None,
      ))
  })

  case tk {
    // Boolean
    chp.Token(value: t.Ident(id), span:, ..) if id == "False" || id == "True" -> {
      Ok(#(
        ast.Bool({
          case id == "True" {
            True -> True
            False -> False
          }
        }),
        span,
        tokens,
      ))
    }
    // String
    chp.Token(value: t.String(str), span:, ..) -> {
      Ok(#(ast.String(str), span, tokens))
    }
    // Int
    chp.Token(value: t.Int(i), span:, ..) -> {
      Ok(#(ast.Int(i), span, tokens))
    }
    // Float
    chp.Token(value: t.Float(f), span:, ..) -> {
      Ok(#(ast.Float(f), span, tokens))
    }
    // Variable
    chp.Token(value: t.Ident(id), span:, ..) -> {
      Ok(#(ast.Variable(id), span, tokens))
    }
    tk ->
      Error(ParsingError(
        message: errs.UnexpectedSimpleExpr({ tk |> string.inspect }),
        hint: option.None,
        span: option.Some(tk.span),
      ))
  }
}

fn parse_pattern(tokens: TkList) -> Result(#(ast.Pattern, TkList), ParsingError) {
  case tokens {
    // Variable and DiscordVar
    [chp.Token(value: t.Ident(id), span:, ..), ..toks] -> {
      case string.starts_with(id, "_") {
        True -> Ok(#(ast.Pattern(kind: ast.PatDiscordVar(id), span:), toks))
        False -> Ok(#(ast.Pattern(kind: ast.PatVar(id), span:), toks))
      }
    }
    _ -> todo
  }
}

/// Check if the next token is if `want` and errors `ExpectedToken`
/// if the `want` tokens is not matched. `expecting` used to pretty display token.
fn check_next_tk(
  tokens: TkList,
  want want: t.Token,
  expecting expecting: String,
  f func: fn(TkList) -> Result(r, ParsingError),
) -> Result(r, ParsingError) {
  result.try(
    {
      case tokens {
        [chp.Token(value:, ..), ..toks] if value == want -> Ok(toks)
        [chp.Token(span:, lexeme:, ..), ..] ->
          Error(ParsingError(
            message: errs.ExpectedToken(found: lexeme, expected: expecting),
            hint: option.None,
            span: option.Some(span),
          ))
        [] -> Error(eof_err(option.None))
      }
    },
    func,
  )
}

/// Privides simple error recovery pre tag
fn skip_until(tokens: TkList, tk: t.Token) -> Result(TkList, Nil) {
  case tokens {
    [chp.Token(value:, ..), ..rest] if value == tk -> {
      Ok(rest)
    }
    [_token, ..rest] -> skip_until(rest, tk)
    [] -> Error(Nil)
  }
}

pub fn eof_err(span: option.Option(span.Span)) -> ParsingError {
  lookahead_err(errs.EOFErr, option.None, span)
}

pub fn lookahead_err(
  message message: errs.ParseErrorKind,
  hint hint: option.Option(String),
  span span: option.Option(span.Span),
) {
  ParsingError(message:, hint:, span: {
    case span {
      // shift by one to demenstrate token ahead not at
      option.Some(span) -> {
        span.Span(..span, col_start: span.col_end, col_end: span.col_end + 1)
        |> option.Some
      }
      option.None -> option.None
    }
  })
}
