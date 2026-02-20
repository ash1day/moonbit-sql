// ========================================================
// get_str
// ========================================================

test "get_str: existing column" {
  let row : @pg.Row = { data: { "name": @pg.Str("Alice"), "age": @pg.Int(30) } }
  assert_eq(get_str(row, "name"), "Alice")
}

test "get_str: column not found" {
  let row : @pg.Row = { data: {} }
  let result = try {
    Result::Ok(get_str(row, "name"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::ColumnNotFound("name")) => ()
    _ => fail("expected ColumnNotFound")
  }
}

test "get_str: type mismatch from Int" {
  let row : @pg.Row = { data: { "name": @pg.Int(42) } }
  let result = try {
    Result::Ok(get_str(row, "name"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("name", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "get_str: type mismatch from Bool" {
  let row : @pg.Row = { data: { "name": @pg.Bool(true) } }
  let result = try {
    Result::Ok(get_str(row, "name"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("name", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "get_str: null value raises NullValue" {
  let row : @pg.Row = { data: { "name": @pg.Null } }
  let result = try {
    Result::Ok(get_str(row, "name"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::NullValue("name")) => ()
    _ => fail("expected NullValue")
  }
}

test "get_str: empty string" {
  let row : @pg.Row = { data: { "name": @pg.Str("") } }
  assert_eq(get_str(row, "name"), "")
}

// ========================================================
// get_int
// ========================================================

test "get_int: existing column" {
  let row : @pg.Row = { data: { "age": @pg.Int(30) } }
  assert_eq(get_int(row, "age"), 30)
}

test "get_int: zero" {
  let row : @pg.Row = { data: { "count": @pg.Int(0) } }
  assert_eq(get_int(row, "count"), 0)
}

test "get_int: negative" {
  let row : @pg.Row = { data: { "balance": @pg.Int(-100) } }
  assert_eq(get_int(row, "balance"), -100)
}

test "get_int: type mismatch from Str" {
  let row : @pg.Row = { data: { "age": @pg.Str("thirty") } }
  let result = try {
    Result::Ok(get_int(row, "age"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("age", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "get_int: type mismatch from Double" {
  let row : @pg.Row = { data: { "age": @pg.Double(30.5) } }
  let result = try {
    Result::Ok(get_int(row, "age"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("age", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "get_int: null value raises NullValue" {
  let row : @pg.Row = { data: { "age": @pg.Null } }
  let result = try {
    Result::Ok(get_int(row, "age"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::NullValue("age")) => ()
    _ => fail("expected NullValue")
  }
}

test "get_int: column not found" {
  let row : @pg.Row = { data: {} }
  let result = try {
    Result::Ok(get_int(row, "age"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::ColumnNotFound("age")) => ()
    _ => fail("expected ColumnNotFound")
  }
}

// ========================================================
// get_bool
// ========================================================

test "get_bool: true" {
  let row : @pg.Row = { data: { "active": @pg.Bool(true) } }
  assert_eq(get_bool(row, "active"), true)
}

test "get_bool: false" {
  let row : @pg.Row = { data: { "active": @pg.Bool(false) } }
  assert_eq(get_bool(row, "active"), false)
}

test "get_bool: type mismatch from Str" {
  let row : @pg.Row = { data: { "active": @pg.Str("yes") } }
  let result = try {
    Result::Ok(get_bool(row, "active"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("active", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "get_bool: type mismatch from Int" {
  let row : @pg.Row = { data: { "active": @pg.Int(1) } }
  let result = try {
    Result::Ok(get_bool(row, "active"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("active", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "get_bool: null value raises NullValue" {
  let row : @pg.Row = { data: { "active": @pg.Null } }
  let result = try {
    Result::Ok(get_bool(row, "active"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::NullValue("active")) => ()
    _ => fail("expected NullValue")
  }
}

test "get_bool: column not found" {
  let row : @pg.Row = { data: {} }
  let result = try {
    Result::Ok(get_bool(row, "active"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::ColumnNotFound("active")) => ()
    _ => fail("expected ColumnNotFound")
  }
}

// ========================================================
// get_double
// ========================================================

test "get_double: from Double" {
  let row : @pg.Row = { data: { "price": @pg.Double(9.99) } }
  assert_eq(get_double(row, "price"), 9.99)
}

test "get_double: from Int (implicit conversion)" {
  let row : @pg.Row = { data: { "price": @pg.Int(10) } }
  assert_eq(get_double(row, "price"), 10.0)
}

test "get_double: zero" {
  let row : @pg.Row = { data: { "price": @pg.Double(0.0) } }
  assert_eq(get_double(row, "price"), 0.0)
}

test "get_double: negative" {
  let row : @pg.Row = { data: { "balance": @pg.Double(-42.5) } }
  assert_eq(get_double(row, "balance"), -42.5)
}

test "get_double: type mismatch from Str" {
  let row : @pg.Row = { data: { "price": @pg.Str("9.99") } }
  let result = try {
    Result::Ok(get_double(row, "price"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("price", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "get_double: null value raises NullValue" {
  let row : @pg.Row = { data: { "price": @pg.Null } }
  let result = try {
    Result::Ok(get_double(row, "price"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::NullValue("price")) => ()
    _ => fail("expected NullValue")
  }
}

test "get_double: column not found" {
  let row : @pg.Row = { data: {} }
  let result = try {
    Result::Ok(get_double(row, "price"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::ColumnNotFound("price")) => ()
    _ => fail("expected ColumnNotFound")
  }
}

// ========================================================
// get_int64
// ========================================================

test "get_int64: from Int64" {
  let row : @pg.Row = { data: { "big_id": @pg.Int64(9999999999L) } }
  assert_eq(get_int64(row, "big_id"), 9999999999L)
}

test "get_int64: from Int (implicit conversion)" {
  let row : @pg.Row = { data: { "id": @pg.Int(42) } }
  assert_eq(get_int64(row, "id"), 42L)
}

test "get_int64: zero" {
  let row : @pg.Row = { data: { "id": @pg.Int64(0L) } }
  assert_eq(get_int64(row, "id"), 0L)
}

test "get_int64: negative" {
  let row : @pg.Row = { data: { "id": @pg.Int64(-1L) } }
  assert_eq(get_int64(row, "id"), -1L)
}

test "get_int64: type mismatch from Str" {
  let row : @pg.Row = { data: { "id": @pg.Str("big") } }
  let result = try {
    Result::Ok(get_int64(row, "id"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("id", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "get_int64: null value raises NullValue" {
  let row : @pg.Row = { data: { "id": @pg.Null } }
  let result = try {
    Result::Ok(get_int64(row, "id"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::NullValue("id")) => ()
    _ => fail("expected NullValue")
  }
}

test "get_int64: column not found" {
  let row : @pg.Row = { data: {} }
  let result = try {
    Result::Ok(get_int64(row, "id"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::ColumnNotFound("id")) => ()
    _ => fail("expected ColumnNotFound")
  }
}

// ========================================================
// get_optional_str
// ========================================================

test "get_optional_str: present value" {
  let row : @pg.Row = { data: { "bio": @pg.Str("hello") } }
  assert_eq(get_optional_str(row, "bio"), Some("hello"))
}

test "get_optional_str: null value" {
  let row : @pg.Row = { data: { "bio": @pg.Null } }
  assert_eq(get_optional_str(row, "bio"), None)
}

test "get_optional_str: empty string" {
  let row : @pg.Row = { data: { "bio": @pg.Str("") } }
  assert_eq(get_optional_str(row, "bio"), Some(""))
}

test "get_optional_str: column not found" {
  let row : @pg.Row = { data: {} }
  let result = try {
    Result::Ok(get_optional_str(row, "bio"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::ColumnNotFound("bio")) => ()
    _ => fail("expected ColumnNotFound")
  }
}

test "get_optional_str: type mismatch from Int" {
  let row : @pg.Row = { data: { "bio": @pg.Int(42) } }
  let result = try {
    Result::Ok(get_optional_str(row, "bio"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("bio", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

// ========================================================
// get_optional_int
// ========================================================

test "get_optional_int: present value" {
  let row : @pg.Row = { data: { "score": @pg.Int(100) } }
  assert_eq(get_optional_int(row, "score"), Some(100))
}

test "get_optional_int: null value" {
  let row : @pg.Row = { data: { "score": @pg.Null } }
  assert_eq(get_optional_int(row, "score"), None)
}

test "get_optional_int: zero" {
  let row : @pg.Row = { data: { "score": @pg.Int(0) } }
  assert_eq(get_optional_int(row, "score"), Some(0))
}

test "get_optional_int: column not found" {
  let row : @pg.Row = { data: {} }
  let result = try {
    Result::Ok(get_optional_int(row, "score"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::ColumnNotFound("score")) => ()
    _ => fail("expected ColumnNotFound")
  }
}

test "get_optional_int: type mismatch from Str" {
  let row : @pg.Row = { data: { "score": @pg.Str("100") } }
  let result = try {
    Result::Ok(get_optional_int(row, "score"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("score", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

// ========================================================
// get_optional_bool
// ========================================================

test "get_optional_bool: present true" {
  let row : @pg.Row = { data: { "verified": @pg.Bool(true) } }
  assert_eq(get_optional_bool(row, "verified"), Some(true))
}

test "get_optional_bool: present false" {
  let row : @pg.Row = { data: { "verified": @pg.Bool(false) } }
  assert_eq(get_optional_bool(row, "verified"), Some(false))
}

test "get_optional_bool: null value" {
  let row : @pg.Row = { data: { "verified": @pg.Null } }
  assert_eq(get_optional_bool(row, "verified"), None)
}

test "get_optional_bool: column not found" {
  let row : @pg.Row = { data: {} }
  let result = try {
    Result::Ok(get_optional_bool(row, "verified"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::ColumnNotFound("verified")) => ()
    _ => fail("expected ColumnNotFound")
  }
}

test "get_optional_bool: type mismatch from Int" {
  let row : @pg.Row = { data: { "verified": @pg.Int(1) } }
  let result = try {
    Result::Ok(get_optional_bool(row, "verified"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("verified", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

// ========================================================
// get_optional_double
// ========================================================

test "get_optional_double: from Double" {
  let row : @pg.Row = { data: { "price": @pg.Double(9.99) } }
  assert_eq(get_optional_double(row, "price"), Some(9.99))
}

test "get_optional_double: null value" {
  let row : @pg.Row = { data: { "price": @pg.Null } }
  assert_eq(get_optional_double(row, "price"), None)
}

test "get_optional_double: from Int (implicit conversion)" {
  let row : @pg.Row = { data: { "price": @pg.Int(10) } }
  assert_eq(get_optional_double(row, "price"), Some(10.0))
}

test "get_optional_double: type mismatch from Str" {
  let row : @pg.Row = { data: { "price": @pg.Str("9.99") } }
  let result = try {
    Result::Ok(get_optional_double(row, "price"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("price", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "get_optional_double: column not found" {
  let row : @pg.Row = { data: {} }
  let result = try {
    Result::Ok(get_optional_double(row, "price"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::ColumnNotFound("price")) => ()
    _ => fail("expected ColumnNotFound")
  }
}

// ========================================================
// get_optional_int64
// ========================================================

test "get_optional_int64: from Int64" {
  let row : @pg.Row = { data: { "big_id": @pg.Int64(9999999999L) } }
  assert_eq(get_optional_int64(row, "big_id"), Some(9999999999L))
}

test "get_optional_int64: null value" {
  let row : @pg.Row = { data: { "big_id": @pg.Null } }
  assert_eq(get_optional_int64(row, "big_id"), None)
}

test "get_optional_int64: from Int (implicit conversion)" {
  let row : @pg.Row = { data: { "id": @pg.Int(42) } }
  assert_eq(get_optional_int64(row, "id"), Some(42L))
}

test "get_optional_int64: type mismatch from Str" {
  let row : @pg.Row = { data: { "id": @pg.Str("big") } }
  let result = try {
    Result::Ok(get_optional_int64(row, "id"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("id", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "get_optional_int64: column not found" {
  let row : @pg.Row = { data: {} }
  let result = try {
    Result::Ok(get_optional_int64(row, "id"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::ColumnNotFound("id")) => ()
    _ => fail("expected ColumnNotFound")
  }
}

// ========================================================
// get_json
// ========================================================

test "get_json: existing column" {
  let row : @pg.Row = { data: { "meta": @pg.Json("{\"key\":\"value\"}") } }
  assert_eq(get_json(row, "meta"), "{\"key\":\"value\"}")
}

test "get_json: column not found" {
  let row : @pg.Row = { data: {} }
  let result = try {
    Result::Ok(get_json(row, "meta"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::ColumnNotFound("meta")) => ()
    _ => fail("expected ColumnNotFound")
  }
}

test "get_json: type mismatch from Str" {
  let row : @pg.Row = { data: { "meta": @pg.Str("not json") } }
  let result = try {
    Result::Ok(get_json(row, "meta"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("meta", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "get_json: type mismatch from Int" {
  let row : @pg.Row = { data: { "meta": @pg.Int(42) } }
  let result = try {
    Result::Ok(get_json(row, "meta"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("meta", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "get_json: null value raises NullValue" {
  let row : @pg.Row = { data: { "meta": @pg.Null } }
  let result = try {
    Result::Ok(get_json(row, "meta"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::NullValue("meta")) => ()
    _ => fail("expected NullValue")
  }
}

test "get_json: empty json object" {
  let row : @pg.Row = { data: { "meta": @pg.Json("{}") } }
  assert_eq(get_json(row, "meta"), "{}")
}

// ========================================================
// get_optional_json
// ========================================================

test "get_optional_json: present value" {
  let row : @pg.Row = { data: { "meta": @pg.Json("[1,2,3]") } }
  assert_eq(get_optional_json(row, "meta"), Some("[1,2,3]"))
}

test "get_optional_json: null value" {
  let row : @pg.Row = { data: { "meta": @pg.Null } }
  assert_eq(get_optional_json(row, "meta"), None)
}

test "get_optional_json: empty json object" {
  let row : @pg.Row = { data: { "meta": @pg.Json("{}") } }
  assert_eq(get_optional_json(row, "meta"), Some("{}"))
}

test "get_optional_json: column not found" {
  let row : @pg.Row = { data: {} }
  let result = try {
    Result::Ok(get_optional_json(row, "meta"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::ColumnNotFound("meta")) => ()
    _ => fail("expected ColumnNotFound")
  }
}

test "get_optional_json: type mismatch from Int" {
  let row : @pg.Row = { data: { "meta": @pg.Int(42) } }
  let result = try {
    Result::Ok(get_optional_json(row, "meta"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("meta", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

// ========================================================
// Cross-type boundary tests
// ========================================================

test "get_double: does not accept Bool" {
  let row : @pg.Row = { data: { "val": @pg.Bool(true) } }
  let result = try {
    Result::Ok(get_double(row, "val"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("val", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "get_int64: does not accept Double" {
  let row : @pg.Row = { data: { "val": @pg.Double(3.14) } }
  let result = try {
    Result::Ok(get_int64(row, "val"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("val", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "row with multiple columns" {
  let row : @pg.Row = {
    data: {
      "id": @pg.Int(1),
      "name": @pg.Str("Alice"),
      "active": @pg.Bool(true),
      "score": @pg.Double(99.5),
      "big_id": @pg.Int64(1000000000L),
      "bio": @pg.Null,
      "meta": @pg.Json("{\"role\":\"admin\"}"),
    },
  }
  assert_eq(get_int(row, "id"), 1)
  assert_eq(get_str(row, "name"), "Alice")
  assert_eq(get_bool(row, "active"), true)
  assert_eq(get_double(row, "score"), 99.5)
  assert_eq(get_int64(row, "big_id"), 1000000000L)
  assert_eq(get_optional_str(row, "bio"), None)
  assert_eq(get_json(row, "meta"), "{\"role\":\"admin\"}")
}
