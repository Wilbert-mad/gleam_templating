// https://linear.app/

import chomp/lexer
import gleam/set
import parser/token

pub type Lx =
  lexer.Lexer(token.Token, LexMode)

pub type LexMode {
  Txt
  CommentTag
  /// {{ }} -> Expression Blocks that return their result
  /// {% %} -> Logical Blocks that only evals content
  Block
}

pub fn lex(source: String) {
  lexer.run_advanced(source, Txt, gen_lex())
}

pub fn gen_lex() -> Lx {
  let whitespace = lexer.whitespace(Nil)
  let left_curly = lexer.token("(", token.LeftCurly)
  let right_curly = lexer.token(")", token.RightCurly)
  let left_brace = lexer.token("[", token.LeftBrace)
  let right_brace = lexer.token("]", token.RightBrace)
  let left_bracket = lexer.token("{", token.LeftBracket)
  let right_bracket = lexer.token("}", token.RightBracket)
  let minus = lexer.token("-", token.Minus)
  let plus = lexer.token("+", token.Plus)
  let mult = lexer.token("*", token.Mult)
  let slash = lexer.token("/", token.Slash)
  let gt = lexer.token(">", token.Gt)
  let lt = lexer.token("<", token.Lt)
  let kw_macro = lexer.keyword("macro", "\\W", token.KW(token.Macro))
  let kw_let = lexer.keyword("let", "\\W", token.KW(token.Let))
  let kw_end = lexer.keyword("end", "\\W", token.KW(token.End))
  let kw_case = lexer.keyword("case", "\\W", token.KW(token.Case))
  let kw_extends = lexer.keyword("extends", "\\W", token.KW(token.Extends))
  let kw_assert = lexer.keyword("assert", "\\W", token.KW(token.Assert))
  let kw_use = lexer.keyword("use", "\\W", token.KW(token.Use))
  let kw_todo = lexer.keyword("todo", "\\W", token.KW(token.Todo))
  let kw_panic = lexer.keyword("panic", "\\W", token.KW(token.Panic))
  let string = lexer.string("\"", fn(str) { token.String(str) })
  let ident =
    lexer.identifier(
      "[a-zA-Z]",
      "[a-zA-Z0-9_]",
      set.from_list([
        "macro", "let", "end", "case", "extends", "assert", "use", "todo",
        "panic",
      ]),
      token.Ident,
    )

  let text =
    lexer.keep(fn(txt, lookahead) {
      case lookahead {
        "{" | "" -> Ok(token.Text(txt))
        _ -> Error(Nil)
      }
    })

  let block_kws = [
    kw_macro,
    kw_let,
    kw_end,
    kw_case,
    kw_extends,
    kw_assert,
    kw_use,
    kw_todo,
    kw_panic,
  ]

  let block = [
    ident,
    string,
    // lx_num(),
    sided_arrow(),
    dotdot_or_dot(),
    left_curly,
    right_curly,
    left_bracket,
    right_bracket,
    left_brace,
    right_brace,
    equal_equal_or_equal(),
    minus,
    plus,
    mult,
    slash,
    gt_lt_e(),
    gt,
    lt,
    ..block_kws
  ]

  use mode <- lexer.advanced()

  case mode {
    Txt -> [initializing_left_tag(), text]
    Block -> [terminating_right_tag(), whitespace |> lexer.ignore(), ..block]
    CommentTag -> [comment_content()]
  }
}

fn lx_num() {
  use mode, tx, lookagead <- lexer.custom()

  todo
}

fn equal_equal_or_equal() {
  use mode, tx, lookahead <- lexer.custom()

  case tx, lookahead {
    "", "=" -> lexer.Skip(mode)
    "=", "=" -> lexer.Skip(mode)

    "==", _ -> lexer.Keep(token.EqualEqual, Block)
    "=", _ -> lexer.Keep(token.Equal, Block)
    _, _ -> lexer.NoMatch
  }
}

/// Matches either '<=' or '>='
fn gt_lt_e() {
  use mode, tx, lookahead <- lexer.custom()

  case tx, lookahead {
    "", ">" -> lexer.Skip(mode)
    ">", "=" -> lexer.Skip(mode)
    ">=", _ -> lexer.Keep(token.Gte, Block)

    "", "<" -> lexer.Skip(mode)
    "<", "=" -> lexer.Skip(mode)
    "<=", _ -> lexer.Keep(token.Lte, Block)

    _, _ -> lexer.NoMatch
  }
}

/// Matches either '->' or '<-'
fn sided_arrow() {
  use mode, tx, lookahead <- lexer.custom()

  case tx, lookahead {
    "", "-" -> lexer.Skip(mode)
    "-", ">" -> lexer.Skip(mode)
    "->", _ -> lexer.Keep(token.RightArrow, Block)

    "", "<" -> lexer.Skip(mode)
    "<", "-" -> lexer.Skip(mode)
    "<-", _ -> lexer.Keep(token.LeftArrow, Block)
    _, _ -> lexer.NoMatch
  }
}

/// Matches either '..' or '.'
fn dotdot_or_dot() {
  use mode, tx, lookahead <- lexer.custom()

  case tx, lookahead {
    "", "." -> lexer.Skip(mode)
    ".", "." -> lexer.Skip(mode)
    ".", _ -> lexer.Keep(token.Dot, Block)
    "..", _ -> lexer.Keep(token.DotDot, Block)
    _, _ -> lexer.NoMatch
  }
}

fn initializing_left_tag() {
  use mode, tx, lookahead <- lexer.custom()

  case tx, lookahead {
    "", "{" -> lexer.NoMatch

    "{", "{" -> lexer.Skip(mode)
    "{", "%" -> lexer.Skip(mode)
    "{", "#" -> lexer.Skip(mode)

    "{{", _ -> lexer.Keep(token.LeftExprTag, Block)
    "{%", _ -> lexer.Keep(token.LeftLogicTag, Block)
    "{#", _ -> lexer.Drop(CommentTag)

    _, _ -> lexer.NoMatch
  }
}

fn terminating_right_tag() {
  use mode, tx, lookahead <- lexer.custom()

  case tx, lookahead {
    "", "}" -> lexer.Skip(mode)
    "", "%" -> lexer.Skip(mode)

    "}", "}" -> lexer.Skip(mode)
    "}}", _ -> lexer.Keep(token.RightExprTag, Txt)

    "%", "}" -> lexer.Skip(mode)
    "%}", _ -> lexer.Keep(token.RightLogicTag, Txt)

    _, _ -> lexer.NoMatch
  }
}

fn comment_content() {
  use mode, tx, lookahead <- lexer.custom()

  case tx, lookahead {
    "", "#" -> lexer.Skip(mode)
    "#", "}" -> lexer.Skip(mode)
    "#}", _ -> lexer.Drop(Txt)

    _, _ -> lexer.Drop(mode)
  }
}
