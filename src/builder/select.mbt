/// Builder for SELECT statements
pub struct SelectBuilder {
  mut distinct_ : Bool
  columns : Array[@ast.SelectItem]
  mut from_ : @ast.TableRef?
  joins_ : Array[@ast.JoinClause]
  mut where_ : @ast.Expr?
  group_by_ : Array[@ast.Expr]
  mut having_ : @ast.Expr?
  order_by_ : Array[@ast.OrderByItem]
  mut limit_ : Int?
  mut offset_ : Int?
  set_ops_ : Array[@ast.SetOperation]
  ctes_ : Array[@ast.CTE]
}

/// Create a new SelectBuilder
pub fn select() -> SelectBuilder {
  {
    distinct_: false,
    columns: [],
    from_: None,
    joins_: [],
    where_: None,
    group_by_: [],
    having_: None,
    order_by_: [],
    limit_: None,
    offset_: None,
    set_ops_: [],
    ctes_: [],
  }
}

/// Set SELECT DISTINCT
pub fn SelectBuilder::distinct(self : SelectBuilder) -> SelectBuilder {
  self.distinct_ = true
  self
}

/// Add multiple columns by name
pub fn SelectBuilder::columns(self : SelectBuilder, cols : Array[String]) -> SelectBuilder {
  for c in cols {
    self.columns.push(
      @ast.SelectItem::Expr(@ast.Expr::Column(@ast.ColumnRef::Column(c))),
    )
  }
  self
}

/// Add a single column by name
pub fn SelectBuilder::column(self : SelectBuilder, c : String) -> SelectBuilder {
  self.columns.push(
    @ast.SelectItem::Expr(@ast.Expr::Column(@ast.ColumnRef::Column(c))),
  )
  self
}

/// Add a raw expression as a select item
pub fn SelectBuilder::expr(self : SelectBuilder, e : @ast.Expr) -> SelectBuilder {
  self.columns.push(@ast.SelectItem::Expr(e))
  self
}

/// Add an expression with alias
pub fn SelectBuilder::expr_as(
  self : SelectBuilder,
  e : @ast.Expr,
  als : String
) -> SelectBuilder {
  self.columns.push(@ast.SelectItem::ExprAlias(e, als))
  self
}

/// Add table.* as a select item
pub fn SelectBuilder::table_all_columns(
  self : SelectBuilder,
  table : String
) -> SelectBuilder {
  self.columns.push(@ast.SelectItem::TableAllColumns(table))
  self
}

/// Select all columns (*)
pub fn SelectBuilder::all(self : SelectBuilder) -> SelectBuilder {
  self.columns.push(@ast.SelectItem::AllColumns)
  self
}

/// Set the FROM table
pub fn SelectBuilder::from(self : SelectBuilder, table : String) -> SelectBuilder {
  self.from_ = Some(@ast.TableRef::Table(table))
  self
}

/// Set the FROM table with alias
pub fn SelectBuilder::from_as(
  self : SelectBuilder,
  table : String,
  als : String
) -> SelectBuilder {
  self.from_ = Some(@ast.TableRef::TableAlias(table, als))
  self
}

/// Set the FROM table with schema qualification
pub fn SelectBuilder::from_schema(
  self : SelectBuilder,
  schema : String,
  table : String
) -> SelectBuilder {
  self.from_ = Some(@ast.TableRef::SchemaTable(schema, table))
  self
}

/// Add an INNER JOIN
pub fn SelectBuilder::join(
  self : SelectBuilder,
  table : String,
  on : @ast.Expr
) -> SelectBuilder {
  self.joins_.push(
    {
      join_type: @ast.JoinType::Inner,
      table: @ast.TableRef::Table(table),
      on,
    },
  )
  self
}

/// Add a LEFT JOIN
pub fn SelectBuilder::left_join(
  self : SelectBuilder,
  table : String,
  on : @ast.Expr
) -> SelectBuilder {
  self.joins_.push(
    {
      join_type: @ast.JoinType::Left,
      table: @ast.TableRef::Table(table),
      on,
    },
  )
  self
}

/// Add a RIGHT JOIN
pub fn SelectBuilder::right_join(
  self : SelectBuilder,
  table : String,
  on : @ast.Expr
) -> SelectBuilder {
  self.joins_.push(
    {
      join_type: @ast.JoinType::Right,
      table: @ast.TableRef::Table(table),
      on,
    },
  )
  self
}

/// Add a FULL JOIN
pub fn SelectBuilder::full_join(
  self : SelectBuilder,
  table : String,
  on : @ast.Expr
) -> SelectBuilder {
  self.joins_.push(
    {
      join_type: @ast.JoinType::Full,
      table: @ast.TableRef::Table(table),
      on,
    },
  )
  self
}

/// Add a CROSS JOIN
pub fn SelectBuilder::cross_join(
  self : SelectBuilder,
  table : String
) -> SelectBuilder {
  self.joins_.push(
    {
      join_type: @ast.JoinType::Cross,
      table: @ast.TableRef::Table(table),
      on: @ast.Expr::Value(@ast.Value::Bool(true)),
    },
  )
  self
}

/// Add an INNER JOIN with alias
pub fn SelectBuilder::join_as(
  self : SelectBuilder,
  table : String,
  als : String,
  on : @ast.Expr
) -> SelectBuilder {
  self.joins_.push(
    {
      join_type: @ast.JoinType::Inner,
      table: @ast.TableRef::TableAlias(table, als),
      on,
    },
  )
  self
}

/// Add a LEFT JOIN with alias
pub fn SelectBuilder::left_join_as(
  self : SelectBuilder,
  table : String,
  als : String,
  on : @ast.Expr
) -> SelectBuilder {
  self.joins_.push(
    {
      join_type: @ast.JoinType::Left,
      table: @ast.TableRef::TableAlias(table, als),
      on,
    },
  )
  self
}

/// Add a RIGHT JOIN with alias
pub fn SelectBuilder::right_join_as(
  self : SelectBuilder,
  table : String,
  als : String,
  on : @ast.Expr
) -> SelectBuilder {
  self.joins_.push(
    {
      join_type: @ast.JoinType::Right,
      table: @ast.TableRef::TableAlias(table, als),
      on,
    },
  )
  self
}

/// Add a FULL JOIN with alias
pub fn SelectBuilder::full_join_as(
  self : SelectBuilder,
  table : String,
  als : String,
  on : @ast.Expr
) -> SelectBuilder {
  self.joins_.push(
    {
      join_type: @ast.JoinType::Full,
      table: @ast.TableRef::TableAlias(table, als),
      on,
    },
  )
  self
}

/// Add a CROSS JOIN with alias
pub fn SelectBuilder::cross_join_as(
  self : SelectBuilder,
  table : String,
  als : String
) -> SelectBuilder {
  self.joins_.push(
    {
      join_type: @ast.JoinType::Cross,
      table: @ast.TableRef::TableAlias(table, als),
      on: @ast.Expr::Value(@ast.Value::Bool(true)),
    },
  )
  self
}

/// Add a WHERE condition (AND-combined with existing)
pub fn SelectBuilder::where_(self : SelectBuilder, cond : @ast.Expr) -> SelectBuilder {
  self.where_ = match self.where_ {
    None => Some(cond)
    Some(existing) =>
      Some(@ast.Expr::Binary(existing, @ast.BinOp::And, cond))
  }
  self
}

/// Add a GROUP BY column by name
pub fn SelectBuilder::group_by(self : SelectBuilder, c : String) -> SelectBuilder {
  self.group_by_.push(@ast.Expr::Column(@ast.ColumnRef::Column(c)))
  self
}

/// Add a GROUP BY with an arbitrary Expr (e.g. table-qualified column)
pub fn SelectBuilder::group_by_expr(
  self : SelectBuilder,
  e : @ast.Expr
) -> SelectBuilder {
  self.group_by_.push(e)
  self
}

/// Add multiple GROUP BY expressions at once
pub fn SelectBuilder::group_by_exprs(
  self : SelectBuilder,
  exprs : Array[@ast.Expr]
) -> SelectBuilder {
  for e in exprs {
    self.group_by_.push(e)
  }
  self
}

/// Add a HAVING condition (AND-combined with existing)
pub fn SelectBuilder::having(self : SelectBuilder, cond : @ast.Expr) -> SelectBuilder {
  self.having_ = match self.having_ {
    None => Some(cond)
    Some(existing) =>
      Some(@ast.Expr::Binary(existing, @ast.BinOp::And, cond))
  }
  self
}

/// Add an ORDER BY clause
pub fn SelectBuilder::order_by(
  self : SelectBuilder,
  c : String,
  order : @ast.Order
) -> SelectBuilder {
  self.order_by_.push(
    { expr: @ast.Expr::Column(@ast.ColumnRef::Column(c)), order },
  )
  self
}

/// Add an ORDER BY clause with table-qualified column
pub fn SelectBuilder::order_by_table(
  self : SelectBuilder,
  table : String,
  c : String,
  order : @ast.Order
) -> SelectBuilder {
  self.order_by_.push(
    { expr: @ast.Expr::Column(@ast.ColumnRef::TableColumn(table, c)), order },
  )
  self
}

/// Set LIMIT
pub fn SelectBuilder::limit(self : SelectBuilder, n : Int) -> SelectBuilder {
  self.limit_ = Some(n)
  self
}

/// Set OFFSET
pub fn SelectBuilder::offset(self : SelectBuilder, n : Int) -> SelectBuilder {
  self.offset_ = Some(n)
  self
}

/// Add a FROM subquery from a SelectBuilder
pub fn SelectBuilder::from_sub(
  self : SelectBuilder,
  sub : SelectBuilder,
  als : String
) -> SelectBuilder {
  let sub_stmt = sub.build_statement()
  self.from_ = Some(@ast.TableRef::SubQuery(sub_stmt, als))
  self
}

/// Add a CTE (WITH clause)
pub fn SelectBuilder::with_(
  self : SelectBuilder,
  name : String,
  sub : SelectBuilder
) -> SelectBuilder {
  let sub_stmt = sub.build_statement()
  self.ctes_.push({ name, query: sub_stmt })
  self
}

/// Add a UNION
pub fn SelectBuilder::union(
  self : SelectBuilder,
  other : SelectBuilder
) -> SelectBuilder {
  let other_stmt = other.build_statement()
  self.set_ops_.push({ kind: @ast.SetOpKind::Union, select: other_stmt })
  self
}

/// Add a UNION ALL
pub fn SelectBuilder::union_all(
  self : SelectBuilder,
  other : SelectBuilder
) -> SelectBuilder {
  let other_stmt = other.build_statement()
  self.set_ops_.push({ kind: @ast.SetOpKind::UnionAll, select: other_stmt })
  self
}

/// Add an INTERSECT
pub fn SelectBuilder::intersect(
  self : SelectBuilder,
  other : SelectBuilder
) -> SelectBuilder {
  let other_stmt = other.build_statement()
  self.set_ops_.push({ kind: @ast.SetOpKind::Intersect, select: other_stmt })
  self
}

/// Add an INTERSECT ALL
pub fn SelectBuilder::intersect_all(
  self : SelectBuilder,
  other : SelectBuilder
) -> SelectBuilder {
  let other_stmt = other.build_statement()
  self.set_ops_.push({ kind: @ast.SetOpKind::IntersectAll, select: other_stmt })
  self
}

/// Add an EXCEPT
pub fn SelectBuilder::except_(
  self : SelectBuilder,
  other : SelectBuilder
) -> SelectBuilder {
  let other_stmt = other.build_statement()
  self.set_ops_.push({ kind: @ast.SetOpKind::Except, select: other_stmt })
  self
}

/// Add an EXCEPT ALL
pub fn SelectBuilder::except_all(
  self : SelectBuilder,
  other : SelectBuilder
) -> SelectBuilder {
  let other_stmt = other.build_statement()
  self.set_ops_.push({ kind: @ast.SetOpKind::ExceptAll, select: other_stmt })
  self
}

/// Build the internal SelectStatement (for use by subqueries, CTEs, etc.)
pub fn SelectBuilder::build_statement(self : SelectBuilder) -> @ast.SelectStatement {
  {
    distinct: self.distinct_,
    columns: self.columns,
    from: self.from_,
    joins: self.joins_,
    where_: self.where_,
    group_by: self.group_by_,
    having: self.having_,
    order_by: self.order_by_,
    limit: match self.limit_ {
      Some(n) => Some(@ast.Expr::Value(@ast.Value::Int(n)))
      None => None
    },
    offset: match self.offset_ {
      Some(n) => Some(@ast.Expr::Value(@ast.Value::Int(n)))
      None => None
    },
    set_ops: self.set_ops_,
    ctes: self.ctes_,
  }
}

/// Build the SelectBuilder into a CompiledQuery
pub fn SelectBuilder::build(self : SelectBuilder) -> @ast.CompiledQuery raise {
  let stmt = self.build_statement()
  @ast.render_select(stmt)
}
