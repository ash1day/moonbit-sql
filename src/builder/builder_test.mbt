// ========================================================
// SELECT: Basic queries
// ========================================================

test "select all columns" {
  let q = select().all().from("users").build()
  assert_eq(q.sql, "SELECT * FROM \"users\"")
  assert_eq(q.params, [])
}

test "select with named columns" {
  let q = select().columns(["id", "name", "email"]).from("users").build()
  assert_eq(q.sql, "SELECT \"id\", \"name\", \"email\" FROM \"users\"")
  assert_eq(q.params, [])
}

test "select single column" {
  let q = select().column("id").from("users").build()
  assert_eq(q.sql, "SELECT \"id\" FROM \"users\"")
  assert_eq(q.params, [])
}

test "select with limit and offset" {
  let q = select()
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

test "select with limit only" {
  let q = select().all().from("users").limit(5).build()
  assert_eq(q.sql, "SELECT * FROM \"users\" LIMIT $1")
  assert_eq(q.params, [@ast.Value::Int(5)])
}

// ========================================================
// SELECT: DISTINCT
// ========================================================

test "select distinct" {
  let q = select().distinct().columns(["name"]).from("users").build()
  assert_eq(q.sql, "SELECT DISTINCT \"name\" FROM \"users\"")
  assert_eq(q.params, [])
}

test "select distinct with multiple columns" {
  let q = select()
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

test "select with where eq" {
  let q = select()
    .columns(["character", "size_w", "size_h"])
    .from("character")
    .where_(col("size_w").eq(val_int(3)))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\", \"size_w\", \"size_h\" FROM \"character\" WHERE (\"size_w\" = $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(3)])
}

test "select with multiple where (AND)" {
  let q = select()
    .columns(["character", "size_w", "size_h"])
    .from("character")
    .where_(col("size_w").eq(val_int(3)))
    .where_(col("size_h").eq(val_int(4)))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\", \"size_w\", \"size_h\" FROM \"character\" WHERE ((\"size_w\" = $1) AND (\"size_h\" = $2))",
  )
  assert_eq(q.params, [@ast.Value::Int(3), @ast.Value::Int(4)])
}

test "select with three where conditions" {
  let q = select()
    .columns(["character", "size_w", "size_h"])
    .from("character")
    .where_(col("size_w").eq(val_int(3)))
    .where_(col("size_h").eq(val_int(4)))
    .where_(col("size_h").eq(val_int(5)))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\", \"size_w\", \"size_h\" FROM \"character\" WHERE (((\"size_w\" = $1) AND (\"size_h\" = $2)) AND (\"size_h\" = $3))",
  )
  assert_eq(
    q.params,
    [@ast.Value::Int(3), @ast.Value::Int(4), @ast.Value::Int(5)],
  )
}

test "select with or condition" {
  let q = select()
    .all()
    .from("users")
    .where_(
      col("role").eq(val_str("admin")).or_(col("role").eq(val_str("mod"))),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE ((\"role\" = $1) OR (\"role\" = $2))",
  )
  assert_eq(
    q.params,
    [@ast.Value::String("admin"), @ast.Value::String("mod")],
  )
}

test "select with or three conditions" {
  let q = select()
    .columns(["character", "size_w", "size_h"])
    .from("character")
    .where_(
      col("size_w")
        .eq(val_int(3))
        .or_(col("size_h").eq(val_int(4)))
        .or_(col("size_h").eq(val_int(5))),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\", \"size_w\", \"size_h\" FROM \"character\" WHERE (((\"size_w\" = $1) OR (\"size_h\" = $2)) OR (\"size_h\" = $3))",
  )
  assert_eq(
    q.params,
    [@ast.Value::Int(3), @ast.Value::Int(4), @ast.Value::Int(5)],
  )
}

test "select with nested and/or" {
  let q = select()
    .all()
    .from("users")
    .where_(
      col("a")
        .eq(val_int(1))
        .and_(col("b").eq(val_int(2)))
        .or_(col("c").eq(val_int(3))),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE (((\"a\" = $1) AND (\"b\" = $2)) OR (\"c\" = $3))",
  )
  assert_eq(
    q.params,
    [@ast.Value::Int(1), @ast.Value::Int(2), @ast.Value::Int(3)],
  )
}

test "select with complex nested conditions" {
  // (A LIKE 'C' OR (D LIKE 'D' AND E LIKE 'E')) AND (F LIKE 'F' OR G LIKE 'G')
  let q = select()
    .column("character")
    .from("character")
    .where_(
      col("character")
        .like("C")
        .or_(col("character").like("D").and_(col("character").like("E")))
        .and_(col("character").like("F").or_(col("character").like("G"))),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" WHERE (((\"character\" LIKE $1) OR ((\"character\" LIKE $2) AND (\"character\" LIKE $3))) AND ((\"character\" LIKE $4) OR (\"character\" LIKE $5)))",
  )
  assert_eq(
    q.params,
    [
      @ast.Value::String("C"),
      @ast.Value::String("D"),
      @ast.Value::String("E"),
      @ast.Value::String("F"),
      @ast.Value::String("G"),
    ],
  )
}

// ========================================================
// SELECT: Comparison operators
// ========================================================

test "select with ne operator" {
  let q = select()
    .all()
    .from("users")
    .where_(col("status").ne(val_str("deleted")))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE (\"status\" <> $1)",
  )
  assert_eq(q.params, [@ast.Value::String("deleted")])
}

test "select with lt operator" {
  let q = select()
    .all()
    .from("products")
    .where_(col("price").lt(val_int(100)))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"products\" WHERE (\"price\" < $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(100)])
}

test "select with gt operator" {
  let q = select()
    .columns(["id", "name"])
    .from("users")
    .where_(col("age").gt(val_int(18)))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"id\", \"name\" FROM \"users\" WHERE (\"age\" > $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(18)])
}

test "select with gte operator" {
  let q = select()
    .all()
    .from("products")
    .where_(col("stock").gte(val_int(0)))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"products\" WHERE (\"stock\" >= $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(0)])
}

test "select with lte operator" {
  let q = select()
    .all()
    .from("products")
    .where_(col("price").lte(val_int(1000)))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"products\" WHERE (\"price\" <= $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(1000)])
}

// ========================================================
// SELECT: IS NULL / IS NOT NULL
// ========================================================

test "select with is null" {
  let q = select()
    .columns(["character"])
    .from("character")
    .where_(col("font_id").is_null())
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" WHERE \"font_id\" IS NULL",
  )
  assert_eq(q.params, [])
}

test "select with is not null" {
  let q = select()
    .all()
    .from("users")
    .where_(col("email").is_not_null())
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE \"email\" IS NOT NULL",
  )
  assert_eq(q.params, [])
}

test "select with is null and is not null combined" {
  let q = select()
    .columns(["character"])
    .from("character")
    .where_(col("font_id").is_null())
    .where_(col("character").is_not_null())
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" WHERE (\"font_id\" IS NULL AND \"character\" IS NOT NULL)",
  )
  assert_eq(q.params, [])
}

test "select with is null or is not null" {
  let q = select()
    .column("id")
    .from("glyph")
    .where_(col("aspect").is_null().or_(col("aspect").is_not_null()))
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

test "select with like" {
  let q = select()
    .all()
    .from("users")
    .where_(col("name").like("%Alice%"))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE (\"name\" LIKE $1)",
  )
  assert_eq(q.params, [@ast.Value::String("%Alice%")])
}

test "select with multiple like (OR)" {
  let q = select()
    .columns(["character"])
    .from("character")
    .where_(
      col("character")
        .like("A%")
        .or_(col("character").like("%B"))
        .or_(col("character").like("%C%")),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" WHERE (((\"character\" LIKE $1) OR (\"character\" LIKE $2)) OR (\"character\" LIKE $3))",
  )
  assert_eq(
    q.params,
    [
      @ast.Value::String("A%"),
      @ast.Value::String("%B"),
      @ast.Value::String("%C%"),
    ],
  )
}

// ========================================================
// SELECT: IN / NOT IN
// ========================================================

test "select with in list" {
  let q = select()
    .all()
    .from("users")
    .where_(col("id").in_list([val_int(1), val_int(2), val_int(3)]))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE \"id\" IN ($1, $2, $3)",
  )
  assert_eq(
    q.params,
    [@ast.Value::Int(1), @ast.Value::Int(2), @ast.Value::Int(3)],
  )
}

test "select with table-qualified in list" {
  let q = select()
    .column("image")
    .from("glyph")
    .where_(table_col("glyph", "aspect").in_list([val_int(3), val_int(4)]))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"image\" FROM \"glyph\" WHERE \"glyph\".\"aspect\" IN ($1, $2)",
  )
  assert_eq(q.params, [@ast.Value::Int(3), @ast.Value::Int(4)])
}

test "select with not in list" {
  let q = select()
    .all()
    .from("users")
    .where_(col("status").not_in_list([val_str("banned"), val_str("deleted")]))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE \"status\" NOT IN ($1, $2)",
  )
  assert_eq(
    q.params,
    [@ast.Value::String("banned"), @ast.Value::String("deleted")],
  )
}

test "select with in list and like combined" {
  let q = select()
    .all()
    .from("users")
    .where_(col("id").in_list([val_int(1), val_int(2), val_int(3)]))
    .where_(col("name").like("A%"))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE (\"id\" IN ($1, $2, $3) AND (\"name\" LIKE $4))",
  )
  assert_eq(
    q.params,
    [
      @ast.Value::Int(1),
      @ast.Value::Int(2),
      @ast.Value::Int(3),
      @ast.Value::String("A%"),
    ],
  )
}

// ========================================================
// SELECT: BETWEEN / NOT BETWEEN
// ========================================================

test "select with between" {
  let q = select()
    .all()
    .from("products")
    .where_(col("price").between(val_int(100), val_int(500)))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"products\" WHERE \"price\" BETWEEN $1 AND $2",
  )
  assert_eq(q.params, [@ast.Value::Int(100), @ast.Value::Int(500)])
}

test "select with between table-qualified" {
  let q = select()
    .column("image")
    .from("glyph")
    .where_(table_col("glyph", "aspect").between(val_int(3), val_int(5)))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"image\" FROM \"glyph\" WHERE \"glyph\".\"aspect\" BETWEEN $1 AND $2",
  )
  assert_eq(q.params, [@ast.Value::Int(3), @ast.Value::Int(5)])
}

test "select with not between" {
  let q = select()
    .all()
    .from("products")
    .where_(col("price").not_between(val_int(800), val_int(1000)))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"products\" WHERE \"price\" NOT BETWEEN $1 AND $2",
  )
  assert_eq(q.params, [@ast.Value::Int(800), @ast.Value::Int(1000)])
}

test "select with between and not between combined" {
  let q = select()
    .columns(["aspect"])
    .from("glyph")
    .where_(col("aspect").between(val_int(3), val_int(5)))
    .where_(col("aspect").not_between(val_int(8), val_int(10)))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"aspect\" FROM \"glyph\" WHERE (\"aspect\" BETWEEN $1 AND $2 AND \"aspect\" NOT BETWEEN $3 AND $4)",
  )
  assert_eq(
    q.params,
    [
      @ast.Value::Int(3),
      @ast.Value::Int(5),
      @ast.Value::Int(8),
      @ast.Value::Int(10),
    ],
  )
}

// ========================================================
// SELECT: Arithmetic expressions
// ========================================================

test "select with arithmetic multiply" {
  let q = select()
    .expr_as(
      @ast.Expr::Binary(col("price"), @ast.BinOp::Mul, col("quantity")),
      "total",
    )
    .from("order_items")
    .build()
  assert_eq(
    q.sql,
    "SELECT (\"price\" * \"quantity\") AS \"total\" FROM \"order_items\"",
  )
  assert_eq(q.params, [])
}

test "select with arithmetic in where" {
  let q = select()
    .column("character")
    .from("character")
    .where_(
      @ast.Expr::Binary(col("size_w"), @ast.BinOp::Mul, val_int(2)).eq(
        @ast.Expr::Binary(col("size_h"), @ast.BinOp::Div, val_int(2)),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" WHERE ((\"size_w\" * $1) = (\"size_h\" / $2))",
  )
  assert_eq(q.params, [@ast.Value::Int(2), @ast.Value::Int(2)])
}

test "select with complex arithmetic" {
  // (size_w * 2) + (size_h / 3) = 4
  let q = select()
    .columns(["character", "size_w", "size_h"])
    .from("character")
    .where_(
      @ast.Expr::Binary(
        @ast.Expr::Binary(col("size_w"), @ast.BinOp::Mul, val_int(2)),
        @ast.BinOp::Add,
        @ast.Expr::Binary(col("size_h"), @ast.BinOp::Div, val_int(3)),
      )
        .eq(val_int(4)),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\", \"size_w\", \"size_h\" FROM \"character\" WHERE (((\"size_w\" * $1) + (\"size_h\" / $2)) = $3)",
  )
  assert_eq(
    q.params,
    [@ast.Value::Int(2), @ast.Value::Int(3), @ast.Value::Int(4)],
  )
}

// ========================================================
// SELECT: NOT expression
// ========================================================

test "select with not expression" {
  let q = select()
    .all()
    .from("users")
    .where_(
      @ast.Expr::Unary(@ast.UnOp::Not, col("active").eq(val_bool(true))),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE (NOT (\"active\" = $1))",
  )
  assert_eq(q.params, [@ast.Value::Bool(true)])
}

test "select with negation" {
  let q = select()
    .expr(@ast.Expr::Unary(@ast.UnOp::Neg, col("balance")))
    .from("accounts")
    .build()
  assert_eq(q.sql, "SELECT (-\"balance\") FROM \"accounts\"")
  assert_eq(q.params, [])
}

// ========================================================
// SELECT: Functions (COUNT, MAX, COALESCE, SUM, etc.)
// ========================================================

test "select with count star" {
  let q = select().expr(func("COUNT", [asterisk()])).from("users").build()
  assert_eq(q.sql, "SELECT COUNT(*) FROM \"users\"")
  assert_eq(q.params, [])
}

test "select with count star alias" {
  let q = select()
    .expr_as(func("COUNT", [asterisk()]), "total")
    .from("users")
    .build()
  assert_eq(q.sql, "SELECT COUNT(*) AS \"total\" FROM \"users\"")
  assert_eq(q.params, [])
}

test "select with max function" {
  let q = select()
    .column("aspect")
    .expr(func("MAX", [col("image")]))
    .from("glyph")
    .group_by("aspect")
    .having(col("aspect").gt(val_int(2)))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"aspect\", MAX(\"image\") FROM \"glyph\" GROUP BY \"aspect\" HAVING (\"aspect\" > $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(2)])
}

test "select with coalesce" {
  let q = select()
    .expr(
      func(
        "COALESCE",
        [col("nickname"), col("name"), val_str("Anonymous")],
      ),
    )
    .from("users")
    .build()
  assert_eq(
    q.sql,
    "SELECT COALESCE(\"nickname\", \"name\", $1) FROM \"users\"",
  )
  assert_eq(q.params, [@ast.Value::String("Anonymous")])
}

test "select with coalesce in where" {
  // COALESCE("aspect", 0) > 2
  let q = select()
    .columns(["aspect"])
    .from("glyph")
    .where_(func("COALESCE", [col("aspect"), val_int(0)]).gt(val_int(2)))
    .build()
  assert_eq(
    q.sql,
    "SELECT \"aspect\" FROM \"glyph\" WHERE (COALESCE(\"aspect\", $1) > $2)",
  )
  assert_eq(q.params, [@ast.Value::Int(0), @ast.Value::Int(2)])
}

test "select with sum function" {
  let q = select()
    .expr_as(func("SUM", [col("amount")]), "total_amount")
    .from("transactions")
    .build()
  assert_eq(
    q.sql,
    "SELECT SUM(\"amount\") AS \"total_amount\" FROM \"transactions\"",
  )
  assert_eq(q.params, [])
}

test "select with avg function" {
  let q = select()
    .expr_as(func("AVG", [col("price")]), "avg_price")
    .from("products")
    .build()
  assert_eq(
    q.sql,
    "SELECT AVG(\"price\") AS \"avg_price\" FROM \"products\"",
  )
  assert_eq(q.params, [])
}

test "select with min function" {
  let q = select()
    .expr_as(func("MIN", [col("created_at")]), "earliest")
    .from("events")
    .build()
  assert_eq(
    q.sql,
    "SELECT MIN(\"created_at\") AS \"earliest\" FROM \"events\"",
  )
  assert_eq(q.params, [])
}

// ========================================================
// SELECT: Expression alias
// ========================================================

test "select with expression alias" {
  let q = select()
    .expr_as(col("character"), "C")
    .from("character")
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" AS \"C\" FROM \"character\"",
  )
  assert_eq(q.params, [])
}

// ========================================================
// SELECT: Table references
// ========================================================

test "select with table all columns" {
  let q = select().table_all_columns("users").from("users").build()
  assert_eq(q.sql, "SELECT \"users\".* FROM \"users\"")
  assert_eq(q.params, [])
}

test "select with table all columns and named column" {
  let q = select()
    .table_all_columns("character")
    .expr(@ast.Expr::Column(@ast.ColumnRef::TableColumn("font", "name")))
    .from("character")
    .join(
      "font",
      table_col("character", "font_id").eq(table_col("font", "id")),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\".*, \"font\".\"name\" FROM \"character\" INNER JOIN \"font\" ON (\"character\".\"font_id\" = \"font\".\"id\")",
  )
  assert_eq(q.params, [])
}

test "select with from_as alias" {
  let q = select()
    .columns(["id", "name"])
    .from_as("users", "u")
    .build()
  assert_eq(q.sql, "SELECT \"id\", \"name\" FROM \"users\" AS \"u\"")
  assert_eq(q.params, [])
}

test "select with schema-qualified table" {
  let q = select().all().from_schema("public", "users").build()
  assert_eq(q.sql, "SELECT * FROM \"public\".\"users\"")
  assert_eq(q.params, [])
}

test "select with table qualified columns" {
  let q = select()
    .all()
    .from("users")
    .where_(table_col("users", "id").eq(val_int(1)))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE (\"users\".\"id\" = $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(1)])
}

// ========================================================
// SELECT: JOINs
// ========================================================

test "select with inner join" {
  let q = select()
    .columns(["name", "total"])
    .from("users")
    .join(
      "orders",
      table_col("users", "id").eq(table_col("orders", "user_id")),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"name\", \"total\" FROM \"users\" INNER JOIN \"orders\" ON (\"users\".\"id\" = \"orders\".\"user_id\")",
  )
  assert_eq(q.params, [])
}

test "select with left join" {
  let q = select()
    .columns(["character"])
    .from("character")
    .left_join(
      "font",
      table_col("character", "font_id").eq(table_col("font", "id")),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" LEFT JOIN \"font\" ON (\"character\".\"font_id\" = \"font\".\"id\")",
  )
  assert_eq(q.params, [])
}

test "select with right join" {
  let q = select()
    .columns(["name"])
    .from("users")
    .right_join(
      "orders",
      table_col("users", "id").eq(table_col("orders", "user_id")),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"name\" FROM \"users\" RIGHT JOIN \"orders\" ON (\"users\".\"id\" = \"orders\".\"user_id\")",
  )
  assert_eq(q.params, [])
}

test "select with full join" {
  let q = select()
    .all()
    .from("left_table")
    .full_join(
      "right_table",
      table_col("left_table", "id").eq(table_col("right_table", "id")),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"left_table\" FULL JOIN \"right_table\" ON (\"left_table\".\"id\" = \"right_table\".\"id\")",
  )
  assert_eq(q.params, [])
}

test "select with cross join" {
  let q = select().all().from("colors").cross_join("sizes").build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"colors\" CROSS JOIN \"sizes\"",
  )
  assert_eq(q.params, [])
}

test "select with multiple joins" {
  let q = select()
    .all()
    .from("orders")
    .join(
      "users",
      table_col("orders", "user_id").eq(table_col("users", "id")),
    )
    .left_join(
      "products",
      table_col("orders", "product_id").eq(table_col("products", "id")),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"orders\" INNER JOIN \"users\" ON (\"orders\".\"user_id\" = \"users\".\"id\") LEFT JOIN \"products\" ON (\"orders\".\"product_id\" = \"products\".\"id\")",
  )
  assert_eq(q.params, [])
}

test "select with left join then inner join" {
  let q = select()
    .columns(["character"])
    .from("character")
    .left_join(
      "font",
      table_col("character", "font_id").eq(table_col("font", "id")),
    )
    .join(
      "glyph",
      table_col("character", "character").eq(table_col("glyph", "image")),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" LEFT JOIN \"font\" ON (\"character\".\"font_id\" = \"font\".\"id\") INNER JOIN \"glyph\" ON (\"character\".\"character\" = \"glyph\".\"image\")",
  )
  assert_eq(q.params, [])
}

test "select with join compound on condition" {
  let q = select()
    .columns(["character"])
    .from("character")
    .left_join(
      "font",
      table_col("character", "font_id")
        .eq(table_col("font", "id"))
        .and_(table_col("character", "font_id").eq(table_col("font", "id"))),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"character\" FROM \"character\" LEFT JOIN \"font\" ON ((\"character\".\"font_id\" = \"font\".\"id\") AND (\"character\".\"font_id\" = \"font\".\"id\"))",
  )
  assert_eq(q.params, [])
}

test "select with join and where" {
  let q = select()
    .columns(["name", "total"])
    .from("users")
    .join(
      "orders",
      table_col("users", "id").eq(table_col("orders", "user_id")),
    )
    .where_(col("total").gt(val_int(100)))
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

test "select with group by and having" {
  let q = select()
    .column("department")
    .expr(func("COUNT", [asterisk()]))
    .from("employees")
    .group_by("department")
    .having(
      @ast.Expr::Binary(
        func("COUNT", [asterisk()]),
        @ast.BinOp::Gt,
        @ast.Expr::Value(@ast.Value::Int(5)),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"department\", COUNT(*) FROM \"employees\" GROUP BY \"department\" HAVING (COUNT(*) > $1)",
  )
  assert_eq(q.params, [@ast.Value::Int(5)])
}

test "select with group by table-qualified" {
  let q = select()
    .columns(["id", "aspect"])
    .expr(func("MAX", [col("image")]))
    .from("glyph")
    .group_by("id")
    .group_by("aspect")
    .having(col("aspect").gt(val_int(2)))
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

test "select with order by asc" {
  let q = select()
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

test "select with multiple order by" {
  let q = select()
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

test "select with order by table-qualified" {
  let q = select()
    .columns(["aspect"])
    .from("glyph")
    .where_(func("COALESCE", [col("aspect"), val_int(0)]).gt(val_int(2)))
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

test "select with null parameter" {
  let q = select()
    .all()
    .from("users")
    .where_(col("name").eq(val_null()))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE (\"name\" = $1)",
  )
  assert_eq(q.params, [@ast.Value::Null])
}

test "select with double value" {
  let q = select()
    .all()
    .from("products")
    .where_(col("rating").gte(val_double(4.5)))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"products\" WHERE (\"rating\" >= $1)",
  )
  assert_eq(q.params, [@ast.Value::Double(4.5)])
}

test "select with int64 value" {
  let q = select()
    .all()
    .from("events")
    .where_(col("timestamp").gt(val_int64(1700000000L)))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"events\" WHERE (\"timestamp\" > $1)",
  )
  assert_eq(q.params, [@ast.Value::Int64(1700000000L)])
}

test "select with bool value" {
  let q = select()
    .all()
    .from("users")
    .where_(col("active").eq(val_bool(true)))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE (\"active\" = $1)",
  )
  assert_eq(q.params, [@ast.Value::Bool(true)])
}

test "select with string value" {
  let q = select()
    .columns(["character"])
    .from("character")
    .where_(col("character").eq(val_str("A")))
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

test "select param numbering across clauses" {
  let q = select()
    .all()
    .from("users")
    .where_(col("age").gt(val_int(18)))
    .where_(col("name").like("%test%"))
    .limit(10)
    .offset(0)
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE ((\"age\" > $1) AND (\"name\" LIKE $2)) LIMIT $3 OFFSET $4",
  )
  assert_eq(
    q.params,
    [
      @ast.Value::Int(18),
      @ast.Value::String("%test%"),
      @ast.Value::Int(10),
      @ast.Value::Int(0),
    ],
  )
}

test "select same values get separate params" {
  let q = select()
    .all()
    .from("users")
    .where_(col("a").eq(val_int(1)))
    .where_(col("b").eq(val_int(1)))
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

test "insert basic" {
  let q = insert_into("users")
    .columns(["name", "email"])
    .values([val_str("Alice"), val_str("alice@example.com")])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"users\" (\"name\", \"email\") VALUES ($1, $2)",
  )
  assert_eq(
    q.params,
    [
      @ast.Value::String("Alice"),
      @ast.Value::String("alice@example.com"),
    ],
  )
}

test "insert with double value" {
  let q = insert_into("glyph")
    .columns(["image", "aspect"])
    .values([val_str("04108048"), val_double(3.1415)])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"glyph\" (\"image\", \"aspect\") VALUES ($1, $2)",
  )
  assert_eq(
    q.params,
    [@ast.Value::String("04108048"), @ast.Value::Double(3.1415)],
  )
}

test "insert multi-row" {
  let q = insert_into("users")
    .columns(["name", "email"])
    .values([val_str("Alice"), val_str("alice@example.com")])
    .values([val_str("Bob"), val_str("bob@example.com")])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"users\" (\"name\", \"email\") VALUES ($1, $2), ($3, $4)",
  )
  assert_eq(
    q.params,
    [
      @ast.Value::String("Alice"),
      @ast.Value::String("alice@example.com"),
      @ast.Value::String("Bob"),
      @ast.Value::String("bob@example.com"),
    ],
  )
}

test "insert multi-row with null" {
  let q = insert_into("glyph")
    .columns(["image", "aspect"])
    .values([val_str("image1"), val_double(3.1415)])
    .values([val_null(), val_double(2.1345)])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"glyph\" (\"image\", \"aspect\") VALUES ($1, $2), ($3, $4)",
  )
  assert_eq(
    q.params,
    [
      @ast.Value::String("image1"),
      @ast.Value::Double(3.1415),
      @ast.Value::Null,
      @ast.Value::Double(2.1345),
    ],
  )
}

// ========================================================
// INSERT: RETURNING
// ========================================================

test "insert with returning" {
  let q = insert_into("users")
    .columns(["name", "email"])
    .values([val_str("Bob"), val_str("bob@example.com")])
    .returning(["id"])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"users\" (\"name\", \"email\") VALUES ($1, $2) RETURNING \"id\"",
  )
  assert_eq(
    q.params,
    [@ast.Value::String("Bob"), @ast.Value::String("bob@example.com")],
  )
}

test "insert with multiple returning" {
  let q = insert_into("users")
    .columns(["name"])
    .values([val_str("Charlie")])
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

test "update basic" {
  let q = update("users")
    .set("name", val_str("Bob"))
    .set("active", val_bool(true))
    .where_(col("id").eq(val_int(1)))
    .build()
  assert_eq(
    q.sql,
    "UPDATE \"users\" SET \"name\" = $1, \"active\" = $2 WHERE (\"id\" = $3)",
  )
  assert_eq(
    q.params,
    [
      @ast.Value::String("Bob"),
      @ast.Value::Bool(true),
      @ast.Value::Int(1),
    ],
  )
}

test "update without where" {
  let q = update("settings").set("value", val_str("default")).build()
  assert_eq(q.sql, "UPDATE \"settings\" SET \"value\" = $1")
  assert_eq(q.params, [@ast.Value::String("default")])
}

test "update with multiple set and where" {
  let q = update("products")
    .set("name", val_str("Widget"))
    .set("price", val_int(999))
    .set("active", val_bool(false))
    .where_(col("id").eq(val_int(42)))
    .where_(col("version").eq(val_int(3)))
    .build()
  assert_eq(
    q.sql,
    "UPDATE \"products\" SET \"name\" = $1, \"price\" = $2, \"active\" = $3 WHERE ((\"id\" = $4) AND (\"version\" = $5))",
  )
  assert_eq(
    q.params,
    [
      @ast.Value::String("Widget"),
      @ast.Value::Int(999),
      @ast.Value::Bool(false),
      @ast.Value::Int(42),
      @ast.Value::Int(3),
    ],
  )
}

test "update set column to expression" {
  // SET "aspect" = "aspect" + 1
  let q = update("glyph")
    .set(
      "aspect",
      @ast.Expr::Binary(col("aspect"), @ast.BinOp::Add, val_int(1)),
    )
    .where_(col("id").eq(val_int(1)))
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

test "update with returning" {
  let q = update("users")
    .set("name", val_str("Updated"))
    .where_(col("id").eq(val_int(1)))
    .returning(["id", "name"])
    .build()
  assert_eq(
    q.sql,
    "UPDATE \"users\" SET \"name\" = $1 WHERE (\"id\" = $2) RETURNING \"id\", \"name\"",
  )
  assert_eq(
    q.params,
    [@ast.Value::String("Updated"), @ast.Value::Int(1)],
  )
}

// ========================================================
// DELETE: Basic
// ========================================================

test "delete basic" {
  let q = delete_from("users").where_(col("id").eq(val_int(42))).build()
  assert_eq(q.sql, "DELETE FROM \"users\" WHERE (\"id\" = $1)")
  assert_eq(q.params, [@ast.Value::Int(42)])
}

test "delete without where" {
  let q = delete_from("temp_data").build()
  assert_eq(q.sql, "DELETE FROM \"temp_data\"")
  assert_eq(q.params, [])
}

test "delete with multiple where" {
  let q = delete_from("logs")
    .where_(col("level").eq(val_str("debug")))
    .where_(col("age_days").gt(val_int(30)))
    .build()
  assert_eq(
    q.sql,
    "DELETE FROM \"logs\" WHERE ((\"level\" = $1) AND (\"age_days\" > $2))",
  )
  assert_eq(
    q.params,
    [@ast.Value::String("debug"), @ast.Value::Int(30)],
  )
}

// ========================================================
// DELETE: RETURNING
// ========================================================

test "delete with returning" {
  let q = delete_from("users")
    .where_(col("active").eq(val_bool(false)))
    .returning(["id"])
    .build()
  assert_eq(
    q.sql,
    "DELETE FROM \"users\" WHERE (\"active\" = $1) RETURNING \"id\"",
  )
  assert_eq(q.params, [@ast.Value::Bool(false)])
}

test "delete with returning multiple columns" {
  let q = delete_from("glyph")
    .where_(col("id").eq(val_int(1)))
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

test "select with empty columns defaults to star" {
  let q = select().from("users").build()
  assert_eq(q.sql, "SELECT * FROM \"users\"")
  assert_eq(q.params, [])
}

test "select without from clause" {
  let q = select().expr(func("COUNT", [asterisk()])).build()
  assert_eq(q.sql, "SELECT COUNT(*)")
  assert_eq(q.params, [])
}

test "select with in_list empty array" {
  let q = select()
    .all()
    .from("users")
    .where_(col("id").in_list([]))
    .build()
  assert_eq(q.sql, "SELECT * FROM \"users\" WHERE \"id\" IN ()")
  assert_eq(q.params, [])
}

test "select with not_in_list empty array" {
  let q = select()
    .all()
    .from("users")
    .where_(col("id").not_in_list([]))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE \"id\" NOT IN ()",
  )
  assert_eq(q.params, [])
}

test "insert with single column single value" {
  let q = insert_into("users")
    .columns(["name"])
    .values([val_str("Alice")])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"users\" (\"name\") VALUES ($1)",
  )
  assert_eq(q.params, [@ast.Value::String("Alice")])
}

test "update with single set" {
  let q = update("users")
    .set("active", val_bool(false))
    .where_(col("id").eq(val_int(1)))
    .build()
  assert_eq(
    q.sql,
    "UPDATE \"users\" SET \"active\" = $1 WHERE (\"id\" = $2)",
  )
  assert_eq(q.params, [@ast.Value::Bool(false), @ast.Value::Int(1)])
}

test "delete with complex where" {
  let q = delete_from("users")
    .where_(col("active").eq(val_bool(false)).or_(col("banned").eq(val_bool(true))))
    .build()
  assert_eq(
    q.sql,
    "DELETE FROM \"users\" WHERE ((\"active\" = $1) OR (\"banned\" = $2))",
  )
  assert_eq(
    q.params,
    [@ast.Value::Bool(false), @ast.Value::Bool(true)],
  )
}

test "select with many params ensures sequential numbering" {
  let q = insert_into("data")
    .columns(["a", "b", "c", "d", "e"])
    .values([val_int(1), val_int(2), val_int(3), val_int(4), val_int(5)])
    .values([val_int(6), val_int(7), val_int(8), val_int(9), val_int(10)])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"data\" (\"a\", \"b\", \"c\", \"d\", \"e\") VALUES ($1, $2, $3, $4, $5), ($6, $7, $8, $9, $10)",
  )
  assert_eq(
    q.params,
    [
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
    ],
  )
}

test "select distinct with where and order by" {
  let q = select()
    .distinct()
    .columns(["name", "email"])
    .from("users")
    .where_(col("active").eq(val_bool(true)))
    .order_by("name", @ast.Asc)
    .build()
  assert_eq(
    q.sql,
    "SELECT DISTINCT \"name\", \"email\" FROM \"users\" WHERE (\"active\" = $1) ORDER BY \"name\" ASC",
  )
  assert_eq(q.params, [@ast.Value::Bool(true)])
}

test "select complex: join + where + group by + having + order by + limit" {
  let q = select()
    .column("department")
    .expr_as(func("COUNT", [asterisk()]), "cnt")
    .from_as("employees", "e")
    .join(
      "departments",
      table_col("e", "dept_id").eq(table_col("departments", "id")),
    )
    .where_(col("active").eq(val_bool(true)))
    .group_by("department")
    .having(func("COUNT", [asterisk()]).gt(val_int(3)))
    .order_by("department", @ast.Asc)
    .limit(10)
    .build()
  assert_eq(
    q.sql,
    "SELECT \"department\", COUNT(*) AS \"cnt\" FROM \"employees\" AS \"e\" INNER JOIN \"departments\" ON (\"e\".\"dept_id\" = \"departments\".\"id\") WHERE (\"active\" = $1) GROUP BY \"department\" HAVING (COUNT(*) > $2) ORDER BY \"department\" ASC LIMIT $3",
  )
  assert_eq(
    q.params,
    [@ast.Value::Bool(true), @ast.Value::Int(3), @ast.Value::Int(10)],
  )
}

test "select is null or combined with lt" {
  let q = select()
    .column("id")
    .from("glyph")
    .where_(
      col("aspect")
        .is_null()
        .or_(col("aspect").is_not_null().and_(col("aspect").lt(val_int(8)))),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT \"id\" FROM \"glyph\" WHERE (\"aspect\" IS NULL OR (\"aspect\" IS NOT NULL AND (\"aspect\" < $1)))",
  )
  assert_eq(q.params, [@ast.Value::Int(8)])
}

test "update with set to null" {
  let q = update("users")
    .set("deleted_at", val_null())
    .where_(col("id").eq(val_int(1)))
    .build()
  assert_eq(
    q.sql,
    "UPDATE \"users\" SET \"deleted_at\" = $1 WHERE (\"id\" = $2)",
  )
  assert_eq(q.params, [@ast.Value::Null, @ast.Value::Int(1)])
}

test "insert three rows" {
  let q = insert_into("items")
    .columns(["name", "price"])
    .values([val_str("A"), val_int(10)])
    .values([val_str("B"), val_int(20)])
    .values([val_str("C"), val_int(30)])
    .build()
  assert_eq(
    q.sql,
    "INSERT INTO \"items\" (\"name\", \"price\") VALUES ($1, $2), ($3, $4), ($5, $6)",
  )
  assert_eq(
    q.params,
    [
      @ast.Value::String("A"),
      @ast.Value::Int(10),
      @ast.Value::String("B"),
      @ast.Value::Int(20),
      @ast.Value::String("C"),
      @ast.Value::Int(30),
    ],
  )
}

test "select with not in and between combined" {
  let q = select()
    .all()
    .from("products")
    .where_(col("category").not_in_list([val_str("hidden"), val_str("draft")]))
    .where_(col("price").between(val_int(10), val_int(100)))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"products\" WHERE (\"category\" NOT IN ($1, $2) AND \"price\" BETWEEN $3 AND $4)",
  )
  assert_eq(
    q.params,
    [
      @ast.Value::String("hidden"),
      @ast.Value::String("draft"),
      @ast.Value::Int(10),
      @ast.Value::Int(100),
    ],
  )
}

test "select with single in_list item" {
  let q = select()
    .all()
    .from("users")
    .where_(col("id").in_list([val_int(42)]))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM \"users\" WHERE \"id\" IN ($1)",
  )
  assert_eq(q.params, [@ast.Value::Int(42)])
}
