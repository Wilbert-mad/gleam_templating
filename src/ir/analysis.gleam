import ast/ast
import chomp/span

pub type IRAnalyElm {
  IRAnalyElm(span: span.Span)
}

pub type IrAnalysis {
  IrAnalysis(errors: List(IRAnalyElm), warnings: List(IRAnalyElm))
}

pub type AnalysisState {
  AnalysisState(st: IrAnalysis)
}

pub fn ir_analyze(templ: ast.Templ) -> IrAnalysis {
  templ.body_stms
  todo
}

pub fn analy_tag() {
  todo
}

/// let id ?(: ty) = expr
/// 
pub fn analy_let() {
  todo
}

pub fn analy_expr() {
  todo
}
