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
