pub suberror DecodeError {
  ColumnNotFound(String)
  TypeMismatch(String, String)
  NullValue(String)
}

fn get_column(row : @pg.Row, col : String) -> @pg.ColumnValue raise {
  match row.data.get(col) {
    Some(v) => v
    None => raise ColumnNotFound(col)
  }
}

/// Extract a String value from a Row by column name
pub fn get_str(row : @pg.Row, col : String) -> String raise {
  let v = get_column(row, col)
  match v {
    Str(s) => s
    Null => raise NullValue(col)
    _ => raise TypeMismatch(col, "String")
  }
}

/// Extract an Int value from a Row by column name
pub fn get_int(row : @pg.Row, col : String) -> Int raise {
  let v = get_column(row, col)
  match v {
    Int(n) => n
    Null => raise NullValue(col)
    _ => raise TypeMismatch(col, "Int")
  }
}

/// Extract a Bool value from a Row by column name
pub fn get_bool(row : @pg.Row, col : String) -> Bool raise {
  let v = get_column(row, col)
  match v {
    Bool(b) => b
    Null => raise NullValue(col)
    _ => raise TypeMismatch(col, "Bool")
  }
}

/// Extract a Double value from a Row by column name
pub fn get_double(row : @pg.Row, col : String) -> Double raise {
  let v = get_column(row, col)
  match v {
    Double(d) => d
    Int(n) => n.to_double()
    Null => raise NullValue(col)
    _ => raise TypeMismatch(col, "Double")
  }
}

/// Extract an Int64 value from a Row by column name
pub fn get_int64(row : @pg.Row, col : String) -> Int64 raise {
  let v = get_column(row, col)
  match v {
    Int64(n) => n
    Int(n) => n.to_int64()
    Null => raise NullValue(col)
    _ => raise TypeMismatch(col, "Int64")
  }
}

/// Extract an optional String value from a Row by column name
/// Returns None if the column is NULL, raises ColumnNotFound if column missing
pub fn get_optional_str(row : @pg.Row, col : String) -> String? raise {
  let v = get_column(row, col)
  match v {
    Null => None
    Str(s) => Some(s)
    _ => raise TypeMismatch(col, "String?")
  }
}

/// Extract an optional Int value from a Row by column name
pub fn get_optional_int(row : @pg.Row, col : String) -> Int? raise {
  let v = get_column(row, col)
  match v {
    Null => None
    Int(n) => Some(n)
    _ => raise TypeMismatch(col, "Int?")
  }
}

/// Extract an optional Double value from a Row by column name
pub fn get_optional_double(row : @pg.Row, col : String) -> Double? raise {
  let v = get_column(row, col)
  match v {
    Null => None
    Double(d) => Some(d)
    Int(n) => Some(n.to_double())
    _ => raise TypeMismatch(col, "Double?")
  }
}

/// Extract an optional Int64 value from a Row by column name
pub fn get_optional_int64(row : @pg.Row, col : String) -> Int64? raise {
  let v = get_column(row, col)
  match v {
    Null => None
    Int64(n) => Some(n)
    Int(n) => Some(n.to_int64())
    _ => raise TypeMismatch(col, "Int64?")
  }
}

/// Extract an optional Bool value from a Row by column name
pub fn get_optional_bool(row : @pg.Row, col : String) -> Bool? raise {
  let v = get_column(row, col)
  match v {
    Null => None
    Bool(b) => Some(b)
    _ => raise TypeMismatch(col, "Bool?")
  }
}

/// Extract a JSON String value from a Row by column name
pub fn get_json(row : @pg.Row, col : String) -> String raise {
  let v = get_column(row, col)
  match v {
    Json(s) => s
    Null => raise NullValue(col)
    _ => raise TypeMismatch(col, "Json")
  }
}

/// Extract an optional JSON String value from a Row by column name
/// Returns None if the column is NULL, raises ColumnNotFound if column missing
pub fn get_optional_json(row : @pg.Row, col : String) -> String? raise {
  let v = get_column(row, col)
  match v {
    Null => None
    Json(s) => Some(s)
    _ => raise TypeMismatch(col, "Json?")
  }
}
