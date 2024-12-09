// import ast/ast
// import chomp/span
// import compile/compiler
// import gleam/bit_array
// import gleam/bytes_builder
import gleam/dict
import gleam/io
import gleam/iterator
import gleam/list
import gleam/option
import gleam/string
import hug
import ir/analysis
import parser/errs
import parser/lexer
import parser/parse

pub type Derived =
  String

@external(erlang, "glm_temp_eff", "buffer_testing")
pub fn buffer_testing(frags: a) -> fn(dict.Dict(String, any)) -> String

pub fn main() {
  // buffer_testing(
  //   ast.Templ([
  //     ast.BodyStm(span.Span(1, 1, 1, 1), ast.Text(""), ast.StaticDisplay),
  //     ast.BodyStm(
  //       span.Span(1, 1, 1, 3),
  //       ast.Let(
  //         False,
  //         ast.Pattern(ast.PatVar("who"), span.Span(1, 8, 1, 11)),
  //         option.None,
  //         ast.Variable("name"),
  //         option.None,
  //         option.None,
  //       ),
  //       ast.Display,
  //     ),
  //     ast.BodyStm(
  //       span.Span(1, 21, 2, 8),
  //       ast.Text("\nHello, "),
  //       ast.StaticDisplay,
  //     ),
  //     ast.BodyStm(
  //       span.Span(2, 8, 2, 10),
  //       ast.NodeExpr(ast.Variable("who"), span.Span(2, 11, 2, 14)),
  //       ast.Display,
  //     ),
  //   ]),
  // )(dict.from_list([#("name", "Iesha")]))
  // |> io.debug
  // compiler.compile(
  //   ast.Templ([
  //     ast.BodyStm(
  //       span.Span(1, 21, 2, 8),
  //       ast.Text("\nHello, "),
  //       ast.StaticDisplay,
  //     ),
  //   ]),
  // )
  // |> io.debug
  my_template()
}

pub fn my_template() -> Derived {
  derived(
    file: "templates/main.glt",
    // vars: dict.from_list([#("name", String("Iesha"))]),
  )
}

pub fn derived(file file: String) {
  let assert True = string.ends_with(file, "glt")
  let assert Ok(content) = read_file(file)
  let _ = case lexer.lex(content) {
    Ok(t) -> {
      let _ = case parse.parse(t) {
        parse.ParseResult(errors: [], template: ast) -> {
          ast
          |> analysis.ir_analyze
          |> io.debug
          Nil
        }
        parse.ParseResult(template: _, errors:) -> {
          iterator.each(iterator.from_list(errors), fn(parse_err) {
            let err_span = {
              case parse_err.span {
                option.Some(span) -> span
                option.None -> {
                  let assert Ok(lt) = list.last(t)
                  let assert option.Some(s) =
                    { option.Some(lt.span) |> parse.eof_err() }.span
                  s
                }
              }
            }

            hug.error(
              containing: content,
              in: "<temp>",
              from: #(err_span.row_start, err_span.col_start),
              to: #(err_span.row_end, err_span.col_end),
              message: errs.parse_err_message(parse_err.message),
              hint: option.unwrap(parse_err.hint, ""),
            )
            |> io.print_error
          })

          Nil
        }
      }

      Nil
    }

    Error(error) -> {
      let assert Ok(#(tg, _)) = error.lexeme |> string.pop_grapheme()
      hug.error(
        containing: content,
        in: "<temp>",
        from: #(error.row, error.col),
        to: #(error.row, error.col + 1),
        message: "Unexpected token " <> string.inspect(tg),
        hint: "",
      )
      |> io.println_error
      Nil
    }
  }

  todo
}

@external(erlang, "file", "read_file")
pub fn read_file(file_name: String) -> Result(String, a)
