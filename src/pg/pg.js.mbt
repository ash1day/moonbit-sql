/// PostgreSQL connection wrapping a pg Client
pub struct Connection {
  client : PgClient
}

/// Connect to a PostgreSQL database
pub async fn Connection::connect(url : String) -> Connection raise {
  let client = js_create_client(url)
  try {
    js_connect_client(client).wait()
  } catch {
    err => raise ConnectionError("failed to connect: \{err}")
  }
  { client, }
}

/// Execute a compiled query and return rows
pub async fn Connection::query(
  self : Connection,
  query : @ast.CompiledQuery,
) -> Array[Row] raise {
  let params_json = params_to_json(query.params)
  let result_json = try {
    js_query_raw(self.client, query.sql, params_json).wait()
  } catch {
    err => raise QueryError("query failed: \{err}")
  }
  try {
    parse_rows(result_json)
  } catch {
    err => raise ParseError("failed to parse query result: \{err}")
  }
}

/// Close the connection
pub async fn Connection::close(self : Connection) -> Unit {
  js_end_client(self.client).wait()
}

/// Convert AST Value params to a JSON array string for the pg driver
fn params_to_json(params : Array[@ast.Value]) -> String {
  let parts : Array[String] = []
  for param in params {
    parts.push(value_to_json(param))
  }
  "[" + parts.join(", ") + "]"
}

/// Convert a single AST Value to its JSON representation
fn value_to_json(v : @ast.Value) -> String {
  match v {
    Null => "null"
    Bool(b) => if b { "true" } else { "false" }
    Int(n) => n.to_string()
    Int64(n) => n.to_string()
    Double(n) => n.to_string()
    String(s) => {
      let buf = StringBuilder::new()
      buf.write_char('"')
      for c in s {
        let code = c.to_int()
        if c == '\\' {
          buf.write_string("\\\\")
        } else if c == '"' {
          buf.write_string("\\\"")
        } else if c == '\n' {
          buf.write_string("\\n")
        } else if c == '\r' {
          buf.write_string("\\r")
        } else if c == '\t' {
          buf.write_string("\\t")
        } else if code == 0x08 {
          // backspace
          buf.write_string("\\b")
        } else if code == 0x0C {
          // form feed
          buf.write_string("\\f")
        } else if code >= 0x00 && code <= 0x1F {
          // other control characters
          let hex_str = if code < 16 {
            "\\u000" + to_hex_digit(code)
          } else {
            "\\u001" + to_hex_digit(code - 16)
          }
          buf.write_string(hex_str)
        } else {
          buf.write_char(c)
        }
      }
      buf.write_char('"')
      buf.to_string()
    }
  }
}

/// Parse the JSON string result from pg into an array of Rows
fn parse_rows(json_str : String) -> Array[Row] raise {
  let json = @json.parse(json_str)
  match json {
    Array(arr) => {
      let rows : Array[Row] = []
      for obj in arr {
        rows.push(parse_row(obj))
      }
      rows
    }
    _ => raise ParseError("expected JSON array")
  }
}

/// Parse a single JSON object into a Row
fn parse_row(json : Json) -> Row raise {
  match json {
    Object(obj) => {
      let row : Map[String, ColumnValue] = {}
      for k, v in obj {
        row[k] = json_to_column_value(v)
      }
      { data: row }
    }
    _ => raise ParseError("expected JSON object for row")
  }
}

/// Convert a single hex digit (0-15) to its character representation
fn to_hex_digit(n : Int) -> String {
  match n {
    0 => "0"
    1 => "1"
    2 => "2"
    3 => "3"
    4 => "4"
    5 => "5"
    6 => "6"
    7 => "7"
    8 => "8"
    9 => "9"
    10 => "a"
    11 => "b"
    12 => "c"
    13 => "d"
    14 => "e"
    _ => "f"
  }
}

/// Convert a JSON value to a ColumnValue
fn json_to_column_value(json : Json) -> ColumnValue {
  match json {
    Null => ColumnValue::Null
    True => ColumnValue::Bool(true)
    False => ColumnValue::Bool(false)
    Number(n, ..) => {
      let i = n.to_int()
      if i.to_double() == n {
        ColumnValue::Int(i)
      } else {
        ColumnValue::Double(n)
      }
    }
    String(s) => ColumnValue::Str(s)
    _ => ColumnValue::Json(json.stringify())
  }
}
