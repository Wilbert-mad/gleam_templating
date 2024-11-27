import ast/ast
import chomp/lexer as chp
import gleam/io
import gleam/list
import parser/token as t

type TkList =
  List(chp.Token(t.Token))

pub fn parse(tokens: TkList) {
  tokens
  |> parse_temp(ast.Templ(body_stms: []))
}

pub fn parse_temp(tokens: TkList, temp: ast.Templ) -> Result(ast.Templ, Nil) {
  case tokens {
    [chp.Token(value: t.Text(tx), span:, ..), ..tks] -> {
      ast.Templ(body_stms: [
        ast.BodyStm(span:, node: ast.Text(tx), display: ast.StaticDisplay),
        ..temp.body_stms
      ])
      |> parse_temp(tks, _)
    }
    [chp.Token(value: t.LeftExprTag, span:, ..), ..tok] -> {
      let #(node, tok) = parse_expr_tag(tok)
      ast.Templ(body_stms: [
        ast.BodyStm(span:, node: node, display: ast.Display),
        ..temp.body_stms
      ])
      |> parse_temp(tok, _)
    }
    [] -> Ok(ast.Templ(body_stms: list.reverse(temp.body_stms)))
    _tokens -> {
      Error(Nil)
    }
  }
}

fn parse_expr_tag(tokens: TkList) -> #(ast.Node, TkList) {
  // todo parse multiple statments not just one

  parse_stam(tokens)
  |> io.debug
  todo
}

fn parse_stam(tokens: TkList) -> #(ast.Node, TkList) {
  case tokens {
    [chp.Token(value: t.KW(t.Assert), span:, ..), ..tks] -> {
      parse_assert_stm(tks)
    }
    [chp.Token(value: t.KW(t.Let), span:, ..), ..tks] -> todo
    _ -> todo
  }
}

fn parse_assert_stm(tokens: TkList) -> #(ast.Node, TkList) {
  tokens |> io.debug
  let #(expr, tokens) = parse_expr(tokens)
  #(ast.AssertExpr(expr: todo, assert_message: todo), tokens)
}

fn parse_expr(tokens) -> #(ast.Expr, TkList) {
  todo
}
