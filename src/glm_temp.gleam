import gleam/io
import gleam/string
import hug
import parser/lexer
import parser/parse

pub type Derived =
  String

@external(erlang, "glm_temp_eff", "fearther_inspect")
pub fn fearther_inspect(term: a) -> String

pub fn main() {
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
      let _ =
        parse.parse(t)
        |> io.debug()

      Nil
    }
    Error(error) -> {
      let assert Ok(#(tg, _)) = error.lexeme |> string.pop_grapheme()
      hug.error(
        containing: content,
        in: "<temp>",
        from: #(error.row, error.col),
        to: #(error.row, error.col + 1),
        message: "SyntaxError: Unexpected token " <> string.inspect(tg),
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
