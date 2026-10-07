///| Test value_to_json for Null
test "value_to_json: null" {
  assert_eq(value_to_json(@ast.Value::Null), "null")
}

///| Test value_to_json for Bool true
test "value_to_json: true" {
  assert_eq(value_to_json(@ast.Value::Bool(true)), "true")
}

///| Test value_to_json for Bool false
test "value_to_json: false" {
  assert_eq(value_to_json(@ast.Value::Bool(false)), "false")
}

///| Test value_to_json for Int
test "value_to_json: int" {
  assert_eq(value_to_json(@ast.Value::Int(42)), "42")
}

///| Test value_to_json for negative Int
test "value_to_json: negative int" {
  assert_eq(value_to_json(@ast.Value::Int(-1)), "-1")
}

///| Test value_to_json for Int64
test "value_to_json: int64" {
  assert_eq(value_to_json(@ast.Value::Int64(9999999999L)), "9999999999")
}

///| Test value_to_json for Double
test "value_to_json: double" {
  assert_eq(value_to_json(@ast.Value::Double(3.14)), "3.14")
}

///| Test value_to_json for simple String
test "value_to_json: simple string" {
  assert_eq(value_to_json(@ast.Value::String("hello")), "\"hello\"")
}

///| Test value_to_json for String with special characters
test "value_to_json: string with escapes" {
  assert_eq(
    value_to_json(@ast.Value::String("a\"b\\c")), "\"a\\\"b\\\\c\"",
  )
}

///| Test value_to_json for String with newline and tab
test "value_to_json: string with newline and tab" {
  assert_eq(
    value_to_json(@ast.Value::String("a\nb\tc")), "\"a\\nb\\tc\"",
  )
}

///| Test value_to_json for String with carriage return
test "value_to_json: string with carriage return" {
  assert_eq(value_to_json(@ast.Value::String("a\rb")), "\"a\\rb\"")
}

///| Test value_to_json for empty String
test "value_to_json: empty string" {
  assert_eq(value_to_json(@ast.Value::String("")), "\"\"")
}

///| Test params_to_json with empty array
test "params_to_json: empty" {
  let params : Array[@ast.Value] = []
  assert_eq(params_to_json(params), "[]")
}

///| Test params_to_json with single param
test "params_to_json: single" {
  let params : Array[@ast.Value] = [@ast.Value::Int(1)]
  assert_eq(params_to_json(params), "[1]")
}

///| Test params_to_json with multiple params
test "params_to_json: multiple" {
  let params : Array[@ast.Value] = [
    @ast.Value::Int(1),
    @ast.Value::String("hello"),
    @ast.Value::Null,
    @ast.Value::Bool(true),
  ]
  assert_eq(params_to_json(params), "[1, \"hello\", null, true]")
}

///| Test params_to_json with all types
test "params_to_json: all types" {
  let params : Array[@ast.Value] = [
    @ast.Value::Null,
    @ast.Value::Bool(false),
    @ast.Value::Int(42),
    @ast.Value::Int64(100L),
    @ast.Value::Double(1.5),
    @ast.Value::String("test"),
  ]
  assert_eq(params_to_json(params), "[null, false, 42, 100, 1.5, \"test\"]")
}
