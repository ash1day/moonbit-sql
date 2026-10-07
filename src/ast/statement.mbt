/// SELECT statement AST
pub(all) struct SelectStatement {
  distinct : Bool
  columns : Array[SelectItem]
  from : TableRef?
  joins : Array[JoinClause]
  where_ : Expr?
  group_by : Array[Expr]
  having : Expr?
  order_by : Array[OrderByItem]
  limit : Expr?
  offset : Expr?
  set_ops : Array[SetOperation]
  ctes : Array[CTE]
} derive(Show, Debug, Eq)

/// Create an empty SelectStatement
pub fn SelectStatement::new() -> SelectStatement {
  {
    distinct: false,
    columns: [],
    from: None,
    joins: [],
    where_: None,
    group_by: [],
    having: None,
    order_by: [],
    limit: None,
    offset: None,
    set_ops: [],
    ctes: [],
  }
}

/// INSERT statement AST
pub(all) struct InsertStatement {
  table : TableRef
  columns : Array[String]
  values : Array[Array[Expr]]
  select_ : SelectStatement?
  returning : Array[SelectItem]
  on_conflict : OnConflict?
} derive(Show, Debug, Eq)

/// UPDATE statement AST
pub(all) struct UpdateStatement {
  table : TableRef
  assignments : Array[(String, Expr)]
  where_ : Expr?
  returning : Array[SelectItem]
} derive(Show, Debug, Eq)

/// DELETE statement AST
pub(all) struct DeleteStatement {
  table : TableRef
  where_ : Expr?
  returning : Array[SelectItem]
} derive(Show, Debug, Eq)
