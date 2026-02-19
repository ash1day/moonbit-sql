/// SQL value types for parameterized queries
pub(all) enum Value {
  Null
  Bool(Bool)
  Int(Int)
  Int64(Int64)
  Double(Double)
  String(String)
} derive(Show, Eq)

/// Column reference
pub(all) enum ColumnRef {
  /// Column name only: "id"
  Column(String)
  /// Table-qualified: "users"."id"
  TableColumn(String, String)
} derive(Show, Eq)

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
} derive(Show, Eq)

/// Unary operators
pub(all) enum UnOp {
  Not
  Neg
} derive(Show, Eq)

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
} derive(Show, Eq)

/// SQL function call
pub(all) struct FuncCall {
  name : String
  args : Array[Expr]
} derive(Show, Eq)

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
} derive(Show, Eq)

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
} derive(Show, Eq)

/// JOIN type
pub(all) enum JoinType {
  Inner
  Left
  Right
  Full
  Cross
} derive(Show, Eq)

/// JOIN clause
pub(all) struct JoinClause {
  join_type : JoinType
  table : TableRef
  on : Expr
} derive(Show, Eq)

/// Sort order
pub(all) enum Order {
  Asc
  Desc
} derive(Show, Eq)

/// ORDER BY item
pub(all) struct OrderByItem {
  expr : Expr
  order : Order
} derive(Show, Eq)

/// Window specification for window functions
pub(all) struct WindowSpec {
  partition_by : Array[Expr]
  order_by : Array[OrderByItem]
} derive(Show, Eq)

/// Set operation type
pub(all) enum SetOpKind {
  Union
  UnionAll
  Intersect
  IntersectAll
  Except
  ExceptAll
} derive(Show, Eq)

/// Set operation: UNION/INTERSECT/EXCEPT with another SELECT
pub(all) struct SetOperation {
  kind : SetOpKind
  select : SelectStatement
} derive(Show, Eq)

/// Common Table Expression (CTE)
pub(all) struct CTE {
  name : String
  query : SelectStatement
} derive(Show, Eq)

/// ON CONFLICT action for upsert
pub(all) enum OnConflictAction {
  DoNothing
  DoUpdate(Array[(String, Expr)])
} derive(Show, Eq)

/// ON CONFLICT clause for INSERT
pub(all) struct OnConflict {
  columns : Array[String]
  action : OnConflictAction
} derive(Show, Eq)

/// Compiled query result: SQL string + parameter values
pub(all) struct CompiledQuery {
  sql : String
  params : Array[Value]
} derive(Show, Eq)
