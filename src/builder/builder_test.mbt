// ========================================================
// SELECT: Basic queries
// ========================================================

///|
test "select all columns" {
  let q = @builder.select().all().from("users").build()
  assert_eq(q.sql, "SELECT * FROM \"users\"")
  assert_eq(q.params, [])
}

///|
test "select with named columns" {
  let q = @builder.select()
    .columns(["id", "name", "email"])
    .from("users")
    .build()
  assert_eq(q.sql, "SELECT \"id\", \"name\", \"email\" FROM \"users\"")
  assert_eq(q.params, [])
}

///|
test "select single column" {
  let q = @builder.select().column("id").from("users").build()
  assert_eq(q.sql, "SELECT \"id\" FROM \"users\"")
  assert_eq(q.params, [])
}

///|
test "select with limit and offset" {
  let q = @builder.select()
    .columns(["character", "size_w", "size_h"])
    .from("character")
    .limit(10)
    .offset(100)
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\", \"size_w\", \"size_h\" FROM \"character\" LIMIT $1 OFFSET $2",
  )
  assert_eq(q.params, [@ast.Value::Int(10), @ast.Value::Int(100)])
}

///|
test "select with limit only" {
  let q = @builder.select().all().from("users").limit(5).build()
  assert_eq(q.sql, "SELECT * FROM \"users\" LIMIT $1")
  assert_eq(q.params, [@ast.Value::Int(5)])
}

// ========================================================
// SELECT: DISTINCT
// ========================================================

///|
test "select distinct" {
  let q = @builder.select().distinct().columns(["name"]).from("users").build()
  assert_eq(q.sql, "SELECT DISTINCT \"name\" FROM \"users\"")
  assert_eq(q.params, [])
}

///|
test "select distinct with multiple columns" {
  let q = @builder.select()
    .distinct()
    .columns(["department", "role"])
    .from("employees")
    .build()
  assert_eq(
    q.sql,
    "SELECT DISTINCT \"department\", \"role\" FROM \"employees\"",
  )
  assert_eq(q.params, [])
}

// ========================================================
// SELECT: WHERE conditions
// ========================================================

///|
test "select with where eq" {
  let q = @builder.select()
    .columns(["character", "size_w", "size_h"])
    .from("character")
    .where_(@builder.col("size_w").eq(@builder.val_int(3)))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\", \"size_w\", \"size_h\" FROM \"character\" WHERE (\"size_w\" = $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(3)])
}

///|
test "select with multiple where (AND)" {
  let q = @builder.select()
    .columns(["character", "size_w", "size_h"])
    .from("character")
    .where_(@builder.col("size_w").eq(@builder.val_int(3)))
    .where_(@builder.col("size_h").eq(@builder.val_int(4)))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\", \"size_w\", \"size_h\" FROM \"character\" WHERE ((\"size_w\" = $1) AND (\"size_h\" = $2))",
  )
  assert_eq(q.params, [@ast.Value::Int(3), @ast.Value::Int(4)])
}

///|
test "select with three where conditions" {
  let q = @builder.select()
    .columns(["character", "size_w", "size_h"])
    .from("character")
    .where_(@builder.col("size_w").eq(@builder.val_int(3)))
    .where_(@builder.col("size_h").eq(@builder.val_int(4)))
    .where_(@builder.col("size_h").eq(@builder.val_int(5)))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\", \"size_w\", \"size_h\" FROM \"character\" WHERE (((\"size_w\" = $1) AND (\"size_h\" = $2)) AND (\"size_h\" = $3))",
  )
  assert_eq(q.params, [
    @ast.Value::Int(3),
    @ast.Value::Int(4),
    @ast.Value::Int(5),
  ])
}

///|
test "select with or condition" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(
      @builder.col("role")
      .eq(@builder.val_str("admin"))
      .or_(@builder.col("role").eq(@builder.val_str("mod"))),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE ((\"role\" = $1) OR (\"role\" = $2))",
  )
  assert_eq(q.params, [@ast.Value::String("admin"), @ast.Value::String("mod")])
}

///|
test "select with or three conditions" {
  let q = @builder.select()
    .columns(["character", "size_w", "size_h"])
    .from("character")
    .where_(
      @builder.col("size_w")
      .eq(@builder.val_int(3))
      .or_(@builder.col("size_h").eq(@builder.val_int(4)))
      .or_(@builder.col("size_h").eq(@builder.val_int(5))),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\", \"size_w\", \"size_h\" FROM \"character\" WHERE (((\"size_w\" = $1) OR (\"size_h\" = $2)) OR (\"size_h\" = $3))",
  )
  assert_eq(q.params, [
    @ast.Value::Int(3),
    @ast.Value::Int(4),
    @ast.Value::Int(5),
  ])
}

///|
test "select with nested and/or" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(
      @builder.col("a")
      .eq(@builder.val_int(1))
      .and_(@builder.col("b").eq(@builder.val_int(2)))
      .or_(@builder.col("c").eq(@builder.val_int(3))),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE (((\"a\" = $1) AND (\"b\" = $2)) OR (\"c\" = $3))",
  )
  assert_eq(q.params, [
    @ast.Value::Int(1),
    @ast.Value::Int(2),
    @ast.Value::Int(3),
  ])
}

///|
test "select with complex nested conditions" {
  // (A LIKE 'C' OR (D LIKE 'D' AND E LIKE 'E')) AND (F LIKE 'F' OR G LIKE 'G')
  let q = @builder.select()
    .column("character")
    .from("character")
    .where_(
      @builder.col("character")
      .like("C")
      .or_(
        @builder.col("character")
        .like("D")
        .and_(@builder.col("character").like("E")),
      )
      .and_(
        @builder.col("character")
        .like("F")
        .or_(@builder.col("character").like("G")),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" WHERE (((\"character\" LIKE $1) OR ((\"character\" LIKE $2) AND (\"character\" LIKE $3))) AND ((\"character\" LIKE $4) OR (\"character\" LIKE $5)))",
  )
  assert_eq(q.params, [
    @ast.Value::String("C"),
    @ast.Value::String("D"),
    @ast.Value::String("E"),
    @ast.Value::String("F"),
    @ast.Value::String("G"),
  ])
}

// ========================================================
// SELECT: Comparison operators
// ========================================================

///|
test "select with ne operator" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.col("status").ne(@builder.val_str("deleted")))
    .build()
  assert_eq(q.sql, "SELECT * FROM \"users\" WHERE (\"status\" <> $1)")
  assert_eq(q.params, [@ast.Value::String("deleted")])
}

///|
test "select with lt operator" {
  let q = @builder.select()
    .all()
    .from("products")
    .where_(@builder.col("price").lt(@builder.val_int(100)))
    .build()
  assert_eq(q.sql, "SELECT * FROM \"products\" WHERE (\"price\" < $1)")
  assert_eq(q.params, [@ast.Value::Int(100)])
}

///|
test "select with gt operator" {
  let q = @builder.select()
    .columns(["id", "name"])
    .from("users")
    .where_(@builder.col("age").gt(@builder.val_int(18)))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"id\", \"name\" FROM \"users\" WHERE (\"age\" > $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(18)])
}

///|
test "select with gte operator" {
  let q = @builder.select()
    .all()
    .from("products")
    .where_(@builder.col("stock").gte(@builder.val_int(0)))
    .build()
  assert_eq(q.sql, "SELECT * FROM \"products\" WHERE (\"stock\" >= $1)")
  assert_eq(q.params, [@ast.Value::Int(0)])
}

///|
test "select with lte operator" {
  let q = @builder.select()
    .all()
    .from("products")
    .where_(@builder.col("price").lte(@builder.val_int(1000)))
    .build()
  assert_eq(q.sql, "SELECT * FROM \"products\" WHERE (\"price\" <= $1)")
  assert_eq(q.params, [@ast.Value::Int(1000)])
}

// ========================================================
// SELECT: IS NULL / IS NOT NULL
// ========================================================

///|
test "select with is null" {
  let q = @builder.select()
    .columns(["character"])
    .from("character")
    .where_(@builder.col("font_id").is_null())
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" WHERE \"font_id\" IS NULL",
  )
  assert_eq(q.params, [])
}

///|
test "select with is not null" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.col("email").is_not_null())
    .build()
  assert_eq(q.sql, "SELECT * FROM \"users\" WHERE \"email\" IS NOT NULL")
  assert_eq(q.params, [])
}

///|
test "select with is null and is not null combined" {
  let q = @builder.select()
    .columns(["character"])
    .from("character")
    .where_(@builder.col("font_id").is_null())
    .where_(@builder.col("character").is_not_null())
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" WHERE (\"font_id\" IS NULL AND \"character\" IS NOT NULL)",
  )
  assert_eq(q.params, [])
}

///|
test "select with is null or is not null" {
  let q = @builder.select()
    .column("id")
    .from("glyph")
    .where_(
      @builder.col("aspect").is_null().or_(@builder.col("aspect").is_not_null()),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"id\" FROM \"glyph\" WHERE (\"aspect\" IS NULL OR \"aspect\" IS NOT NULL)",
  )
  assert_eq(q.params, [])
}

// ========================================================
// SELECT: LIKE
// ========================================================

///|
test "select with like" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.col("name").like("%Alice%"))
    .build()
  assert_eq(q.sql, "SELECT * FROM \"users\" WHERE (\"name\" LIKE $1)")
  assert_eq(q.params, [@ast.Value::String("%Alice%")])
}

///|
test "select with multiple like (OR)" {
  let q = @builder.select()
    .columns(["character"])
    .from("character")
    .where_(
      @builder.col("character")
      .like("A%")
      .or_(@builder.col("character").like("%B"))
      .or_(@builder.col("character").like("%C%")),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" WHERE (((\"character\" LIKE $1) OR (\"character\" LIKE $2)) OR (\"character\" LIKE $3))",
  )
  assert_eq(q.params, [
    @ast.Value::String("A%"),
    @ast.Value::String("%B"),
    @ast.Value::String("%C%"),
  ])
}

// ========================================================
// SELECT: IN / NOT IN
// ========================================================

///|
test "select with in list" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(
      @builder.col("id").in_list([
        @builder.val_int(1),
        @builder.val_int(2),
        @builder.val_int(3),
      ]),
    )
    .build()
  assert_eq(q.sql, "SELECT * FROM \"users\" WHERE \"id\" IN ($1, $2, $3)")
  assert_eq(q.params, [
    @ast.Value::Int(1),
    @ast.Value::Int(2),
    @ast.Value::Int(3),
  ])
}

///|
test "select with table-qualified in list" {
  let q = @builder.select()
    .column("image")
    .from("glyph")
    .where_(
      @builder.table_col("glyph", "aspect").in_list([
        @builder.val_int(3),
        @builder.val_int(4),
      ]),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"image\" FROM \"glyph\" WHERE \"glyph\".\"aspect\" IN ($1, $2)",
  )
  assert_eq(q.params, [@ast.Value::Int(3), @ast.Value::Int(4)])
}

///|
test "select with not in list" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(
      @builder.col("status").not_in_list([
        @builder.val_str("banned"),
        @builder.val_str("deleted"),
      ]),
    )
    .build()
  assert_eq(q.sql, "SELECT * FROM \"users\" WHERE \"status\" NOT IN ($1, $2)")
  assert_eq(q.params, [
    @ast.Value::String("banned"),
    @ast.Value::String("deleted"),
  ])
}

///|
test "select with in list and like combined" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(
      @builder.col("id").in_list([
        @builder.val_int(1),
        @builder.val_int(2),
        @builder.val_int(3),
      ]),
    )
    .where_(@builder.col("name").like("A%"))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE (\"id\" IN ($1, $2, $3) AND (\"name\" LIKE $4))",
  )
  assert_eq(q.params, [
    @ast.Value::Int(1),
    @ast.Value::Int(2),
    @ast.Value::Int(3),
    @ast.Value::String("A%"),
  ])
}

// ========================================================
// SELECT: BETWEEN / NOT BETWEEN
// ========================================================

///|
test "select with between" {
  let q = @builder.select()
    .all()
    .from("products")
    .where_(
      @builder.col("price").between(
        @builder.val_int(100),
        @builder.val_int(500),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"products\" WHERE \"price\" BETWEEN $1 AND $2",
  )
  assert_eq(q.params, [@ast.Value::Int(100), @ast.Value::Int(500)])
}

///|
test "select with between table-qualified" {
  let q = @builder.select()
    .column("image")
    .from("glyph")
    .where_(
      @builder.table_col("glyph", "aspect").between(
        @builder.val_int(3),
        @builder.val_int(5),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"image\" FROM \"glyph\" WHERE \"glyph\".\"aspect\" BETWEEN $1 AND $2",
  )
  assert_eq(q.params, [@ast.Value::Int(3), @ast.Value::Int(5)])
}

///|
test "select with not between" {
  let q = @builder.select()
    .all()
    .from("products")
    .where_(
      @builder.col("price").not_between(
        @builder.val_int(800),
        @builder.val_int(1000),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"products\" WHERE \"price\" NOT BETWEEN $1 AND $2",
  )
  assert_eq(q.params, [@ast.Value::Int(800), @ast.Value::Int(1000)])
}

///|
test "select with between and not between combined" {
  let q = @builder.select()
    .columns(["aspect"])
    .from("glyph")
    .where_(
      @builder.col("aspect").between(@builder.val_int(3), @builder.val_int(5)),
    )
    .where_(
      @builder.col("aspect").not_between(
        @builder.val_int(8),
        @builder.val_int(10),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"aspect\" FROM \"glyph\" WHERE (\"aspect\" BETWEEN $1 AND $2 AND \"aspect\" NOT BETWEEN $3 AND $4)",
  )
  assert_eq(q.params, [
    @ast.Value::Int(3),
    @ast.Value::Int(5),
    @ast.Value::Int(8),
    @ast.Value::Int(10),
  ])
}

// ========================================================
// SELECT: Arithmetic expressions
// ========================================================

///|
test "select with arithmetic multiply" {
  let q = @builder.select()
    .expr_as(@builder.col("price").mul(@builder.col("quantity")), "total")
    .from("order_items")
    .build()
  assert_eq(
    q.sql,
    "SELECT (\"price\" * \"quantity\") AS \"total\" FROM \"order_items\"",
  )
  assert_eq(q.params, [])
}

///|
test "select with arithmetic in where" {
  let q = @builder.select()
    .column("character")
    .from("character")
    .where_(
      @builder.col("size_w")
      .mul(@builder.val_int(2))
      .eq(@builder.col("size_h").div(@builder.val_int(2))),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" WHERE ((\"size_w\" * $1) = (\"size_h\" / $2))",
  )
  assert_eq(q.params, [@ast.Value::Int(2), @ast.Value::Int(2)])
}

///|
test "select with complex arithmetic" {
  // (size_w * 2) + (size_h / 3) = 4
  let q = @builder.select()
    .columns(["character", "size_w", "size_h"])
    .from("character")
    .where_(
      @builder.col("size_w")
      .mul(@builder.val_int(2))
      .add(@builder.col("size_h").div(@builder.val_int(3)))
      .eq(@builder.val_int(4)),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\", \"size_w\", \"size_h\" FROM \"character\" WHERE (((\"size_w\" * $1) + (\"size_h\" / $2)) = $3)",
  )
  assert_eq(q.params, [
    @ast.Value::Int(2),
    @ast.Value::Int(3),
    @ast.Value::Int(4),
  ])
}

// ========================================================
// SELECT: NOT expression
// ========================================================

///|
test "select with not expression" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.col("active").eq(@builder.val_bool(true)).not_())
    .build()
  assert_eq(q.sql, "SELECT * FROM \"users\" WHERE (NOT (\"active\" = $1))")
  assert_eq(q.params, [@ast.Value::Bool(true)])
}

///|
test "select with negation" {
  let q = @builder.select()
    .expr(@builder.col("balance").neg())
    .from("accounts")
    .build()
  assert_eq(q.sql, "SELECT (-\"balance\") FROM \"accounts\"")
  assert_eq(q.params, [])
}

// ========================================================
// SELECT: Functions (COUNT, MAX, COALESCE, SUM, etc.)
// ========================================================

///|
test "select with count star" {
  let q = @builder.select()
    .expr(@builder.func("COUNT", [@builder.asterisk()]))
    .from("users")
    .build()
  assert_eq(q.sql, "SELECT COUNT(*) FROM \"users\"")
  assert_eq(q.params, [])
}

///|
test "select with count star alias" {
  let q = @builder.select()
    .expr_as(@builder.func("COUNT", [@builder.asterisk()]), "total")
    .from("users")
    .build()
  assert_eq(q.sql, "SELECT COUNT(*) AS \"total\" FROM \"users\"")
  assert_eq(q.params, [])
}

///|
test "select with max function" {
  let q = @builder.select()
    .column("aspect")
    .expr(@builder.func("MAX", [@builder.col("image")]))
    .from("glyph")
    .group_by("aspect")
    .having(@builder.col("aspect").gt(@builder.val_int(2)))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"aspect\", MAX(\"image\") FROM \"glyph\" GROUP BY \"aspect\" HAVING (\"aspect\" > $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(2)])
}

///|
test "select with coalesce" {
  let q = @builder.select()
    .expr(
      @builder.func("COALESCE", [
        @builder.col("nickname"),
        @builder.col("name"),
        @builder.val_str("Anonymous"),
      ]),
    )
    .from("users")
    .build()
  assert_eq(q.sql, "SELECT COALESCE(\"nickname\", \"name\", $1) FROM \"users\"")
  assert_eq(q.params, [@ast.Value::String("Anonymous")])
}

///|
test "select with coalesce in where" {
  // COALESCE("aspect", 0) > 2
  let q = @builder.select()
    .columns(["aspect"])
    .from("glyph")
    .where_(
      @builder.func("COALESCE", [@builder.col("aspect"), @builder.val_int(0)]).gt(
        @builder.val_int(2),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"aspect\" FROM \"glyph\" WHERE (COALESCE(\"aspect\", $1) > $2)",
  )
  assert_eq(q.params, [@ast.Value::Int(0), @ast.Value::Int(2)])
}

///|
test "select with sum function" {
  let q = @builder.select()
    .expr_as(@builder.func("SUM", [@builder.col("amount")]), "total_amount")
    .from("transactions")
    .build()
  assert_eq(
    q.sql,
    "SELECT SUM(\"amount\") AS \"total_amount\" FROM \"transactions\"",
  )
  assert_eq(q.params, [])
}

///|
test "select with avg function" {
  let q = @builder.select()
    .expr_as(@builder.func("AVG", [@builder.col("price")]), "avg_price")
    .from("products")
    .build()
  assert_eq(q.sql, "SELECT AVG(\"price\") AS \"avg_price\" FROM \"products\"")
  assert_eq(q.params, [])
}

///|
test "select with min function" {
  let q = @builder.select()
    .expr_as(@builder.func("MIN", [@builder.col("created_at")]), "earliest")
    .from("events")
    .build()
  assert_eq(q.sql, "SELECT MIN(\"created_at\") AS \"earliest\" FROM \"events\"")
  assert_eq(q.params, [])
}

// ========================================================
// SELECT: Expression alias
// ========================================================

///|
test "select with expression alias" {
  let q = @builder.select()
    .expr_as(@builder.col("character"), "C")
    .from("character")
    .build()
  assert_eq(q.sql, "SELECT \"character\" AS \"C\" FROM \"character\"")
  assert_eq(q.params, [])
}

// ========================================================
// SELECT: Table references
// ========================================================

///|
test "select with table all columns" {
  let q = @builder.select().table_all_columns("users").from("users").build()
  assert_eq(q.sql, "SELECT \"users\".* FROM \"users\"")
  assert_eq(q.params, [])
}

///|
test "select with table all columns and named column" {
  let q = @builder.select()
    .table_all_columns("character")
    .expr(@ast.Expr::Column(@ast.ColumnRef::TableColumn("font", "name")))
    .from("character")
    .join(
      "font",
      @builder.table_col("character", "font_id").eq(
        @builder.table_col("font", "id"),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\".*, \"font\".\"name\" FROM \"character\" INNER JOIN \"font\" ON (\"character\".\"font_id\" = \"font\".\"id\")",
  )
  assert_eq(q.params, [])
}

///|
test "select with from_as alias" {
  let q = @builder.select()
    .columns(["id", "name"])
    .from_as("users", "u")
    .build()
  assert_eq(q.sql, "SELECT \"id\", \"name\" FROM \"users\" AS \"u\"")
  assert_eq(q.params, [])
}

///|
test "select with schema-qualified table" {
  let q = @builder.select().all().from_schema("public", "users").build()
  assert_eq(q.sql, "SELECT * FROM \"public\".\"users\"")
  assert_eq(q.params, [])
}

///|
test "select with table qualified columns" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.table_col("users", "id").eq(@builder.val_int(1)))
    .build()
  assert_eq(q.sql, "SELECT * FROM \"users\" WHERE (\"users\".\"id\" = $1)")
  assert_eq(q.params, [@ast.Value::Int(1)])
}

// ========================================================
// SELECT: JOINs
// ========================================================

///|
test "select with inner join" {
  let q = @builder.select()
    .columns(["name", "total"])
    .from("users")
    .join(
      "orders",
      @builder.table_col("users", "id").eq(
        @builder.table_col("orders", "user_id"),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"name\", \"total\" FROM \"users\" INNER JOIN \"orders\" ON (\"users\".\"id\" = \"orders\".\"user_id\")",
  )
  assert_eq(q.params, [])
}

///|
test "select with left join" {
  let q = @builder.select()
    .columns(["character"])
    .from("character")
    .left_join(
      "font",
      @builder.table_col("character", "font_id").eq(
        @builder.table_col("font", "id"),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" LEFT JOIN \"font\" ON (\"character\".\"font_id\" = \"font\".\"id\")",
  )
  assert_eq(q.params, [])
}

///|
test "select with right join" {
  let q = @builder.select()
    .columns(["name"])
    .from("users")
    .right_join(
      "orders",
      @builder.table_col("users", "id").eq(
        @builder.table_col("orders", "user_id"),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"name\" FROM \"users\" RIGHT JOIN \"orders\" ON (\"users\".\"id\" = \"orders\".\"user_id\")",
  )
  assert_eq(q.params, [])
}

///|
test "select with full join" {
  let q = @builder.select()
    .all()
    .from("left_table")
    .full_join(
      "right_table",
      @builder.table_col("left_table", "id").eq(
        @builder.table_col("right_table", "id"),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"left_table\" FULL JOIN \"right_table\" ON (\"left_table\".\"id\" = \"right_table\".\"id\")",
  )
  assert_eq(q.params, [])
}

///|
test "select with cross join" {
  let q = @builder.select().all().from("colors").cross_join("sizes").build()
  assert_eq(q.sql, "SELECT * FROM \"colors\" CROSS JOIN \"sizes\"")
  assert_eq(q.params, [])
}

///|
test "select with multiple joins" {
  let q = @builder.select()
    .all()
    .from("orders")
    .join(
      "users",
      @builder.table_col("orders", "user_id").eq(
        @builder.table_col("users", "id"),
      ),
    )
    .left_join(
      "products",
      @builder.table_col("orders", "product_id").eq(
        @builder.table_col("products", "id"),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"orders\" INNER JOIN \"users\" ON (\"orders\".\"user_id\" = \"users\".\"id\") LEFT JOIN \"products\" ON (\"orders\".\"product_id\" = \"products\".\"id\")",
  )
  assert_eq(q.params, [])
}

///|
test "select with left join then inner join" {
  let q = @builder.select()
    .columns(["character"])
    .from("character")
    .left_join(
      "font",
      @builder.table_col("character", "font_id").eq(
        @builder.table_col("font", "id"),
      ),
    )
    .join(
      "glyph",
      @builder.table_col("character", "character").eq(
        @builder.table_col("glyph", "image"),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" LEFT JOIN \"font\" ON (\"character\".\"font_id\" = \"font\".\"id\") INNER JOIN \"glyph\" ON (\"character\".\"character\" = \"glyph\".\"image\")",
  )
  assert_eq(q.params, [])
}

///|
test "select with join compound on condition" {
  let q = @builder.select()
    .columns(["character"])
    .from("character")
    .left_join(
      "font",
      @builder.table_col("character", "font_id")
      .eq(@builder.table_col("font", "id"))
      .and_(
        @builder.table_col("character", "font_id").eq(
          @builder.table_col("font", "id"),
        ),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" LEFT JOIN \"font\" ON ((\"character\".\"font_id\" = \"font\".\"id\") AND (\"character\".\"font_id\" = \"font\".\"id\"))",
  )
  assert_eq(q.params, [])
}

///|
test "select with join and where" {
  let q = @builder.select()
    .columns(["name", "total"])
    .from("users")
    .join(
      "orders",
      @builder.table_col("users", "id").eq(
        @builder.table_col("orders", "user_id"),
      ),
    )
    .where_(@builder.col("total").gt(@builder.val_int(100)))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"name\", \"total\" FROM \"users\" INNER JOIN \"orders\" ON (\"users\".\"id\" = \"orders\".\"user_id\") WHERE (\"total\" > $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(100)])
}

// ========================================================
// SELECT: GROUP BY + HAVING
// ========================================================

///|
test "select with group by and having" {
  let q = @builder.select()
    .column("department")
    .expr(@builder.func("COUNT", [@builder.asterisk()]))
    .from("employees")
    .group_by("department")
    .having(
      @builder.func("COUNT", [@builder.asterisk()]).gt(@builder.val_int(5)),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"department\", COUNT(*) FROM \"employees\" GROUP BY \"department\" HAVING (COUNT(*) > $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(5)])
}

///|
test "select with group by table-qualified" {
  let q = @builder.select()
    .columns(["id", "aspect"])
    .expr(@builder.func("MAX", [@builder.col("image")]))
    .from("glyph")
    .group_by("id")
    .group_by("aspect")
    .having(@builder.col("aspect").gt(@builder.val_int(2)))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"id\", \"aspect\", MAX(\"image\") FROM \"glyph\" GROUP BY \"id\", \"aspect\" HAVING (\"aspect\" > $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(2)])
}

// ========================================================
// SELECT: ORDER BY
// ========================================================

///|
test "select with order by asc" {
  let q = @builder.select()
    .all()
    .from("users")
    .order_by("name", @ast.Asc)
    .limit(10)
    .offset(20)
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" ORDER BY \"name\" ASC LIMIT $1 OFFSET $2",
  )
  assert_eq(q.params, [@ast.Value::Int(10), @ast.Value::Int(20)])
}

///|
test "select with multiple order by" {
  let q = @builder.select()
    .all()
    .from("users")
    .order_by("last_name", @ast.Asc)
    .order_by("created_at", @ast.Desc)
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" ORDER BY \"last_name\" ASC, \"created_at\" DESC",
  )
  assert_eq(q.params, [])
}

///|
test "select with order by table-qualified" {
  let q = @builder.select()
    .columns(["aspect"])
    .from("glyph")
    .where_(
      @builder.func("COALESCE", [@builder.col("aspect"), @builder.val_int(0)]).gt(
        @builder.val_int(2),
      ),
    )
    .order_by("image", @ast.Desc)
    .order_by_table("glyph", "aspect", @ast.Asc)
    .build()
  assert_eq(
    q.sql,
    "SELECT \"aspect\" FROM \"glyph\" WHERE (COALESCE(\"aspect\", $1) > $2) ORDER BY \"image\" DESC, \"glyph\".\"aspect\" ASC",
  )
  assert_eq(q.params, [@ast.Value::Int(0), @ast.Value::Int(2)])
}

// ========================================================
// SELECT: Value types
// ========================================================

///|
test "select with null parameter" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.col("name").eq(@builder.val_null()))
    .build()
  assert_eq(q.sql, "SELECT * FROM \"users\" WHERE (\"name\" = $1)")
  assert_eq(q.params, [@ast.Value::Null])
}

///|
test "select with double value" {
  let q = @builder.select()
    .all()
    .from("products")
    .where_(@builder.col("rating").gte(@builder.val_double(4.5)))
    .build()
  assert_eq(q.sql, "SELECT * FROM \"products\" WHERE (\"rating\" >= $1)")
  assert_eq(q.params, [@ast.Value::Double(4.5)])
}

///|
test "select with int64 value" {
  let q = @builder.select()
    .all()
    .from("events")
    .where_(@builder.col("timestamp").gt(@builder.val_int64(1700000000L)))
    .build()
  assert_eq(q.sql, "SELECT * FROM \"events\" WHERE (\"timestamp\" > $1)")
  assert_eq(q.params, [@ast.Value::Int64(1700000000L)])
}

///|
test "select with bool value" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.col("active").eq(@builder.val_bool(true)))
    .build()
  assert_eq(q.sql, "SELECT * FROM \"users\" WHERE (\"active\" = $1)")
  assert_eq(q.params, [@ast.Value::Bool(true)])
}

///|
test "select with string value" {
  let q = @builder.select()
    .columns(["character"])
    .from("character")
    .where_(@builder.col("character").eq(@builder.val_str("A")))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" WHERE (\"character\" = $1)",
  )
  assert_eq(q.params, [@ast.Value::String("A")])
}

// ========================================================
// SELECT: Parameter numbering
// ========================================================

///|
test "select param numbering across clauses" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.col("age").gt(@builder.val_int(18)))
    .where_(@builder.col("name").like("%test%"))
    .limit(10)
    .offset(0)
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE ((\"age\" > $1) AND (\"name\" LIKE $2)) LIMIT $3 OFFSET $4",
  )
  assert_eq(q.params, [
    @ast.Value::Int(18),
    @ast.Value::String("%test%"),
    @ast.Value::Int(10),
    @ast.Value::Int(0),
  ])
}

///|
test "select same values get separate params" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.col("a").eq(@builder.val_int(1)))
    .where_(@builder.col("b").eq(@builder.val_int(1)))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE ((\"a\" = $1) AND (\"b\" = $2))",
  )
  assert_eq(q.params, [@ast.Value::Int(1), @ast.Value::Int(1)])
}

// ========================================================
// INSERT: Basic
// ========================================================

///|
test "insert basic" {
  let q = @builder.insert_into("users")
    .columns(["name", "email"])
    .values([@builder.val_str("Alice"), @builder.val_str("alice@example.com")])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"users\" (\"name\", \"email\") VALUES ($1, $2)",
  )
  assert_eq(q.params, [
    @ast.Value::String("Alice"),
    @ast.Value::String("alice@example.com"),
  ])
}

///|
test "insert with double value" {
  let q = @builder.insert_into("glyph")
    .columns(["image", "aspect"])
    .values([@builder.val_str("04108048"), @builder.val_double(3.1415)])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"glyph\" (\"image\", \"aspect\") VALUES ($1, $2)",
  )
  assert_eq(q.params, [
    @ast.Value::String("04108048"),
    @ast.Value::Double(3.1415),
  ])
}

///|
test "insert multi-row" {
  let q = @builder.insert_into("users")
    .columns(["name", "email"])
    .values([@builder.val_str("Alice"), @builder.val_str("alice@example.com")])
    .values([@builder.val_str("Bob"), @builder.val_str("bob@example.com")])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"users\" (\"name\", \"email\") VALUES ($1, $2), ($3, $4)",
  )
  assert_eq(q.params, [
    @ast.Value::String("Alice"),
    @ast.Value::String("alice@example.com"),
    @ast.Value::String("Bob"),
    @ast.Value::String("bob@example.com"),
  ])
}

///|
test "insert multi-row with null" {
  let q = @builder.insert_into("glyph")
    .columns(["image", "aspect"])
    .values([@builder.val_str("image1"), @builder.val_double(3.1415)])
    .values([@builder.val_null(), @builder.val_double(2.1345)])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"glyph\" (\"image\", \"aspect\") VALUES ($1, $2), ($3, $4)",
  )
  assert_eq(q.params, [
    @ast.Value::String("image1"),
    @ast.Value::Double(3.1415),
    @ast.Value::Null,
    @ast.Value::Double(2.1345),
  ])
}

// ========================================================
// INSERT: RETURNING
// ========================================================

///|
test "insert with returning" {
  let q = @builder.insert_into("users")
    .columns(["name", "email"])
    .values([@builder.val_str("Bob"), @builder.val_str("bob@example.com")])
    .returning(["id"])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"users\" (\"name\", \"email\") VALUES ($1, $2) RETURNING \"id\"",
  )
  assert_eq(q.params, [
    @ast.Value::String("Bob"),
    @ast.Value::String("bob@example.com"),
  ])
}

///|
test "insert with multiple returning" {
  let q = @builder.insert_into("users")
    .columns(["name"])
    .values([@builder.val_str("Charlie")])
    .returning(["id", "created_at"])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"users\" (\"name\") VALUES ($1) RETURNING \"id\", \"created_at\"",
  )
  assert_eq(q.params, [@ast.Value::String("Charlie")])
}

// ========================================================
// UPDATE: Basic
// ========================================================

///|
test "update basic" {
  let q = @builder.update("users")
    .set("name", @builder.val_str("Bob"))
    .set("active", @builder.val_bool(true))
    .where_(@builder.col("id").eq(@builder.val_int(1)))
    .build()
  assert_eq(
    q.sql,
    "UPDATE \"users\" SET \"name\" = $1, \"active\" = $2 WHERE (\"id\" = $3)",
  )
  assert_eq(q.params, [
    @ast.Value::String("Bob"),
    @ast.Value::Bool(true),
    @ast.Value::Int(1),
  ])
}

///|
test "update without where" {
  let q = @builder.update("settings")
    .set("value", @builder.val_str("default"))
    .build()
  assert_eq(q.sql, "UPDATE \"settings\" SET \"value\" = $1")
  assert_eq(q.params, [@ast.Value::String("default")])
}

///|
test "update with multiple set and where" {
  let q = @builder.update("products")
    .set("name", @builder.val_str("Widget"))
    .set("price", @builder.val_int(999))
    .set("active", @builder.val_bool(false))
    .where_(@builder.col("id").eq(@builder.val_int(42)))
    .where_(@builder.col("version").eq(@builder.val_int(3)))
    .build()
  assert_eq(
    q.sql,
    "UPDATE \"products\" SET \"name\" = $1, \"price\" = $2, \"active\" = $3 WHERE ((\"id\" = $4) AND (\"version\" = $5))",
  )
  assert_eq(q.params, [
    @ast.Value::String("Widget"),
    @ast.Value::Int(999),
    @ast.Value::Bool(false),
    @ast.Value::Int(42),
    @ast.Value::Int(3),
  ])
}

///|
test "update set column to expression" {
  // SET "aspect" = "aspect" + 1
  let q = @builder.update("glyph")
    .set("aspect", @builder.col("aspect").add(@builder.val_int(1)))
    .where_(@builder.col("id").eq(@builder.val_int(1)))
    .build()
  assert_eq(
    q.sql,
    "UPDATE \"glyph\" SET \"aspect\" = (\"aspect\" + $1) WHERE (\"id\" = $2)",
  )
  assert_eq(q.params, [@ast.Value::Int(1), @ast.Value::Int(1)])
}

// ========================================================
// UPDATE: RETURNING
// ========================================================

///|
test "update with returning" {
  let q = @builder.update("users")
    .set("name", @builder.val_str("Updated"))
    .where_(@builder.col("id").eq(@builder.val_int(1)))
    .returning(["id", "name"])
    .build()
  assert_eq(
    q.sql,
    "UPDATE \"users\" SET \"name\" = $1 WHERE (\"id\" = $2) RETURNING \"id\", \"name\"",
  )
  assert_eq(q.params, [@ast.Value::String("Updated"), @ast.Value::Int(1)])
}

// ========================================================
// DELETE: Basic
// ========================================================

///|
test "delete basic" {
  let q = @builder.delete_from("users")
    .where_(@builder.col("id").eq(@builder.val_int(42)))
    .build()
  assert_eq(q.sql, "DELETE FROM \"users\" WHERE (\"id\" = $1)")
  assert_eq(q.params, [@ast.Value::Int(42)])
}

///|
test "delete without where" {
  let q = @builder.delete_from("temp_data").build()
  assert_eq(q.sql, "DELETE FROM \"temp_data\"")
  assert_eq(q.params, [])
}

///|
test "delete with multiple where" {
  let q = @builder.delete_from("logs")
    .where_(@builder.col("level").eq(@builder.val_str("debug")))
    .where_(@builder.col("age_days").gt(@builder.val_int(30)))
    .build()
  assert_eq(
    q.sql,
    "DELETE FROM \"logs\" WHERE ((\"level\" = $1) AND (\"age_days\" > $2))",
  )
  assert_eq(q.params, [@ast.Value::String("debug"), @ast.Value::Int(30)])
}

// ========================================================
// DELETE: RETURNING
// ========================================================

///|
test "delete with returning" {
  let q = @builder.delete_from("users")
    .where_(@builder.col("active").eq(@builder.val_bool(false)))
    .returning(["id"])
    .build()
  assert_eq(
    q.sql,
    "DELETE FROM \"users\" WHERE (\"active\" = $1) RETURNING \"id\"",
  )
  assert_eq(q.params, [@ast.Value::Bool(false)])
}

///|
test "delete with returning multiple columns" {
  let q = @builder.delete_from("glyph")
    .where_(@builder.col("id").eq(@builder.val_int(1)))
    .returning(["id", "image"])
    .build()
  assert_eq(
    q.sql,
    "DELETE FROM \"glyph\" WHERE (\"id\" = $1) RETURNING \"id\", \"image\"",
  )
  assert_eq(q.params, [@ast.Value::Int(1)])
}

// ========================================================
// Boundary/edge cases
// ========================================================

///|
test "select with empty columns defaults to star" {
  let q = @builder.select().from("users").build()
  assert_eq(q.sql, "SELECT * FROM \"users\"")
  assert_eq(q.params, [])
}

///|
test "select without from clause" {
  let q = @builder.select()
    .expr(@builder.func("COUNT", [@builder.asterisk()]))
    .build()
  assert_eq(q.sql, "SELECT COUNT(*)")
  assert_eq(q.params, [])
}

///|
test "select with in_list empty array renders FALSE" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.col("id").in_list([]))
    .build()
  assert_eq(q.sql, "SELECT * FROM \"users\" WHERE FALSE")
  assert_eq(q.params, [])
}

///|
test "select with not_in_list empty array renders TRUE" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.col("id").not_in_list([]))
    .build()
  assert_eq(q.sql, "SELECT * FROM \"users\" WHERE TRUE")
  assert_eq(q.params, [])
}

///|
test "insert with single column single value" {
  let q = @builder.insert_into("users")
    .columns(["name"])
    .values([@builder.val_str("Alice")])
    .build()
  assert_eq(q.sql, "INSERT INTO \"users\" (\"name\") VALUES ($1)")
  assert_eq(q.params, [@ast.Value::String("Alice")])
}

///|
test "update with single set" {
  let q = @builder.update("users")
    .set("active", @builder.val_bool(false))
    .where_(@builder.col("id").eq(@builder.val_int(1)))
    .build()
  assert_eq(q.sql, "UPDATE \"users\" SET \"active\" = $1 WHERE (\"id\" = $2)")
  assert_eq(q.params, [@ast.Value::Bool(false), @ast.Value::Int(1)])
}

///|
test "delete with complex where" {
  let q = @builder.delete_from("users")
    .where_(
      @builder.col("active")
      .eq(@builder.val_bool(false))
      .or_(@builder.col("banned").eq(@builder.val_bool(true))),
    )
    .build()
  assert_eq(
    q.sql,
    "DELETE FROM \"users\" WHERE ((\"active\" = $1) OR (\"banned\" = $2))",
  )
  assert_eq(q.params, [@ast.Value::Bool(false), @ast.Value::Bool(true)])
}

///|
test "select with many params ensures sequential numbering" {
  let q = @builder.insert_into("data")
    .columns(["a", "b", "c", "d", "e"])
    .values([
      @builder.val_int(1),
      @builder.val_int(2),
      @builder.val_int(3),
      @builder.val_int(4),
      @builder.val_int(5),
    ])
    .values([
      @builder.val_int(6),
      @builder.val_int(7),
      @builder.val_int(8),
      @builder.val_int(9),
      @builder.val_int(10),
    ])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"data\" (\"a\", \"b\", \"c\", \"d\", \"e\") VALUES ($1, $2, $3, $4, $5), ($6, $7, $8, $9, $10)",
  )
  assert_eq(q.params, [
    @ast.Value::Int(1),
    @ast.Value::Int(2),
    @ast.Value::Int(3),
    @ast.Value::Int(4),
    @ast.Value::Int(5),
    @ast.Value::Int(6),
    @ast.Value::Int(7),
    @ast.Value::Int(8),
    @ast.Value::Int(9),
    @ast.Value::Int(10),
  ])
}

///|
test "select distinct with where and order by" {
  let q = @builder.select()
    .distinct()
    .columns(["name", "email"])
    .from("users")
    .where_(@builder.col("active").eq(@builder.val_bool(true)))
    .order_by("name", @ast.Asc)
    .build()
  assert_eq(
    q.sql,
    "SELECT DISTINCT \"name\", \"email\" FROM \"users\" WHERE (\"active\" = $1) ORDER BY \"name\" ASC",
  )
  assert_eq(q.params, [@ast.Value::Bool(true)])
}

///|
test "select complex: join + where + group by + having + order by + limit" {
  let q = @builder.select()
    .column("department")
    .expr_as(@builder.func("COUNT", [@builder.asterisk()]), "cnt")
    .from_as("employees", "e")
    .join(
      "departments",
      @builder.table_col("e", "dept_id").eq(
        @builder.table_col("departments", "id"),
      ),
    )
    .where_(@builder.col("active").eq(@builder.val_bool(true)))
    .group_by("department")
    .having(
      @builder.func("COUNT", [@builder.asterisk()]).gt(@builder.val_int(3)),
    )
    .order_by("department", @ast.Asc)
    .limit(10)
    .build()
  assert_eq(
    q.sql,
    "SELECT \"department\", COUNT(*) AS \"cnt\" FROM \"employees\" AS \"e\" INNER JOIN \"departments\" ON (\"e\".\"dept_id\" = \"departments\".\"id\") WHERE (\"active\" = $1) GROUP BY \"department\" HAVING (COUNT(*) > $2) ORDER BY \"department\" ASC LIMIT $3",
  )
  assert_eq(q.params, [
    @ast.Value::Bool(true),
    @ast.Value::Int(3),
    @ast.Value::Int(10),
  ])
}

///|
test "select is null or combined with lt" {
  let q = @builder.select()
    .column("id")
    .from("glyph")
    .where_(
      @builder.col("aspect")
      .is_null()
      .or_(
        @builder.col("aspect")
        .is_not_null()
        .and_(@builder.col("aspect").lt(@builder.val_int(8))),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"id\" FROM \"glyph\" WHERE (\"aspect\" IS NULL OR (\"aspect\" IS NOT NULL AND (\"aspect\" < $1)))",
  )
  assert_eq(q.params, [@ast.Value::Int(8)])
}

///|
test "update with set to null" {
  let q = @builder.update("users")
    .set("deleted_at", @builder.val_null())
    .where_(@builder.col("id").eq(@builder.val_int(1)))
    .build()
  assert_eq(
    q.sql,
    "UPDATE \"users\" SET \"deleted_at\" = $1 WHERE (\"id\" = $2)",
  )
  assert_eq(q.params, [@ast.Value::Null, @ast.Value::Int(1)])
}

///|
test "insert three rows" {
  let q = @builder.insert_into("items")
    .columns(["name", "price"])
    .values([@builder.val_str("A"), @builder.val_int(10)])
    .values([@builder.val_str("B"), @builder.val_int(20)])
    .values([@builder.val_str("C"), @builder.val_int(30)])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"items\" (\"name\", \"price\") VALUES ($1, $2), ($3, $4), ($5, $6)",
  )
  assert_eq(q.params, [
    @ast.Value::String("A"),
    @ast.Value::Int(10),
    @ast.Value::String("B"),
    @ast.Value::Int(20),
    @ast.Value::String("C"),
    @ast.Value::Int(30),
  ])
}

///|
test "select with not in and between combined" {
  let q = @builder.select()
    .all()
    .from("products")
    .where_(
      @builder.col("category").not_in_list([
        @builder.val_str("hidden"),
        @builder.val_str("draft"),
      ]),
    )
    .where_(
      @builder.col("price").between(@builder.val_int(10), @builder.val_int(100)),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"products\" WHERE (\"category\" NOT IN ($1, $2) AND \"price\" BETWEEN $3 AND $4)",
  )
  assert_eq(q.params, [
    @ast.Value::String("hidden"),
    @ast.Value::String("draft"),
    @ast.Value::Int(10),
    @ast.Value::Int(100),
  ])
}

///|
test "select with single in_list item" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.col("id").in_list([@builder.val_int(42)]))
    .build()
  assert_eq(q.sql, "SELECT * FROM \"users\" WHERE \"id\" IN ($1)")
  assert_eq(q.params, [@ast.Value::Int(42)])
}

// ========================================================
// Identifier escaping
// ========================================================

///|
test "identifier with double quote is escaped" {
  let q = @builder.select().column("col\"name").from("my\"table").build()
  assert_eq(q.sql, "SELECT \"col\"\"name\" FROM \"my\"\"table\"")
}

// ========================================================
// Function name validation
// ========================================================

///|
test "function name with valid characters" {
  let q = @builder.select()
    .expr(@builder.func("COUNT", [@builder.asterisk()]))
    .from("t")
    .build()
  assert_eq(q.sql, "SELECT COUNT(*) FROM \"t\"")
}

///|
test "function name with dot for schema qualified" {
  let q = @builder.select()
    .expr(@builder.func("pg_catalog.array_agg", [@builder.col("x")]))
    .from("t")
    .build()
  assert_eq(q.sql, "SELECT pg_catalog.array_agg(\"x\") FROM \"t\"")
}

// ========================================================
// JOIN with alias
// ========================================================

///|
test "join with alias" {
  let q = @builder.select()
    .all()
    .from_as("users", "u")
    .join_as(
      "orders",
      "o",
      @builder.table_col("u", "id").eq(@builder.table_col("o", "user_id")),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" AS \"u\" INNER JOIN \"orders\" AS \"o\" ON (\"u\".\"id\" = \"o\".\"user_id\")",
  )
}

///|
test "left join with alias" {
  let q = @builder.select()
    .all()
    .from_as("users", "u")
    .left_join_as(
      "profiles",
      "p",
      @builder.table_col("u", "id").eq(@builder.table_col("p", "user_id")),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" AS \"u\" LEFT JOIN \"profiles\" AS \"p\" ON (\"u\".\"id\" = \"p\".\"user_id\")",
  )
}

///|
test "right join with alias" {
  let q = @builder.select()
    .all()
    .from_as("users", "u")
    .right_join_as(
      "orders",
      "o",
      @builder.table_col("u", "id").eq(@builder.table_col("o", "user_id")),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" AS \"u\" RIGHT JOIN \"orders\" AS \"o\" ON (\"u\".\"id\" = \"o\".\"user_id\")",
  )
}

///|
test "full join with alias" {
  let q = @builder.select()
    .all()
    .from("a")
    .full_join_as(
      "b",
      "bb",
      @builder.table_col("a", "id").eq(@builder.table_col("bb", "a_id")),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"a\" FULL JOIN \"b\" AS \"bb\" ON (\"a\".\"id\" = \"bb\".\"a_id\")",
  )
}

///|
test "cross join with alias" {
  let q = @builder.select()
    .all()
    .from("colors")
    .cross_join_as("sizes", "s")
    .build()
  assert_eq(q.sql, "SELECT * FROM \"colors\" CROSS JOIN \"sizes\" AS \"s\"")
}

// ========================================================
// Subquery: FROM subquery
// ========================================================

///|
test "select from subquery" {
  let sub = @builder.select()
    .columns(["id"])
    .from("users")
    .where_(@builder.col("active").eq(@builder.val_bool(true)))
  let q = @builder.select().all().from_sub(sub, "sub").build()
  assert_eq(
    q.sql,
    "SELECT * FROM (SELECT \"id\" FROM \"users\" WHERE (\"active\" = $1)) AS \"sub\"",
  )
  assert_eq(q.params, [@ast.Value::Bool(true)])
}

///|
test "select from subquery with where" {
  let sub = @builder.select().columns(["id", "name"]).from("users")
  let q = @builder.select()
    .all()
    .from_sub(sub, "u")
    .where_(@builder.col("id").gt(@builder.val_int(10)))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM (SELECT \"id\", \"name\" FROM \"users\") AS \"u\" WHERE (\"id\" > $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(10)])
}

///|
test "select from subquery with join" {
  let sub = @builder.select()
    .columns(["user_id", "total"])
    .from("orders")
    .where_(@builder.col("total").gt(@builder.val_int(100)))
  let q = @builder.select()
    .all()
    .from_sub(sub, "o")
    .join(
      "users",
      @builder.table_col("o", "user_id").eq(@builder.table_col("users", "id")),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM (SELECT \"user_id\", \"total\" FROM \"orders\" WHERE (\"total\" > $1)) AS \"o\" INNER JOIN \"users\" ON (\"o\".\"user_id\" = \"users\".\"id\")",
  )
  assert_eq(q.params, [@ast.Value::Int(100)])
}

// ========================================================
// Subquery: IN subquery
// ========================================================

///|
test "select with in subquery" {
  let sub = @builder.select()
    .column("id")
    .from("users")
    .where_(@builder.col("active").eq(@builder.val_bool(true)))
  let q = @builder.select()
    .all()
    .from("orders")
    .where_(@builder.in_sub(@builder.col("user_id"), sub))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"orders\" WHERE \"user_id\" IN (SELECT \"id\" FROM \"users\" WHERE (\"active\" = $1))",
  )
  assert_eq(q.params, [@ast.Value::Bool(true)])
}

///|
test "select with not in subquery" {
  let sub = @builder.select().column("id").from("banned_users")
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.not_in_sub(@builder.col("id"), sub))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE \"id\" NOT IN (SELECT \"id\" FROM \"banned_users\")",
  )
  assert_eq(q.params, [])
}

///|
test "select with in subquery and other conditions" {
  let sub = @builder.select()
    .column("user_id")
    .from("orders")
    .where_(@builder.col("total").gt(@builder.val_int(1000)))
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.in_sub(@builder.col("id"), sub))
    .where_(@builder.col("active").eq(@builder.val_bool(true)))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE (\"id\" IN (SELECT \"user_id\" FROM \"orders\" WHERE (\"total\" > $1)) AND (\"active\" = $2))",
  )
  assert_eq(q.params, [@ast.Value::Int(1000), @ast.Value::Bool(true)])
}

// ========================================================
// CTE (WITH)
// ========================================================

///|
test "select with CTE" {
  let cte = @builder.select()
    .columns(["id", "name"])
    .from("users")
    .where_(@builder.col("active").eq(@builder.val_bool(true)))
  let q = @builder.select()
    .with_("active_users", cte)
    .all()
    .from("active_users")
    .build()
  assert_eq(
    q.sql,
    "WITH \"active_users\" AS (SELECT \"id\", \"name\" FROM \"users\" WHERE (\"active\" = $1)) SELECT * FROM \"active_users\"",
  )
  assert_eq(q.params, [@ast.Value::Bool(true)])
}

///|
test "select with multiple CTEs" {
  let cte1 = @builder.select()
    .columns(["id", "name"])
    .from("users")
    .where_(@builder.col("active").eq(@builder.val_bool(true)))
  let cte2 = @builder.select()
    .columns(["user_id", "total"])
    .from("orders")
    .where_(@builder.col("total").gt(@builder.val_int(100)))
  let q = @builder.select()
    .with_("active_users", cte1)
    .with_("big_orders", cte2)
    .all()
    .from("active_users")
    .join(
      "big_orders",
      @builder.table_col("active_users", "id").eq(
        @builder.table_col("big_orders", "user_id"),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "WITH \"active_users\" AS (SELECT \"id\", \"name\" FROM \"users\" WHERE (\"active\" = $1)), \"big_orders\" AS (SELECT \"user_id\", \"total\" FROM \"orders\" WHERE (\"total\" > $2)) SELECT * FROM \"active_users\" INNER JOIN \"big_orders\" ON (\"active_users\".\"id\" = \"big_orders\".\"user_id\")",
  )
  assert_eq(q.params, [@ast.Value::Bool(true), @ast.Value::Int(100)])
}

///|
test "select with CTE and where" {
  let cte = @builder.select().column("id").from("users")
  let q = @builder.select()
    .with_("all_ids", cte)
    .all()
    .from("all_ids")
    .where_(@builder.col("id").gt(@builder.val_int(5)))
    .build()
  assert_eq(
    q.sql,
    "WITH \"all_ids\" AS (SELECT \"id\" FROM \"users\") SELECT * FROM \"all_ids\" WHERE (\"id\" > $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(5)])
}

// ========================================================
// UNION / INTERSECT / EXCEPT
// ========================================================

///|
test "select union" {
  let q = @builder.select()
    .all()
    .from("table_a")
    .union(@builder.select().all().from("table_b"))
    .build()
  assert_eq(q.sql, "SELECT * FROM \"table_a\" UNION SELECT * FROM \"table_b\"")
  assert_eq(q.params, [])
}

///|
test "select union all" {
  let q = @builder.select()
    .all()
    .from("table_a")
    .union_all(@builder.select().all().from("table_b"))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"table_a\" UNION ALL SELECT * FROM \"table_b\"",
  )
  assert_eq(q.params, [])
}

///|
test "select intersect" {
  let q = @builder.select()
    .all()
    .from("table_a")
    .intersect(@builder.select().all().from("table_b"))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"table_a\" INTERSECT SELECT * FROM \"table_b\"",
  )
  assert_eq(q.params, [])
}

///|
test "select intersect all" {
  let q = @builder.select()
    .all()
    .from("table_a")
    .intersect_all(@builder.select().all().from("table_b"))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"table_a\" INTERSECT ALL SELECT * FROM \"table_b\"",
  )
  assert_eq(q.params, [])
}

///|
test "select except" {
  let q = @builder.select()
    .all()
    .from("table_a")
    .except_(@builder.select().all().from("table_b"))
    .build()
  assert_eq(q.sql, "SELECT * FROM \"table_a\" EXCEPT SELECT * FROM \"table_b\"")
  assert_eq(q.params, [])
}

///|
test "select except all" {
  let q = @builder.select()
    .all()
    .from("table_a")
    .except_all(@builder.select().all().from("table_b"))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"table_a\" EXCEPT ALL SELECT * FROM \"table_b\"",
  )
  assert_eq(q.params, [])
}

///|
test "select union with params" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.col("role").eq(@builder.val_str("admin")))
    .union(
      @builder.select()
      .all()
      .from("users")
      .where_(@builder.col("role").eq(@builder.val_str("mod"))),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE (\"role\" = $1) UNION SELECT * FROM \"users\" WHERE (\"role\" = $2)",
  )
  assert_eq(q.params, [@ast.Value::String("admin"), @ast.Value::String("mod")])
}

///|
test "select union with order by and limit" {
  let q = @builder.select()
    .all()
    .from("table_a")
    .union(@builder.select().all().from("table_b"))
    .order_by("id", @ast.Asc)
    .limit(10)
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"table_a\" UNION SELECT * FROM \"table_b\" ORDER BY \"id\" ASC LIMIT $1",
  )
  assert_eq(q.params, [@ast.Value::Int(10)])
}

///|
test "select multiple unions" {
  let q = @builder.select()
    .all()
    .from("table_a")
    .union(@builder.select().all().from("table_b"))
    .union(@builder.select().all().from("table_c"))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"table_a\" UNION SELECT * FROM \"table_b\" UNION SELECT * FROM \"table_c\"",
  )
  assert_eq(q.params, [])
}

// ========================================================
// Upsert (INSERT ON CONFLICT)
// ========================================================

///|
test "insert on conflict do nothing" {
  let q = @builder.insert_into("users")
    .columns(["id", "name"])
    .values([@builder.val_int(1), @builder.val_str("Alice")])
    .on_conflict_do_nothing(["id"])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"users\" (\"id\", \"name\") VALUES ($1, $2) ON CONFLICT (\"id\") DO NOTHING",
  )
  assert_eq(q.params, [@ast.Value::Int(1), @ast.Value::String("Alice")])
}

///|
test "insert on conflict do update" {
  let q = @builder.insert_into("users")
    .columns(["id", "name", "email"])
    .values([
      @builder.val_int(1),
      @builder.val_str("Alice"),
      @builder.val_str("alice@example.com"),
    ])
    .on_conflict_do_update(["id"], [
      ("name", @builder.table_col("excluded", "name")),
      ("email", @builder.table_col("excluded", "email")),
    ])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"users\" (\"id\", \"name\", \"email\") VALUES ($1, $2, $3) ON CONFLICT (\"id\") DO UPDATE SET \"name\" = \"excluded\".\"name\", \"email\" = \"excluded\".\"email\"",
  )
  assert_eq(q.params, [
    @ast.Value::Int(1),
    @ast.Value::String("Alice"),
    @ast.Value::String("alice@example.com"),
  ])
}

///|
test "insert on conflict do update with value" {
  let q = @builder.insert_into("counters")
    .columns(["key", "value"])
    .values([@builder.val_str("hits"), @builder.val_int(1)])
    .on_conflict_do_update(["key"], [
      (
        "value",
        @builder.table_col("counters", "value").add(@builder.val_int(1)),
      ),
    ])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"counters\" (\"key\", \"value\") VALUES ($1, $2) ON CONFLICT (\"key\") DO UPDATE SET \"value\" = (\"counters\".\"value\" + $3)",
  )
  assert_eq(q.params, [
    @ast.Value::String("hits"),
    @ast.Value::Int(1),
    @ast.Value::Int(1),
  ])
}

///|
test "insert on conflict multiple columns" {
  let q = @builder.insert_into("user_roles")
    .columns(["user_id", "role_id", "granted_at"])
    .values([
      @builder.val_int(1),
      @builder.val_int(2),
      @builder.val_str("2024-01-01"),
    ])
    .on_conflict_do_nothing(["user_id", "role_id"])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"user_roles\" (\"user_id\", \"role_id\", \"granted_at\") VALUES ($1, $2, $3) ON CONFLICT (\"user_id\", \"role_id\") DO NOTHING",
  )
  assert_eq(q.params, [
    @ast.Value::Int(1),
    @ast.Value::Int(2),
    @ast.Value::String("2024-01-01"),
  ])
}

///|
test "insert on conflict do update with returning" {
  let q = @builder.insert_into("users")
    .columns(["id", "name"])
    .values([@builder.val_int(1), @builder.val_str("Alice")])
    .on_conflict_do_update(["id"], [
      ("name", @builder.table_col("excluded", "name")),
    ])
    .returning(["id", "name"])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"users\" (\"id\", \"name\") VALUES ($1, $2) ON CONFLICT (\"id\") DO UPDATE SET \"name\" = \"excluded\".\"name\" RETURNING \"id\", \"name\"",
  )
  assert_eq(q.params, [@ast.Value::Int(1), @ast.Value::String("Alice")])
}

// ========================================================
// Window Functions
// ========================================================

///|
test "select with row_number window function" {
  let q = @builder.select()
    .expr_as(
      @builder.window_func("ROW_NUMBER", [], partition_by=["dept"], order_by=[
        ("salary", @ast.Desc),
      ]),
      "rank",
    )
    .from("employees")
    .build()
  assert_eq(
    q.sql,
    "SELECT ROW_NUMBER() OVER (PARTITION BY \"dept\" ORDER BY \"salary\" DESC) AS \"rank\" FROM \"employees\"",
  )
  assert_eq(q.params, [])
}

///|
test "select with rank window function" {
  let q = @builder.select()
    .column("name")
    .expr_as(
      @builder.window_func("RANK", [], order_by=[("score", @ast.Desc)]),
      "rank",
    )
    .from("players")
    .build()
  assert_eq(
    q.sql,
    "SELECT \"name\", RANK() OVER (ORDER BY \"score\" DESC) AS \"rank\" FROM \"players\"",
  )
  assert_eq(q.params, [])
}

///|
test "select with sum window function" {
  let q = @builder.select()
    .column("month")
    .column("revenue")
    .expr_as(
      @builder.window_func(
        "SUM",
        [@builder.col("revenue")],
        partition_by=["year"],
        order_by=[("month", @ast.Asc)],
      ),
      "running_total",
    )
    .from("sales")
    .build()
  assert_eq(
    q.sql,
    "SELECT \"month\", \"revenue\", SUM(\"revenue\") OVER (PARTITION BY \"year\" ORDER BY \"month\" ASC) AS \"running_total\" FROM \"sales\"",
  )
  assert_eq(q.params, [])
}

///|
test "select with window function partition only" {
  let q = @builder.select()
    .expr_as(
      @builder.window_func("COUNT", [@builder.asterisk()], partition_by=["dept"]),
      "dept_count",
    )
    .from("employees")
    .build()
  assert_eq(
    q.sql,
    "SELECT COUNT(*) OVER (PARTITION BY \"dept\") AS \"dept_count\" FROM \"employees\"",
  )
  assert_eq(q.params, [])
}

///|
test "select with window function order only" {
  let q = @builder.select()
    .expr_as(
      @builder.window_func("ROW_NUMBER", [], order_by=[("id", @ast.Asc)]),
      "row_num",
    )
    .from("users")
    .build()
  assert_eq(
    q.sql,
    "SELECT ROW_NUMBER() OVER (ORDER BY \"id\" ASC) AS \"row_num\" FROM \"users\"",
  )
  assert_eq(q.params, [])
}

///|
test "select with window function multiple partition and order" {
  let q = @builder.select()
    .expr_as(
      @builder.window_func("ROW_NUMBER", [], partition_by=["dept", "team"], order_by=[
        ("salary", @ast.Desc),
        ("name", @ast.Asc),
      ]),
      "rank",
    )
    .from("employees")
    .build()
  assert_eq(
    q.sql,
    "SELECT ROW_NUMBER() OVER (PARTITION BY \"dept\", \"team\" ORDER BY \"salary\" DESC, \"name\" ASC) AS \"rank\" FROM \"employees\"",
  )
  assert_eq(q.params, [])
}

// ========================================================
// Combined: CTE with UNION
// ========================================================

///|
test "CTE with union inside" {
  let cte_query = @builder.select()
    .column("id")
    .from("active_users")
    .union(@builder.select().column("id").from("premium_users"))
  let q = @builder.select()
    .with_("all_special_users", cte_query)
    .all()
    .from("all_special_users")
    .build()
  assert_eq(
    q.sql,
    "WITH \"all_special_users\" AS (SELECT \"id\" FROM \"active_users\" UNION SELECT \"id\" FROM \"premium_users\") SELECT * FROM \"all_special_users\"",
  )
  assert_eq(q.params, [])
}

// ========================================================
// Combined: Subquery in WHERE with UNION
// ========================================================

///|
test "subquery with params in nested context" {
  let sub = @builder.select()
    .column("id")
    .from("users")
    .where_(@builder.col("age").gt(@builder.val_int(18)))
  let q = @builder.select()
    .all()
    .from("orders")
    .where_(@builder.in_sub(@builder.col("user_id"), sub))
    .where_(@builder.col("total").gt(@builder.val_int(50)))
    .order_by("total", @ast.Desc)
    .limit(10)
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"orders\" WHERE (\"user_id\" IN (SELECT \"id\" FROM \"users\" WHERE (\"age\" > $1)) AND (\"total\" > $2)) ORDER BY \"total\" DESC LIMIT $3",
  )
  assert_eq(q.params, [
    @ast.Value::Int(18),
    @ast.Value::Int(50),
    @ast.Value::Int(10),
  ])
}

// ========================================================
// BuildError: raise テスト
// ========================================================

///|
test "insert empty values raises EmptyValues" {
  let result = Result::Ok(
    @builder.insert_into("users").columns(["name"]).build(),
  ) catch {
    err => Err(err)
  }
  match result {
    Err(@builder.BuildError::EmptyValues(_)) => ()
    _ => fail("expected EmptyValues")
  }
}

///|
test "update empty assignments raises EmptyAssignments" {
  let result = Result::Ok(
    @builder.update("users")
    .where_(@builder.col("id").eq(@builder.val_int(1)))
    .build(),
  ) catch {
    err => Err(err)
  }
  match result {
    Err(@builder.BuildError::EmptyAssignments(_)) => ()
    _ => fail("expected EmptyAssignments")
  }
}

///|
test "on_conflict_do_nothing empty columns raises EmptyConflictColumns" {
  let result = Result::Ok(
    @builder.insert_into("users")
    .columns(["name"])
    .values([@builder.val_str("Alice")])
    .on_conflict_do_nothing([])
    .build(),
  ) catch {
    err => Err(err)
  }
  match result {
    Err(@builder.BuildError::EmptyConflictColumns(_)) => ()
    _ => fail("expected EmptyConflictColumns")
  }
}

///|
test "on_conflict_do_update empty columns raises EmptyConflictColumns" {
  let result = Result::Ok(
    @builder.insert_into("users")
    .columns(["name"])
    .values([@builder.val_str("Alice")])
    .on_conflict_do_update([], [
      ("name", @builder.table_col("excluded", "name")),
    ])
    .build(),
  ) catch {
    err => Err(err)
  }
  match result {
    Err(@builder.BuildError::EmptyConflictColumns(_)) => ()
    _ => fail("expected EmptyConflictColumns")
  }
}

///|
test "func invalid name raises InvalidFuncName" {
  let result = Result::Ok(@builder.func("COUNT(*)", [])) catch {
    err => Err(err)
  }
  match result {
    Err(@builder.BuildError::InvalidFuncName(_)) => ()
    _ => fail("expected InvalidFuncName")
  }
}

///|
test "window_func invalid name raises InvalidFuncName" {
  let result = Result::Ok(@builder.window_func("ROW; DROP TABLE--", [])) catch {
    err => Err(err)
  }
  match result {
    Err(@builder.BuildError::InvalidFuncName(_)) => ()
    _ => fail("expected InvalidFuncName")
  }
}

// ========================================================
// HAVING: AND 結合テスト
// ========================================================

///|
test "having with multiple conditions AND-combined" {
  let q = @builder.select()
    .column("dept")
    .expr_as(@builder.func("COUNT", [@builder.asterisk()]), "cnt")
    .from("employees")
    .group_by("dept")
    .having(
      @builder.func("COUNT", [@builder.asterisk()]).gt(@builder.val_int(5)),
    )
    .having(
      @builder.func("COUNT", [@builder.asterisk()]).lt(@builder.val_int(100)),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"dept\", COUNT(*) AS \"cnt\" FROM \"employees\" GROUP BY \"dept\" HAVING ((COUNT(*) > $1) AND (COUNT(*) < $2))",
  )
  assert_eq(q.params, [@ast.Value::Int(5), @ast.Value::Int(100)])
}

// ========================================================
// 算術ヘルパー: add, sub_, mul, div, not_, neg
// ========================================================

///|
test "arithmetic helper: add" {
  let q = @builder.select()
    .expr_as(@builder.col("price").add(@builder.col("tax")), "total")
    .from("items")
    .build()
  assert_eq(q.sql, "SELECT (\"price\" + \"tax\") AS \"total\" FROM \"items\"")
  assert_eq(q.params, [])
}

///|
test "arithmetic helper: sub_" {
  let q = @builder.select()
    .expr_as(@builder.col("price").sub_(@builder.col("discount")), "net")
    .from("items")
    .build()
  assert_eq(
    q.sql,
    "SELECT (\"price\" - \"discount\") AS \"net\" FROM \"items\"",
  )
  assert_eq(q.params, [])
}

///|
test "arithmetic helper: mul" {
  let q = @builder.select()
    .expr_as(@builder.col("price").mul(@builder.col("quantity")), "total")
    .from("order_items")
    .build()
  assert_eq(
    q.sql,
    "SELECT (\"price\" * \"quantity\") AS \"total\" FROM \"order_items\"",
  )
  assert_eq(q.params, [])
}

///|
test "arithmetic helper: div" {
  let q = @builder.select()
    .expr_as(@builder.col("total").div(@builder.col("count")), "average")
    .from("stats")
    .build()
  assert_eq(
    q.sql,
    "SELECT (\"total\" / \"count\") AS \"average\" FROM \"stats\"",
  )
  assert_eq(q.params, [])
}

///|
test "arithmetic helper: not_" {
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.col("active").eq(@builder.val_bool(true)).not_())
    .build()
  assert_eq(q.sql, "SELECT * FROM \"users\" WHERE (NOT (\"active\" = $1))")
  assert_eq(q.params, [@ast.Value::Bool(true)])
}

///|
test "arithmetic helper: neg" {
  let q = @builder.select()
    .expr(@builder.col("balance").neg())
    .from("accounts")
    .build()
  assert_eq(q.sql, "SELECT (-\"balance\") FROM \"accounts\"")
  assert_eq(q.params, [])
}

///|
test "arithmetic helpers: combined expression" {
  let q = @builder.select()
    .columns(["character", "size_w", "size_h"])
    .from("character")
    .where_(
      @builder.col("size_w")
      .mul(@builder.val_int(2))
      .add(@builder.col("size_h").div(@builder.val_int(3)))
      .eq(@builder.val_int(4)),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\", \"size_w\", \"size_h\" FROM \"character\" WHERE (((\"size_w\" * $1) + (\"size_h\" / $2)) = $3)",
  )
  assert_eq(q.params, [
    @ast.Value::Int(2),
    @ast.Value::Int(3),
    @ast.Value::Int(4),
  ])
}

// ========================================================
// in_sub / not_in_sub ヘルパー
// ========================================================

///|
test "in_sub helper" {
  let sub = @builder.select().column("id").from("active_users")
  let q = @builder.select()
    .all()
    .from("orders")
    .where_(@builder.in_sub(@builder.col("user_id"), sub))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"orders\" WHERE \"user_id\" IN (SELECT \"id\" FROM \"active_users\")",
  )
  assert_eq(q.params, [])
}

///|
test "not_in_sub helper" {
  let sub = @builder.select().column("id").from("banned_users")
  let q = @builder.select()
    .all()
    .from("orders")
    .where_(@builder.not_in_sub(@builder.col("user_id"), sub))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"orders\" WHERE \"user_id\" NOT IN (SELECT \"id\" FROM \"banned_users\")",
  )
  assert_eq(q.params, [])
}

// ========================================================
// CASE WHEN
// ========================================================

///|
test "case when single condition" {
  let q = @builder.select()
    .expr(
      @builder.case_()
      .when_(
        @builder.col("status").eq(@builder.val_str("active")),
        @builder.val_str("Active"),
      )
      .end(),
    )
    .from("users")
    .build()
  assert_eq(
    q.sql,
    "SELECT CASE WHEN (\"status\" = $1) THEN $2 END FROM \"users\"",
  )
  assert_eq(q.params, [
    @ast.Value::String("active"),
    @ast.Value::String("Active"),
  ])
}

///|
test "case when two conditions with else" {
  let q = @builder.select()
    .expr_as(
      @builder.case_()
      .when_(
        @builder.col("score").gte(@builder.val_int(90)),
        @builder.val_str("A"),
      )
      .when_(
        @builder.col("score").gte(@builder.val_int(70)),
        @builder.val_str("B"),
      )
      .else_(@builder.val_str("C"))
      .end(),
      "grade",
    )
    .from("students")
    .build()
  assert_eq(
    q.sql,
    "SELECT CASE WHEN (\"score\" >= $1) THEN $2 WHEN (\"score\" >= $3) THEN $4 ELSE $5 END AS \"grade\" FROM \"students\"",
  )
  assert_eq(q.params, [
    @ast.Value::Int(90),
    @ast.Value::String("A"),
    @ast.Value::Int(70),
    @ast.Value::String("B"),
    @ast.Value::String("C"),
  ])
}

///|
test "case when without else" {
  let q = @builder.select()
    .expr(
      @builder.case_()
      .when_(
        @builder.col("active").eq(@builder.val_bool(true)),
        @builder.val_str("yes"),
      )
      .end(),
    )
    .from("users")
    .build()
  assert_eq(
    q.sql,
    "SELECT CASE WHEN (\"active\" = $1) THEN $2 END FROM \"users\"",
  )
  assert_eq(q.params, [@ast.Value::Bool(true), @ast.Value::String("yes")])
}

///|
test "case when used in where clause" {
  let q = @builder.select()
    .all()
    .from("orders")
    .where_(
      @builder.case_()
      .when_(
        @builder.col("total").gt(@builder.val_int(1000)),
        @builder.val_str("large"),
      )
      .else_(@builder.val_str("small"))
      .end()
      .eq(@builder.val_str("large")),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"orders\" WHERE (CASE WHEN (\"total\" > $1) THEN $2 ELSE $3 END = $4)",
  )
  assert_eq(q.params, [
    @ast.Value::Int(1000),
    @ast.Value::String("large"),
    @ast.Value::String("small"),
    @ast.Value::String("large"),
  ])
}

///|
test "case when select expr with alias" {
  let q = @builder.select()
    .column("name")
    .expr_as(
      @builder.case_()
      .when_(
        @builder.col("role").eq(@builder.val_str("admin")),
        @builder.val_int(1),
      )
      .when_(
        @builder.col("role").eq(@builder.val_str("mod")),
        @builder.val_int(2),
      )
      .else_(@builder.val_int(0))
      .end(),
      "role_level",
    )
    .from("users")
    .build()
  assert_eq(
    q.sql,
    "SELECT \"name\", CASE WHEN (\"role\" = $1) THEN $2 WHEN (\"role\" = $3) THEN $4 ELSE $5 END AS \"role_level\" FROM \"users\"",
  )
  assert_eq(q.params, [
    @ast.Value::String("admin"),
    @ast.Value::Int(1),
    @ast.Value::String("mod"),
    @ast.Value::Int(2),
    @ast.Value::Int(0),
  ])
}

///|
test "case end with no when clauses raises EmptyWhenClauses" {
  let result = Result::Ok(@builder.case_().end()) catch { err => Err(err) }
  match result {
    Err(@builder.BuildError::EmptyWhenClauses(_)) => ()
    _ => fail("expected EmptyWhenClauses")
  }
}

// ========================================================
// EXISTS / NOT EXISTS
// ========================================================

///|
test "exists basic" {
  let sub = @builder.select()
    .column("id")
    .from("orders")
    .where_(@builder.col("user_id").eq(@builder.val_int(1)))
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.exists_(sub))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE EXISTS (SELECT \"id\" FROM \"orders\" WHERE (\"user_id\" = $1))",
  )
  assert_eq(q.params, [@ast.Value::Int(1)])
}

///|
test "not exists basic" {
  let sub = @builder.select().column("id").from("banned_users")
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.not_exists(sub))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE NOT EXISTS (SELECT \"id\" FROM \"banned_users\")",
  )
  assert_eq(q.params, [])
}

///|
test "exists in where correlated style" {
  let sub = @builder.select()
    .column("id")
    .from("orders")
    .where_(
      @builder.table_col("orders", "user_id").eq(
        @builder.table_col("users", "id"),
      ),
    )
    .where_(@builder.col("total").gt(@builder.val_int(500)))
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.exists_(sub))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE EXISTS (SELECT \"id\" FROM \"orders\" WHERE ((\"orders\".\"user_id\" = \"users\".\"id\") AND (\"total\" > $1)))",
  )
  assert_eq(q.params, [@ast.Value::Int(500)])
}

///|
test "exists combined with and condition" {
  let sub = @builder.select()
    .column("id")
    .from("subscriptions")
    .where_(@builder.col("active").eq(@builder.val_bool(true)))
  let q = @builder.select()
    .all()
    .from("users")
    .where_(@builder.col("age").gte(@builder.val_int(18)))
    .where_(@builder.exists_(sub))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE ((\"age\" >= $1) AND EXISTS (SELECT \"id\" FROM \"subscriptions\" WHERE (\"active\" = $2)))",
  )
  assert_eq(q.params, [@ast.Value::Int(18), @ast.Value::Bool(true)])
}

// ========================================================
// INSERT INTO ... SELECT
// ========================================================

///|
test "insert from select basic" {
  let sub = @builder.select().columns(["name", "email"]).from("old_users")
  let q = @builder.insert_into("users")
    .columns(["name", "email"])
    .from_select(sub)
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"users\" (\"name\", \"email\") SELECT \"name\", \"email\" FROM \"old_users\"",
  )
  assert_eq(q.params, [])
}

///|
test "insert from select with columns" {
  let sub = @builder.select()
    .columns(["username", "email"])
    .from("staging")
    .where_(@builder.col("verified").eq(@builder.val_bool(true)))
  let q = @builder.insert_into("users")
    .columns(["name", "email"])
    .from_select(sub)
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"users\" (\"name\", \"email\") SELECT \"username\", \"email\" FROM \"staging\" WHERE (\"verified\" = $1)",
  )
  assert_eq(q.params, [@ast.Value::Bool(true)])
}

///|
test "insert from select with returning" {
  let sub = @builder.select().columns(["name", "email"]).from("temp_users")
  let q = @builder.insert_into("users")
    .columns(["name", "email"])
    .from_select(sub)
    .returning(["id"])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"users\" (\"name\", \"email\") SELECT \"name\", \"email\" FROM \"temp_users\" RETURNING \"id\"",
  )
  assert_eq(q.params, [])
}

///|
test "insert from select with where in sub" {
  let sub = @builder.select()
    .columns(["name", "score"])
    .from("candidates")
    .where_(@builder.col("score").gt(@builder.val_int(80)))
  let q = @builder.insert_into("winners")
    .columns(["name", "score"])
    .from_select(sub)
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"winners\" (\"name\", \"score\") SELECT \"name\", \"score\" FROM \"candidates\" WHERE (\"score\" > $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(80)])
}

///|
test "insert values and select both set raises ConflictingInsertSource" {
  let result = try {
    let sub = @builder.select().all().from("other")
    Result::Ok(
      @builder.insert_into("users")
      .columns(["name"])
      .values([@builder.val_str("Alice")])
      .from_select(sub)
      .build(),
    )
  } catch {
    err => Err(err)
  }
  match result {
    Err(@builder.BuildError::ConflictingInsertSource(_)) => ()
    _ => fail("expected ConflictingInsertSource")
  }
}

// ========================================================
// @builder.raw(): verbatim SQL injection
// ========================================================

///|
test "raw in SELECT expr" {
  let q = @builder.select()
    .expr_as(@builder.raw("current_timestamp"), "ts")
    .from("events")
    .build()
  assert_eq(q.sql, "SELECT current_timestamp AS \"ts\" FROM \"events\"")
  assert_eq(q.params, [])
}

///|
test "raw in WHERE clause" {
  let q = @builder.select()
    .column("id")
    .from("sessions")
    .where_(@builder.raw("expires_at > now()"))
    .build()
  assert_eq(q.sql, "SELECT \"id\" FROM \"sessions\" WHERE expires_at > now()")
  assert_eq(q.params, [])
}

///|
test "raw combined with typed expr" {
  let q = @builder.select()
    .column("id")
    .from("logs")
    .where_(
      @builder.col("level")
      .eq(@builder.val_str("error"))
      .and_(@builder.raw("created_at > now() - interval '7 days'")),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"id\" FROM \"logs\" WHERE ((\"level\" = $1) AND created_at > now() - interval '7 days')",
  )
  assert_eq(q.params, [@ast.Value::String("error")])
}

///|
test "raw in GROUP BY via group_by_expr" {
  let q = @builder.select()
    .expr_as(@builder.raw("date_trunc('month', created_at)"), "month")
    .expr_as(@builder.func("COUNT", [@builder.asterisk()]), "cnt")
    .from("events")
    .group_by_expr(@builder.raw("date_trunc('month', created_at)"))
    .build()
  assert_eq(
    q.sql,
    "SELECT date_trunc('month', created_at) AS \"month\", COUNT(*) AS \"cnt\" FROM \"events\" GROUP BY date_trunc('month', created_at)",
  )
  assert_eq(q.params, [])
}
