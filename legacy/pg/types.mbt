pub suberror PgError {
  ConnectionError(String)
  QueryError(String)
  ParseError(String)
}

/// Column value from a database row
pub(all) enum ColumnValue {
  Null
  Bool(Bool)
  Int(Int)
  Int64(Int64)
  Double(Double)
  Str(String)
  Json(String)
} derive(Show, Debug, Eq)

/// A single database row: column name -> value
pub(all) struct Row {
  data : Map[String, ColumnValue]
} derive(Show, Debug, Eq)
