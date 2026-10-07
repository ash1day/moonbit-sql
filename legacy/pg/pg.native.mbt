/// PostgreSQL connection wrapping mattn/postgres for native target
pub struct Connection {
  client : @postgres.Connection
}

/// Connect to a PostgreSQL database
#deprecated("Use a PostgreSQL driver with ast.CompiledQuery; see README migration notes")
pub fn Connection::connect(url : String) -> Connection raise {
  match @postgres.connect(url) {
    Ok(conn) => { client: conn }
    Err(e) => raise ConnectionError("failed to connect: \{e.to_string()}")
  }
}

/// Execute a compiled query and return rows.
/// Since mattn/postgres ToValue trait is readonly, we inline parameters
/// into the SQL string using Connection::query (no parameterized binding).
pub fn Connection::query(
  self : Connection,
  compiled : @ast.CompiledQuery,
) -> Array[Row] raise {
  let sql = inline_params(compiled.sql, compiled.params)
  let result = match self.client.query(sql) {
    Ok(r) => r
    Err(e) => raise QueryError("query failed: \{e.to_string()}")
  }
  let columns = result.columns()
  let raw_rows = result.rows()
  result.free()
  let rows : Array[Row] = []
  for raw_row in raw_rows {
    let data : Map[String, ColumnValue] = {}
    for j, col_name in columns {
      data[col_name] = str_to_column_value(raw_row[j])
    }
    rows.push({ data, })
  }
  rows
}

/// Close the connection
pub fn Connection::close(self : Connection) -> Unit {
  self.client.close()
}

/// Replace $1, $2, ... placeholders with SQL-safe literal values.
fn inline_params(sql : String, params : Array[@ast.Value]) -> String {
  if params.is_empty() {
    return sql
  }
  let buf = StringBuilder::new()
  let chars = sql.to_array()
  let len = chars.length()
  let mut i = 0
  while i < len {
    if chars[i] == '$' && i + 1 < len && chars[i + 1] >= '1' && chars[i + 1] <= '9' {
      // Parse the parameter number
      let mut j = i + 1
      while j < len && chars[j] >= '0' && chars[j] <= '9' {
        j = j + 1
      }
      let mut num = 0
      let mut k = i + 1
      while k < j {
        num = num * 10 + (chars[k].to_int() - '0'.to_int())
        k = k + 1
      }
      num = num - 1 // Convert 1-based to 0-based index
      if num >= 0 && num < params.length() {
        buf.write_string(value_to_sql_literal(params[num]))
      } else {
        // Keep original placeholder if out of range
        let mut k2 = i
        while k2 < j {
          buf.write_char(chars[k2])
          k2 = k2 + 1
        }
      }
      i = j
    } else {
      buf.write_char(chars[i])
      i = i + 1
    }
  }
  buf.to_string()
}

/// Convert an AST Value to a SQL literal string (safely escaped).
fn value_to_sql_literal(v : @ast.Value) -> String {
  match v {
    Null => "NULL"
    Bool(b) => if b { "TRUE" } else { "FALSE" }
    Int(n) => n.to_string()
    Int64(n) => n.to_string()
    Double(n) => n.to_string()
    String(s) => "'" + s.replace_all(old="'", new="''") + "'"
  }
}

/// Convert a string value from pg result to ColumnValue.
/// PostgreSQL returns all values as strings via libpq; we infer types heuristically.
fn str_to_column_value(s : String) -> ColumnValue {
  // PostgreSQL boolean values
  if s == "t" {
    return ColumnValue::Bool(true)
  }
  if s == "f" {
    return ColumnValue::Bool(false)
  }
  // Try parsing as integer
  try {
    let n = @strconv.parse_int(s)
    return ColumnValue::Int(n)
  } catch {
    _ => ()
  }
  // Try parsing as double (only if it contains '.' or 'e'/'E')
  if s.contains(".") || s.contains("e") || s.contains("E") {
    try {
      let n = @strconv.parse_double(s)
      return ColumnValue::Double(n)
    } catch {
      _ => ()
    }
  }
  ColumnValue::Str(s)
}
