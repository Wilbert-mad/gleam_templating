import ast/ast
import gleam/int
import gleam/list
import gleam/result
import gleam/string

fn strwrap(t: String) -> String {
  "\"" <> t <> "\""
}

pub type CompilerState {
  CompilerState(
    /// The index of insertion the the stack buffer output for the
    /// template inside of the erlang expression
    /// `OutBuff@<buff_indx>` eg `OutBuff@2`
    buff_index: Int,
    buff_out: List(String),
    /// global struct index
    /// `Globals@<g_mut_count>` eg `Globals@2`
    g_mut_count: Int,
  )
}

pub fn compile(templ: ast.Templ) {
  let state = compile_start()
  let state = compile_stam(state, unwrapf(list.first(templ.body_stms)))
  string.join(compile_end(state).buff_out, "")
}

fn unwrapf(r: Result(v, e)) -> v {
  case r {
    Ok(v) -> v
    Error(e) -> panic as string.inspect(e)
  }
}

fn compile_start() -> CompilerState {
  CompilerState(buff_index: 0, g_mut_count: 0, buff_out: [
    "fun(Data)when is_map(Data)->", "Globals@0=#{data=>Data},", "OutBuff@0=[],",
  ])
}

fn compile_end(cs: CompilerState) -> CompilerState {
  CompilerState(
    ..cs,
    buff_out: list.append(cs.buff_out, [
      "gleam@string:join(" <> compose_buffname(cs.buff_index) <> ",\"\")",
      // close off func
      "end.",
    ]),
  )
}

fn compile_stam(cs: CompilerState, stm: ast.BodyStm) -> CompilerState {
  case stm {
    // take care of purly text nodes
    ast.BodyStm(display: ast.StaticDisplay, node: ast.Text(txt), ..) -> {
      CompilerState(
        buff_out: list.append(cs.buff_out, [compose_tx_node(txt, cs.buff_index)]),
        buff_index: cs.buff_index + 1,
        g_mut_count: todo,
      )
    }
    _ -> panic
  }
}

/// intended to take in text, and buff index; reutrning-
/// ```
/// OutBuff@1=OutBuff@0++[<txt>],
/// ```
fn compose_tx_node(txt: String, buff_index: Int) -> String {
  compose_buffname(buff_index + 1)
  <> "="
  <> compose_buffname(buff_index)
  <> "++"
  <> "["
  <> strwrap(txt)
  <> "],"
}

fn compose_buffname(buff_index: Int) -> String {
  "OutBuff@" <> int.to_string(buff_index)
}
