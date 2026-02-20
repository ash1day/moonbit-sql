/// Builder for DELETE statements
pub struct DeleteBuilder {
  table_ : @ast.TableRef
  mut where_ : @ast.Expr?
  returning_ : Array[@ast.SelectItem]
}

/// Create a new DeleteBuilder for the given table
pub fn delete_from(table : String) -> DeleteBuilder {
  {
    table_: @ast.TableRef::Table(table),
    where_: None,
    returning_: [],
  }
}

/// Add a WHERE condition (AND-combined with existing)
pub fn DeleteBuilder::where_(self : DeleteBuilder, cond : @ast.Expr) -> DeleteBuilder {
  self.where_ = match self.where_ {
    None => Some(cond)
    Some(existing) =>
      Some(@ast.Expr::Binary(existing, @ast.BinOp::And, cond))
  }
  self
}

/// Add RETURNING columns
pub fn DeleteBuilder::returning(self : DeleteBuilder, cols : Array[String]) -> DeleteBuilder {
  for c in cols {
    self.returning_.push(
      @ast.SelectItem::Expr(@ast.Expr::Column(@ast.ColumnRef::Column(c))),
    )
  }
  self
}

/// Build the DeleteBuilder into a CompiledQuery
pub fn DeleteBuilder::build(self : DeleteBuilder) -> @ast.CompiledQuery raise {
  let stmt : @ast.DeleteStatement = {
    table: self.table_,
    where_: self.where_,
    returning: self.returning_,
  }
  @ast.render_delete(stmt)
}
