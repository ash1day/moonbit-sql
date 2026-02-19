/// Internal state for rendering SQL with parameterized queries
priv struct RenderContext {
  mut sql : String
  params : Array[Value]
}

fn RenderContext::new() -> RenderContext {
  { sql: "", params: [] }
}

fn RenderContext::write(self : RenderContext, s : String) -> Unit {
  self.sql = self.sql + s
}

fn RenderContext::write_param(self : RenderContext, value : Value) -> Unit {
  self.params.push(value)
  let n = self.params.length()
  self.sql = self.sql + "$\{n}"
}

fn RenderContext::write_identifier(self : RenderContext, name : String) -> Unit {
  self.sql = self.sql + "\"" + name + "\""
}

/// Render a ColumnRef to SQL
fn render_column_ref(ctx : RenderContext, col : ColumnRef) -> Unit {
  match col {
    Column(name) => ctx.write_identifier(name)
    TableColumn(table, name) => {
      ctx.write_identifier(table)
      ctx.write(".")
      ctx.write_identifier(name)
    }
  }
}

/// Render a BinOp to its SQL operator string
fn binop_to_sql(op : BinOp) -> String {
  match op {
    Eq => "="
    Ne => "<>"
    Lt => "<"
    Le => "<="
    Gt => ">"
    Ge => ">="
    And => "AND"
    Or => "OR"
    Like => "LIKE"
    Add => "+"
    Sub => "-"
    Mul => "*"
    Div => "/"
  }
}

/// Render an Expr to SQL
fn render_expr(ctx : RenderContext, expr : Expr) -> Unit {
  match expr {
    Asterisk => ctx.write("*")
    Column(col_ref) => render_column_ref(ctx, col_ref)
    Value(v) => ctx.write_param(v)
    Binary(left, op, right) => {
      ctx.write("(")
      render_expr(ctx, left)
      ctx.write(" " + binop_to_sql(op) + " ")
      render_expr(ctx, right)
      ctx.write(")")
    }
    Unary(op, expr) => {
      let op_str = match op {
        Not => "NOT "
        Neg => "-"
      }
      ctx.write("(")
      ctx.write(op_str)
      render_expr(ctx, expr)
      ctx.write(")")
    }
    IsNull(expr) => {
      render_expr(ctx, expr)
      ctx.write(" IS NULL")
    }
    IsNotNull(expr) => {
      render_expr(ctx, expr)
      ctx.write(" IS NOT NULL")
    }
    InList(expr, values) => {
      render_expr(ctx, expr)
      ctx.write(" IN (")
      for i, v in values {
        if i > 0 {
          ctx.write(", ")
        }
        render_expr(ctx, v)
      }
      ctx.write(")")
    }
    NotInList(expr, values) => {
      render_expr(ctx, expr)
      ctx.write(" NOT IN (")
      for i, v in values {
        if i > 0 {
          ctx.write(", ")
        }
        render_expr(ctx, v)
      }
      ctx.write(")")
    }
    Between(expr, low, high) => {
      render_expr(ctx, expr)
      ctx.write(" BETWEEN ")
      render_expr(ctx, low)
      ctx.write(" AND ")
      render_expr(ctx, high)
    }
    NotBetween(expr, low, high) => {
      render_expr(ctx, expr)
      ctx.write(" NOT BETWEEN ")
      render_expr(ctx, low)
      ctx.write(" AND ")
      render_expr(ctx, high)
    }
    Func(func_call) => {
      ctx.write(func_call.name)
      ctx.write("(")
      for i, arg in func_call.args {
        if i > 0 {
          ctx.write(", ")
        }
        render_expr(ctx, arg)
      }
      ctx.write(")")
    }
  }
}

/// Render a TableRef to SQL
fn render_table_ref(ctx : RenderContext, table : TableRef) -> Unit {
  match table {
    Table(name) => ctx.write_identifier(name)
    TableAlias(name, als) => {
      ctx.write_identifier(name)
      ctx.write(" AS ")
      ctx.write_identifier(als)
    }
    SchemaTable(schema, name) => {
      ctx.write_identifier(schema)
      ctx.write(".")
      ctx.write_identifier(name)
    }
  }
}

/// Render a SelectItem to SQL
fn render_select_item(ctx : RenderContext, item : SelectItem) -> Unit {
  match item {
    Expr(expr) => render_expr(ctx, expr)
    ExprAlias(expr, als) => {
      render_expr(ctx, expr)
      ctx.write(" AS ")
      ctx.write_identifier(als)
    }
    AllColumns => ctx.write("*")
    TableAllColumns(table) => {
      ctx.write_identifier(table)
      ctx.write(".*")
    }
  }
}

/// Render a JoinType to SQL
fn join_type_to_sql(jt : JoinType) -> String {
  match jt {
    Inner => "INNER JOIN"
    Left => "LEFT JOIN"
    Right => "RIGHT JOIN"
    Full => "FULL JOIN"
    Cross => "CROSS JOIN"
  }
}

/// Render a SELECT statement to a CompiledQuery
pub fn render_select(stmt : SelectStatement) -> CompiledQuery {
  let ctx = RenderContext::new()
  ctx.write("SELECT ")
  if stmt.distinct {
    ctx.write("DISTINCT ")
  }
  // Columns
  if stmt.columns.is_empty() {
    ctx.write("*")
  } else {
    for i, col in stmt.columns {
      if i > 0 {
        ctx.write(", ")
      }
      render_select_item(ctx, col)
    }
  }
  // FROM
  match stmt.from {
    Some(table) => {
      ctx.write(" FROM ")
      render_table_ref(ctx, table)
    }
    None => ()
  }
  // JOINs
  for join in stmt.joins {
    ctx.write(" ")
    ctx.write(join_type_to_sql(join.join_type))
    ctx.write(" ")
    render_table_ref(ctx, join.table)
    match join.join_type {
      Cross => ()
      _ => {
        ctx.write(" ON ")
        render_expr(ctx, join.on)
      }
    }
  }
  // WHERE
  match stmt.where_ {
    Some(expr) => {
      ctx.write(" WHERE ")
      render_expr(ctx, expr)
    }
    None => ()
  }
  // GROUP BY
  if not(stmt.group_by.is_empty()) {
    ctx.write(" GROUP BY ")
    for i, expr in stmt.group_by {
      if i > 0 {
        ctx.write(", ")
      }
      render_expr(ctx, expr)
    }
  }
  // HAVING
  match stmt.having {
    Some(expr) => {
      ctx.write(" HAVING ")
      render_expr(ctx, expr)
    }
    None => ()
  }
  // ORDER BY
  if not(stmt.order_by.is_empty()) {
    ctx.write(" ORDER BY ")
    for i, item in stmt.order_by {
      if i > 0 {
        ctx.write(", ")
      }
      render_expr(ctx, item.expr)
      match item.order {
        Asc => ctx.write(" ASC")
        Desc => ctx.write(" DESC")
      }
    }
  }
  // LIMIT
  match stmt.limit {
    Some(expr) => {
      ctx.write(" LIMIT ")
      render_expr(ctx, expr)
    }
    None => ()
  }
  // OFFSET
  match stmt.offset {
    Some(expr) => {
      ctx.write(" OFFSET ")
      render_expr(ctx, expr)
    }
    None => ()
  }
  { sql: ctx.sql, params: ctx.params }
}

/// Render an INSERT statement to a CompiledQuery
pub fn render_insert(stmt : InsertStatement) -> CompiledQuery {
  let ctx = RenderContext::new()
  ctx.write("INSERT INTO ")
  render_table_ref(ctx, stmt.table)
  // Columns
  if not(stmt.columns.is_empty()) {
    ctx.write(" (")
    for i, col in stmt.columns {
      if i > 0 {
        ctx.write(", ")
      }
      ctx.write_identifier(col)
    }
    ctx.write(")")
  }
  // VALUES
  ctx.write(" VALUES ")
  for i, row in stmt.values {
    if i > 0 {
      ctx.write(", ")
    }
    ctx.write("(")
    for j, expr in row {
      if j > 0 {
        ctx.write(", ")
      }
      render_expr(ctx, expr)
    }
    ctx.write(")")
  }
  // RETURNING
  if not(stmt.returning.is_empty()) {
    ctx.write(" RETURNING ")
    for i, item in stmt.returning {
      if i > 0 {
        ctx.write(", ")
      }
      render_select_item(ctx, item)
    }
  }
  { sql: ctx.sql, params: ctx.params }
}

/// Render an UPDATE statement to a CompiledQuery
pub fn render_update(stmt : UpdateStatement) -> CompiledQuery {
  let ctx = RenderContext::new()
  ctx.write("UPDATE ")
  render_table_ref(ctx, stmt.table)
  ctx.write(" SET ")
  for i, assignment in stmt.assignments {
    if i > 0 {
      ctx.write(", ")
    }
    ctx.write_identifier(assignment.0)
    ctx.write(" = ")
    render_expr(ctx, assignment.1)
  }
  // WHERE
  match stmt.where_ {
    Some(expr) => {
      ctx.write(" WHERE ")
      render_expr(ctx, expr)
    }
    None => ()
  }
  // RETURNING
  if not(stmt.returning.is_empty()) {
    ctx.write(" RETURNING ")
    for i, item in stmt.returning {
      if i > 0 {
        ctx.write(", ")
      }
      render_select_item(ctx, item)
    }
  }
  { sql: ctx.sql, params: ctx.params }
}

/// Render a DELETE statement to a CompiledQuery
pub fn render_delete(stmt : DeleteStatement) -> CompiledQuery {
  let ctx = RenderContext::new()
  ctx.write("DELETE FROM ")
  render_table_ref(ctx, stmt.table)
  // WHERE
  match stmt.where_ {
    Some(expr) => {
      ctx.write(" WHERE ")
      render_expr(ctx, expr)
    }
    None => ()
  }
  // RETURNING
  if not(stmt.returning.is_empty()) {
    ctx.write(" RETURNING ")
    for i, item in stmt.returning {
      if i > 0 {
        ctx.write(", ")
      }
      render_select_item(ctx, item)
    }
  }
  { sql: ctx.sql, params: ctx.params }
}
