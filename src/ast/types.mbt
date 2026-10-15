///|
/// SQL value types for parameterized queries
pub(all) enum Value {
  Null
  Bool(Bool)
  Int(Int32)
  Int64(Int64)
  Double(Double)
  String(String)
} derive(Debug, Eq)

///|
/// Column reference
pub(all) enum ColumnRef {
  /// Column name only: "id"
  Column(String)
  /// Table-qualified: "users"."id"
  TableColumn(String, String)
} derive(Debug, Eq)

///|
/// Binary operators
pub(all) enum BinOp {
  Eq
  Ne
  Lt
  Le
  Gt
  Ge
  And
  Or
  Like
  Add
  Sub
  Mul
  Div
} derive(Debug, Eq)

///|
/// Unary operators
pub(all) enum UnOp {
  Not
  Neg
} derive(Debug, Eq)

///|
/// WHEN condition THEN result clause for CASE expressions
pub(all) struct WhenClause {
  condition : Expr
  result : Expr
} derive(Debug, Eq)

///|
/// SQL expression (used in WHERE, SELECT, etc.)
pub(all) enum Expr {
  Column(ColumnRef)
  Value(Value)
  Binary(Expr, BinOp, Expr)
  Unary(UnOp, Expr)
  IsNull(Expr)
  IsNotNull(Expr)
  InList(Expr, Array[Expr])
  NotInList(Expr, Array[Expr])
  Between(Expr, Expr, Expr)
  NotBetween(Expr, Expr, Expr)
  Func(FuncCall)
  Asterisk
  InSubquery(Expr, SelectStatement)
  NotInSubquery(Expr, SelectStatement)
  Subquery(SelectStatement)
  WindowFunc(FuncCall, WindowSpec)
  CaseExpr(Array[WhenClause], Expr?)
  Exists(SelectStatement)
  NotExists(SelectStatement)
  /// Raw SQL string injected verbatim — use only when no typed builder exists
  Raw(String)
} derive(Debug, Eq)

///|
/// SQL function call
pub(all) struct FuncCall {
  name : String
  args : Array[Expr]
} derive(Debug, Eq)

///|
/// Table reference
pub(all) enum TableRef {
  /// Simple table name
  Table(String)
  /// Table with alias: "users" AS "u"
  TableAlias(String, String)
  /// Schema-qualified: "public"."users"
  SchemaTable(String, String)
  /// Subquery with alias: (SELECT ...) AS "alias"
  SubQuery(SelectStatement, String)
} derive(Debug, Eq)

///|
/// SELECT target item
pub(all) enum SelectItem {
  /// Expression: column, function, etc.
  Expr(Expr)
  /// Expression with alias: expr AS "name"
  ExprAlias(Expr, String)
  /// All columns: *
  AllColumns
  /// All columns from table: "users".*
  TableAllColumns(String)
} derive(Debug, Eq)

///|
/// JOIN type
pub(all) enum JoinType {
  Inner
  Left
  Right
  Full
  Cross
} derive(Debug, Eq)

///|
/// JOIN clause
pub(all) struct JoinClause {
  join_type : JoinType
  table : TableRef
  on : Expr
} derive(Debug, Eq)

///|
/// Sort order
pub(all) enum Order {
  Asc
  Desc
} derive(Debug, Eq)

///|
/// ORDER BY item
pub(all) struct OrderByItem {
  expr : Expr
  order : Order
} derive(Debug, Eq)

///|
/// Window specification for window functions
pub(all) struct WindowSpec {
  partition_by : Array[Expr]
  order_by : Array[OrderByItem]
} derive(Debug, Eq)

///|
/// Set operation type
pub(all) enum SetOpKind {
  Union
  UnionAll
  Intersect
  IntersectAll
  Except
  ExceptAll
} derive(Debug, Eq)

///|
/// Set operation: UNION/INTERSECT/EXCEPT with another SELECT
pub(all) struct SetOperation {
  kind : SetOpKind
  select : SelectStatement
} derive(Debug, Eq)

///|
/// Common Table Expression (CTE)
pub(all) struct CTE {
  name : String
  query : SelectStatement
} derive(Debug, Eq)

///|
/// ON CONFLICT action for upsert
pub(all) enum OnConflictAction {
  DoNothing
  DoUpdate(Array[(String, Expr)])
} derive(Debug, Eq)

///|
/// ON CONFLICT clause for INSERT
pub(all) struct OnConflict {
  columns : Array[String]
  action : OnConflictAction
} derive(Debug, Eq)

///|
/// Compiled query result: SQL string + parameter values
pub(all) struct CompiledQuery {
  sql : String
  params : Array[Value]
} derive(Debug, Eq)

///|
/// Errors that can occur during SQL rendering
pub suberror RenderError {
  InvalidFuncName(String)
}
