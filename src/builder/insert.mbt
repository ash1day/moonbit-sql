/// Builder for INSERT statements
pub struct InsertBuilder {
  table_ : @ast.TableRef
  mut columns_ : Array[String]
  values_ : Array[Array[@ast.Expr]]
  returning_ : Array[@ast.SelectItem]
}

/// Create a new InsertBuilder for the given table
pub fn insert_into(table : String) -> InsertBuilder {
  {
    table_: @ast.TableRef::Table(table),
    columns_: [],
    values_: [],
    returning_: [],
  }
}

/// Set the columns for the INSERT
pub fn InsertBuilder::columns(self : InsertBuilder, cols : Array[String]) -> InsertBuilder {
  self.columns_ = cols
  self
}

/// Add a row of values
pub fn InsertBuilder::values(self : InsertBuilder, vals : Array[@ast.Expr]) -> InsertBuilder {
  self.values_.push(vals)
  self
}

/// Add RETURNING columns
pub fn InsertBuilder::returning(self : InsertBuilder, cols : Array[String]) -> InsertBuilder {
  for c in cols {
    self.returning_.push(
      @ast.SelectItem::Expr(@ast.Expr::Column(@ast.ColumnRef::Column(c))),
    )
  }
  self
}

/// Build the InsertBuilder into a CompiledQuery
pub fn InsertBuilder::build(self : InsertBuilder) -> @ast.CompiledQuery {
  if self.values_.is_empty() {
    abort("moonbit-sql: INSERT requires at least one VALUES row")
  }
  let stmt : @ast.InsertStatement = {
    table: self.table_,
    columns: self.columns_,
    values: self.values_,
    returning: self.returning_,
  }
  @ast.render_insert(stmt)
}
