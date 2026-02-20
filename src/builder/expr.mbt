/// Helper functions for constructing Expr values

/// Create a column reference expression
pub fn col(name : String) -> @ast.Expr {
  @ast.Expr::Column(@ast.ColumnRef::Column(name))
}

/// Create a table-qualified column reference expression
pub fn table_col(table : String, name : String) -> @ast.Expr {
  @ast.Expr::Column(@ast.ColumnRef::TableColumn(table, name))
}

/// Create an integer value expression
pub fn val_int(v : Int) -> @ast.Expr {
  @ast.Expr::Value(@ast.Value::Int(v))
}

/// Create a string value expression
pub fn val_str(v : String) -> @ast.Expr {
  @ast.Expr::Value(@ast.Value::String(v))
}

/// Create a boolean value expression
pub fn val_bool(v : Bool) -> @ast.Expr {
  @ast.Expr::Value(@ast.Value::Bool(v))
}

/// Create a double value expression
pub fn val_double(v : Double) -> @ast.Expr {
  @ast.Expr::Value(@ast.Value::Double(v))
}

/// Create an Int64 value expression
pub fn val_int64(v : Int64) -> @ast.Expr {
  @ast.Expr::Value(@ast.Value::Int64(v))
}

/// Create a null value expression
pub fn val_null() -> @ast.Expr {
  @ast.Expr::Value(@ast.Value::Null)
}

/// Validate that a function name contains only safe characters
fn validate_builder_func_name(name : String) -> Unit raise {
  for c in name {
    let valid = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' &&
    c <= '9') || c == '_' || c == '.'
    if not(valid) {
      raise InvalidFuncName(name)
    }
  }
}

/// Create a function call expression
pub fn func(name : String, args : Array[@ast.Expr]) -> @ast.Expr raise {
  validate_builder_func_name(name)
  @ast.Expr::Func({ name, args })
}

/// Create an asterisk expression
pub fn asterisk() -> @ast.Expr {
  @ast.Expr::Asterisk
}

/// Create a window function expression
pub fn window_func(
  name : String,
  args : Array[@ast.Expr],
  partition_by~ : Array[String] = [],
  order_by~ : Array[(String, @ast.Order)] = []
) -> @ast.Expr raise {
  validate_builder_func_name(name)
  let partition_exprs = partition_by.map(
    fn(c) { @ast.Expr::Column(@ast.ColumnRef::Column(c)) },
  )
  let order_items = order_by.map(
    fn(item) {
      ({
        expr: @ast.Expr::Column(@ast.ColumnRef::Column(item.0)),
        order: item.1,
      } : @ast.OrderByItem)
    },
  )
  @ast.Expr::WindowFunc(
    { name, args },
    { partition_by: partition_exprs, order_by: order_items },
  )
}

/// IN subquery check using SelectBuilder
pub fn in_sub(expr : @ast.Expr, sub : SelectBuilder) -> @ast.Expr {
  expr.in_subquery(sub.build_statement())
}

/// NOT IN subquery check using SelectBuilder
pub fn not_in_sub(expr : @ast.Expr, sub : SelectBuilder) -> @ast.Expr {
  expr.not_in_subquery(sub.build_statement())
}

/// EXISTS subquery check using SelectBuilder
pub fn exists_(sub : SelectBuilder) -> @ast.Expr {
  @ast.Expr::Exists(sub.build_statement())
}

/// NOT EXISTS subquery check using SelectBuilder
pub fn not_exists(sub : SelectBuilder) -> @ast.Expr {
  @ast.Expr::NotExists(sub.build_statement())
}

/// Inject raw SQL verbatim — use only when no typed builder method covers the use case.
/// The string is written as-is with no escaping or parameterization.
/// Warning: never pass user input here; it will not be sanitized.
pub fn raw(sql : String) -> @ast.Expr {
  @ast.Expr::Raw(sql)
}

/// Builder for CASE WHEN ... THEN ... ELSE ... END expressions
pub struct CaseBuilder {
  branches : Array[@ast.WhenClause]
  mut else_ : @ast.Expr?
}

/// Start a CASE expression
pub fn case_() -> CaseBuilder {
  { branches: [], else_: None }
}

/// Add a WHEN condition THEN result clause
pub fn CaseBuilder::when_(
  self : CaseBuilder,
  cond : @ast.Expr,
  then : @ast.Expr
) -> CaseBuilder {
  self.branches.push({ condition: cond, result: then })
  self
}

/// Add an ELSE clause
pub fn CaseBuilder::else_(self : CaseBuilder, default : @ast.Expr) -> CaseBuilder {
  self.else_ = Some(default)
  self
}

/// Finish building the CASE expression
pub fn CaseBuilder::end(self : CaseBuilder) -> @ast.Expr raise {
  if self.branches.is_empty() {
    raise EmptyWhenClauses("CASE requires at least one WHEN clause")
  }
  @ast.Expr::CaseExpr(self.branches, self.else_)
}
