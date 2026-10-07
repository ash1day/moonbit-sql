///| Integration test: connect, create table, insert, query, drop table
test "native pg integration: basic CRUD" {
  let conn = Connection::connect("postgresql://localhost/postgres")
  // Create a temporary table
  let create_sql : @ast.CompiledQuery = {
    sql: "CREATE TEMPORARY TABLE _moonbit_sql_test (id INT, name TEXT, active BOOLEAN)",
    params: [],
  }
  let _ = conn.query(create_sql)
  // Insert rows
  let insert_sql : @ast.CompiledQuery = {
    sql: "INSERT INTO _moonbit_sql_test (id, name, active) VALUES ($1, $2, $3)",
    params: [@ast.Value::Int(1), @ast.Value::String("alice"), @ast.Value::Bool(true)],
  }
  let _ = conn.query(insert_sql)
  let insert_sql2 : @ast.CompiledQuery = {
    sql: "INSERT INTO _moonbit_sql_test (id, name, active) VALUES ($1, $2, $3)",
    params: [@ast.Value::Int(2), @ast.Value::String("bob"), @ast.Value::Bool(false)],
  }
  let _ = conn.query(insert_sql2)
  // Query all rows
  let select_sql : @ast.CompiledQuery = {
    sql: "SELECT id, name, active FROM _moonbit_sql_test ORDER BY id",
    params: [],
  }
  let rows = conn.query(select_sql)
  assert_eq(rows.length(), 2)
  // Check first row
  let row0 = rows[0]
  assert_eq(row0.data.get("id"), Option::Some(ColumnValue::Int(1)))
  assert_eq(row0.data.get("name"), Option::Some(ColumnValue::Str("alice")))
  assert_eq(row0.data.get("active"), Option::Some(ColumnValue::Bool(true)))
  // Check second row
  let row1 = rows[1]
  assert_eq(row1.data.get("id"), Option::Some(ColumnValue::Int(2)))
  assert_eq(row1.data.get("name"), Option::Some(ColumnValue::Str("bob")))
  assert_eq(row1.data.get("active"), Option::Some(ColumnValue::Bool(false)))
  // Query with WHERE parameter
  let where_sql : @ast.CompiledQuery = {
    sql: "SELECT name FROM _moonbit_sql_test WHERE id = $1",
    params: [@ast.Value::Int(1)],
  }
  let filtered = conn.query(where_sql)
  assert_eq(filtered.length(), 1)
  assert_eq(
    filtered[0].data.get("name"), Option::Some(ColumnValue::Str("alice")),
  )
  // Clean up (temp table is auto-dropped, but close connection)
  conn.close()
}
