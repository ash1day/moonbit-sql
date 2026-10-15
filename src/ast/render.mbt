///|
/// Internal state for rendering SQL with parameterized queries
priv struct RenderContext {
  buf : StringBuilder
  params : Array[Value]
}

///|
fn RenderContext::new() -> RenderContext {
  { buf: StringBuilder::new(), params: [], }
}

///|
fn RenderContext::write(self : RenderContext, s : String) -> Unit {
  self.buf.write_string(s)
}

///|
fn RenderContext::write_param(self : RenderContext, value : Value) -> Unit {
  self.params.push(value)
  let n = self.params.length()
  self.buf.write_string("$\{n}")
}

///|
fn RenderContext::write_identifier(self : RenderContext, name : String) -> Unit {
  let escaped = name.replace_all(old="\"", new="\"\"")
  self.buf.write_string("\"")
  self.buf.write_string(escaped)
  self.buf.write_string("\"")
}

///|
fn RenderContext::to_sql(self : RenderContext) -> String {
  self.buf.to_string()
}

///|
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

///|
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

///|
/// Validate that a function name contains only safe characters
fn validate_func_name(name : String) -> String raise {
  for c in name {
    let valid = (c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      (c >= '0' && c <= '9') ||
      c == '_' ||
      c == '.'
    if !valid {
      raise InvalidFuncName("invalid character in function name: \{name}")
    }
  }
  name
}

///|
/// Memoize only GROUP BY expressions, within one SELECT scope. Equal literal
/// values in unrelated SQL contexts must keep independent parameter identities.
priv struct GroupedExpressions {
  expressions : Array[Expr]
  rendered : Array[(Expr, String)]
}

///|
fn render_expr(
  ctx : RenderContext,
  expr : Expr,
  grouping~ : GroupedExpressions? = None,
) -> Unit raise {
  if grouping is Some(memo) && memo.expressions.contains(expr) {
    match memo.rendered.search_by(fn(item) { item.0 == expr }) {
      Some(index) => ctx.write(memo.rendered[index].1)
      None => {
        let part : RenderContext = {
          buf: StringBuilder::new(),
          params: ctx.params,
        }
        render_expr_body(part, expr, grouping~)
        let sql = part.to_sql()
        memo.rendered.push((expr, sql))
        ctx.write(sql)
      }
    }
  } else {
    render_expr_body(ctx, expr, grouping~)
  }
}

///|
fn render_expr_body(
  ctx : RenderContext,
  expr : Expr,
  grouping~ : GroupedExpressions? = None,
) -> Unit raise {
  match expr {
    Asterisk => ctx.write("*")
    Column(col_ref) => render_column_ref(ctx, col_ref)
    Value(v) => ctx.write_param(v)
    Binary(left, op, right) => {
      ctx.write("(")
      render_expr(ctx, left, grouping~)
      ctx.write(" " + binop_to_sql(op) + " ")
      render_expr(ctx, right, grouping~)
      ctx.write(")")
    }
    Unary(op, expr) => {
      let op_str = match op {
        Not => "NOT "
        Neg => "-"
      }
      ctx.write("(")
      ctx.write(op_str)
      render_expr(ctx, expr, grouping~)
      ctx.write(")")
    }
    IsNull(expr) => {
      render_expr(ctx, expr, grouping~)
      ctx.write(" IS NULL")
    }
    IsNotNull(expr) => {
      render_expr(ctx, expr, grouping~)
      ctx.write(" IS NOT NULL")
    }
    InList(expr, values) =>
      if values.is_empty() {
        ctx.write("FALSE")
      } else {
        render_expr(ctx, expr, grouping~)
        ctx.write(" IN (")
        for i, v in values {
          if i > 0 {
            ctx.write(", ")
          }
          render_expr(ctx, v, grouping~)
        }
        ctx.write(")")
      }
    NotInList(expr, values) =>
      if values.is_empty() {
        ctx.write("TRUE")
      } else {
        render_expr(ctx, expr, grouping~)
        ctx.write(" NOT IN (")
        for i, v in values {
          if i > 0 {
            ctx.write(", ")
          }
          render_expr(ctx, v, grouping~)
        }
        ctx.write(")")
      }
    Between(expr, low, high) => {
      render_expr(ctx, expr, grouping~)
      ctx.write(" BETWEEN ")
      render_expr(ctx, low, grouping~)
      ctx.write(" AND ")
      render_expr(ctx, high, grouping~)
    }
    NotBetween(expr, low, high) => {
      render_expr(ctx, expr, grouping~)
      ctx.write(" NOT BETWEEN ")
      render_expr(ctx, low, grouping~)
      ctx.write(" AND ")
      render_expr(ctx, high, grouping~)
    }
    Func(func_call) => {
      ctx.write(validate_func_name(func_call.name))
      ctx.write("(")
      for i, arg in func_call.args {
        if i > 0 {
          ctx.write(", ")
        }
        render_expr(ctx, arg, grouping~)
      }
      ctx.write(")")
    }
    InSubquery(expr, sub_stmt) => {
      render_expr(ctx, expr, grouping~)
      ctx.write(" IN (")
      render_select_query(ctx, sub_stmt)
      ctx.write(")")
    }
    NotInSubquery(expr, sub_stmt) => {
      render_expr(ctx, expr, grouping~)
      ctx.write(" NOT IN (")
      render_select_query(ctx, sub_stmt)
      ctx.write(")")
    }
    Subquery(sub_stmt) => {
      ctx.write("(")
      render_select_query(ctx, sub_stmt)
      ctx.write(")")
    }
    CaseExpr(branches, else_) => {
      ctx.write("CASE")
      for branch in branches {
        ctx.write(" WHEN ")
        render_expr(ctx, branch.condition, grouping~)
        ctx.write(" THEN ")
        render_expr(ctx, branch.result, grouping~)
      }
      match else_ {
        Some(default) => {
          ctx.write(" ELSE ")
          render_expr(ctx, default, grouping~)
        }
        None => ()
      }
      ctx.write(" END")
    }
    Exists(sub_stmt) => {
      ctx.write("EXISTS (")
      render_select_query(ctx, sub_stmt)
      ctx.write(")")
    }
    NotExists(sub_stmt) => {
      ctx.write("NOT EXISTS (")
      render_select_query(ctx, sub_stmt)
      ctx.write(")")
    }
    Raw(sql) => ctx.write(sql)
    WindowFunc(func_call, win_spec) => {
      ctx.write(validate_func_name(func_call.name))
      ctx.write("(")
      for i, arg in func_call.args {
        if i > 0 {
          ctx.write(", ")
        }
        render_expr(ctx, arg, grouping~)
      }
      ctx.write(") OVER (")
      if !win_spec.partition_by.is_empty() {
        ctx.write("PARTITION BY ")
        for i, expr in win_spec.partition_by {
          if i > 0 {
            ctx.write(", ")
          }
          render_expr(ctx, expr, grouping~)
        }
      }
      if !win_spec.order_by.is_empty() {
        if !win_spec.partition_by.is_empty() {
          ctx.write(" ")
        }
        ctx.write("ORDER BY ")
        for i, item in win_spec.order_by {
          if i > 0 {
            ctx.write(", ")
          }
          render_expr(ctx, item.expr, grouping~)
          match item.order {
            Asc => ctx.write(" ASC")
            Desc => ctx.write(" DESC")
          }
        }
      }
      ctx.write(")")
    }
  }
}

///|
/// Render a TableRef to SQL
fn render_table_ref(ctx : RenderContext, table : TableRef) -> Unit raise {
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
    SubQuery(sub_stmt, als) => {
      ctx.write("(")
      render_select_query(ctx, sub_stmt)
      ctx.write(") AS ")
      ctx.write_identifier(als)
    }
  }
}

///|
/// Render a SelectItem to SQL
fn render_select_item(
  ctx : RenderContext,
  item : SelectItem,
  grouping~ : GroupedExpressions? = None,
) -> Unit raise {
  match item {
    Expr(expr) => render_expr(ctx, expr, grouping~)
    ExprAlias(expr, als) => {
      render_expr(ctx, expr, grouping~)
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

///|
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

///|
/// Render the body of a SELECT statement (without CTEs) into a context
fn render_select_body(
  ctx : RenderContext,
  stmt : SelectStatement,
) -> Unit raise {
  let grouping : GroupedExpressions = {
    expressions: stmt.group_by.filter(fn(expr) {
      match expr {
        Value(_) => false
        _ => true
      }
    }),
    rendered: [],
  }
  // The builder chains left-to-right. INTERSECT has higher SQL precedence,
  // so close a grouped prefix whenever it follows UNION or EXCEPT.
  let grouped_prefixes = stmt.set_ops.mapi(fn(i, op) {
    i > 0 &&
    is_intersection(op.kind) &&
    !is_intersection(stmt.set_ops[i - 1].kind)
  })
  for grouped in grouped_prefixes {
    if grouped {
      ctx.write("(")
    }
  }
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
      render_select_item(ctx, col, grouping=Some(grouping))
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
  if !stmt.group_by.is_empty() {
    ctx.write(" GROUP BY ")
    for i, expr in stmt.group_by {
      if i > 0 {
        ctx.write(", ")
      }
      render_expr(ctx, expr, grouping=Some(grouping))
    }
  }
  // HAVING
  match stmt.having {
    Some(expr) => {
      ctx.write(" HAVING ")
      render_expr(ctx, expr, grouping=Some(grouping))
    }
    None => ()
  }
  // Set operations (UNION, INTERSECT, EXCEPT)
  for i, set_op in stmt.set_ops {
    if grouped_prefixes[i] {
      ctx.write(")")
    }
    let keyword = match set_op.kind {
      Union => " UNION "
      UnionAll => " UNION ALL "
      Intersect => " INTERSECT "
      IntersectAll => " INTERSECT ALL "
      Except => " EXCEPT "
      ExceptAll => " EXCEPT ALL "
    }
    ctx.write(keyword)
    render_set_operand(ctx, set_op.select)
  }
  // ORDER BY
  if !stmt.order_by.is_empty() {
    ctx.write(" ORDER BY ")
    for i, item in stmt.order_by {
      if i > 0 {
        ctx.write(", ")
      }
      render_expr(ctx, item.expr, grouping=Some(grouping))
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
}

///|
fn is_intersection(kind : SetOpKind) -> Bool {
  match kind {
    Intersect | IntersectAll => true
    _ => false
  }
}

///|
/// Parentheses keep an operand's WITH, set operations and trailing clauses local.
fn render_set_operand(
  ctx : RenderContext,
  stmt : SelectStatement,
) -> Unit raise {
  let grouped = !stmt.ctes.is_empty() ||
    !stmt.set_ops.is_empty() ||
    !stmt.order_by.is_empty() ||
    stmt.limit != None ||
    stmt.offset != None
  if grouped {
    ctx.write("(")
  }
  render_select_query(ctx, stmt)
  if grouped {
    ctx.write(")")
  }
}

///|
/// Render WITH and the SELECT into the caller's parameter context.
fn render_select_query(
  ctx : RenderContext,
  stmt : SelectStatement,
) -> Unit raise {
  // CTEs (WITH clause)
  if !stmt.ctes.is_empty() {
    ctx.write("WITH ")
    for i, cte in stmt.ctes {
      if i > 0 {
        ctx.write(", ")
      }
      ctx.write_identifier(cte.name)
      ctx.write(" AS (")
      render_select_query(ctx, cte.query)
      ctx.write(")")
    }
    ctx.write(" ")
  }
  render_select_body(ctx, stmt)
}

///|
/// Render a complete SELECT, preserving WITH at every nesting level.
pub fn render_select(stmt : SelectStatement) -> CompiledQuery raise {
  let ctx = RenderContext::new()
  render_select_query(ctx, stmt)
  { sql: ctx.to_sql(), params: ctx.params, }
}

///|
/// Render an INSERT statement to a CompiledQuery
pub fn render_insert(stmt : InsertStatement) -> CompiledQuery raise {
  let ctx = RenderContext::new()
  ctx.write("INSERT INTO ")
  render_table_ref(ctx, stmt.table)
  // Columns
  if !stmt.columns.is_empty() {
    ctx.write(" (")
    for i, col in stmt.columns {
      if i > 0 {
        ctx.write(", ")
      }
      ctx.write_identifier(col)
    }
    ctx.write(")")
  }
  // VALUES or SELECT
  match stmt.select_ {
    Some(sub_stmt) => {
      ctx.write(" ")
      render_select_query(ctx, sub_stmt)
    }
    None => {
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
    }
  }
  // ON CONFLICT
  match stmt.on_conflict {
    Some(oc) => {
      ctx.write(" ON CONFLICT (")
      for i, col in oc.columns {
        if i > 0 {
          ctx.write(", ")
        }
        ctx.write_identifier(col)
      }
      ctx.write(")")
      match oc.action {
        DoNothing => ctx.write(" DO NOTHING")
        DoUpdate(assignments) => {
          ctx.write(" DO UPDATE SET ")
          for i, assignment in assignments {
            if i > 0 {
              ctx.write(", ")
            }
            ctx.write_identifier(assignment.0)
            ctx.write(" = ")
            render_expr(ctx, assignment.1)
          }
        }
      }
    }
    None => ()
  }
  // RETURNING
  if !stmt.returning.is_empty() {
    ctx.write(" RETURNING ")
    for i, item in stmt.returning {
      if i > 0 {
        ctx.write(", ")
      }
      render_select_item(ctx, item)
    }
  }
  { sql: ctx.to_sql(), params: ctx.params, }
}

///|
/// Render an UPDATE statement to a CompiledQuery
pub fn render_update(stmt : UpdateStatement) -> CompiledQuery raise {
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
  if !stmt.returning.is_empty() {
    ctx.write(" RETURNING ")
    for i, item in stmt.returning {
      if i > 0 {
        ctx.write(", ")
      }
      render_select_item(ctx, item)
    }
  }
  { sql: ctx.to_sql(), params: ctx.params, }
}

///|
/// Render a DELETE statement to a CompiledQuery
pub fn render_delete(stmt : DeleteStatement) -> CompiledQuery raise {
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
  if !stmt.returning.is_empty() {
    ctx.write(" RETURNING ")
    for i, item in stmt.returning {
      if i > 0 {
        ctx.write(", ")
      }
      render_select_item(ctx, item)
    }
  }
  { sql: ctx.to_sql(), params: ctx.params, }
}
