/// Builder for UPDATE statements
pub struct UpdateBuilder {
  table_ : @ast.TableRef
  assignments_ : Array[(String, @ast.Expr)]
  mut where_ : @ast.Expr?
  returning_ : Array[@ast.SelectItem]
}

/// Create a new UpdateBuilder for the given table
pub fn update(table : String) -> UpdateBuilder {
  {
    table_: @ast.TableRef::Table(table),
    assignments_: [],
    where_: None,
    returning_: [],
  }
}

/// Set a column = value assignment
pub fn UpdateBuilder::set(
  self : UpdateBuilder,
  c : String,
  val : @ast.Expr
) -> UpdateBuilder {
  self.assignments_.push((c, val))
  self
}

/// Add a WHERE condition (AND-combined with existing)
pub fn UpdateBuilder::where_(self : UpdateBuilder, cond : @ast.Expr) -> UpdateBuilder {
  self.where_ = match self.where_ {
    None => Some(cond)
    Some(existing) =>
      Some(@ast.Expr::Binary(existing, @ast.BinOp::And, cond))
  }
  self
}

/// Add RETURNING columns
pub fn UpdateBuilder::returning(self : UpdateBuilder, cols : Array[String]) -> UpdateBuilder {
  for c in cols {
    self.returning_.push(
      @ast.SelectItem::Expr(@ast.Expr::Column(@ast.ColumnRef::Column(c))),
    )
  }
  self
}

/// Build the UpdateBuilder into a CompiledQuery
pub fn UpdateBuilder::build(self : UpdateBuilder) -> @ast.CompiledQuery {
  if self.assignments_.is_empty() {
    abort("moonbit-sql: UPDATE requires at least one SET assignment")
  }
  let stmt : @ast.UpdateStatement = {
    table: self.table_,
    assignments: self.assignments_,
    where_: self.where_,
    returning: self.returning_,
  }
  @ast.render_update(stmt)
}
