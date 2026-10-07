///|
/// Copy all mutable arrays in an expression, including nested SELECTs.
pub fn Expr::snapshot(self : Expr) -> Expr {
  match self {
    Column(_) | Value(_) | Asterisk | Raw(_) => self
    Binary(left, op, right) => Binary(left.snapshot(), op, right.snapshot())
    Unary(op, expr) => Unary(op, expr.snapshot())
    IsNull(expr) => IsNull(expr.snapshot())
    IsNotNull(expr) => IsNotNull(expr.snapshot())
    InList(expr, values) => InList(expr.snapshot(), values.map(Expr::snapshot))
    NotInList(expr, values) =>
      NotInList(expr.snapshot(), values.map(Expr::snapshot))
    Between(expr, low, high) =>
      Between(expr.snapshot(), low.snapshot(), high.snapshot())
    NotBetween(expr, low, high) =>
      NotBetween(expr.snapshot(), low.snapshot(), high.snapshot())
    Func(call) => Func(snapshot_func(call))
    InSubquery(expr, stmt) => InSubquery(expr.snapshot(), stmt.snapshot())
    NotInSubquery(expr, stmt) => NotInSubquery(expr.snapshot(), stmt.snapshot())
    Subquery(stmt) => Subquery(stmt.snapshot())
    Exists(stmt) => Exists(stmt.snapshot())
    NotExists(stmt) => NotExists(stmt.snapshot())
    WindowFunc(call, spec) =>
      WindowFunc(snapshot_func(call), {
        partition_by: spec.partition_by.map(Expr::snapshot),
        order_by: spec.order_by.map(snapshot_order),
      })
    CaseExpr(branches, default) =>
      CaseExpr(
        branches.map(fn(branch) {
          {
            condition: branch.condition.snapshot(),
            result: branch.result.snapshot(),
          }
        }),
        default.map(Expr::snapshot),
      )
  }
}

///|
fn snapshot_func(call : FuncCall) -> FuncCall {
  { name: call.name, args: call.args.map(Expr::snapshot) }
}

///|
fn snapshot_order(item : OrderByItem) -> OrderByItem {
  { expr: item.expr.snapshot(), order: item.order }
}

///|
fn snapshot_table(table : TableRef) -> TableRef {
  match table {
    SubQuery(stmt, als) => SubQuery(stmt.snapshot(), als)
    _ => table
  }
}

///|
fn snapshot_item(item : SelectItem) -> SelectItem {
  match item {
    Expr(expr) => Expr(expr.snapshot())
    ExprAlias(expr, als) => ExprAlias(expr.snapshot(), als)
    AllColumns | TableAllColumns(_) => item
  }
}

///|
/// Return an independent AST: later mutations to the source arrays do not
/// change this statement, and mutations to this statement do not change its source.
pub fn SelectStatement::snapshot(self : SelectStatement) -> SelectStatement {
  {
    distinct: self.distinct,
    columns: self.columns.map(snapshot_item),
    from: self.from.map(snapshot_table),
    joins: self.joins.map(fn(join) {
      {
        join_type: join.join_type,
        table: snapshot_table(join.table),
        on: join.on.snapshot(),
      }
    }),
    where_: self.where_.map(Expr::snapshot),
    group_by: self.group_by.map(Expr::snapshot),
    having: self.having.map(Expr::snapshot),
    order_by: self.order_by.map(snapshot_order),
    limit: self.limit.map(Expr::snapshot),
    offset: self.offset.map(Expr::snapshot),
    set_ops: self.set_ops.map(fn(op) {
      { kind: op.kind, select: op.select.snapshot() }
    }),
    ctes: self.ctes.map(fn(cte) {
      { name: cte.name, query: cte.query.snapshot() }
    }),
  }
}
