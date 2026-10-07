///|
test "having does not reuse an unrelated selected literal" {
  let q = @builder.select()
    .expr_as(@builder.val_str("2026-01-01"), "label")
    .expr(@builder.func("MIN", [@builder.col("created_at")]))
    .from("events")
    .having(
      @builder.func("MIN", [@builder.col("created_at")]).gt(
        @builder.val_str("2026-01-01"),
      ),
    )
    .build()
  assert_eq(
    q.sql,
    "SELECT $1 AS \"label\", MIN(\"created_at\") FROM \"events\" HAVING (MIN(\"created_at\") > $2)",
  )
  assert_eq(q.params, [@ast.String("2026-01-01"), @ast.String("2026-01-01")])
}

///|
test "nested CTE retains WITH and parameter ordering" {
  let seed = @builder.select().expr_as(@builder.val_int(7), "id")
  let sub = @builder.select()
    .with_("seed", seed)
    .column("id")
    .from("seed")
    .where_(@builder.col("id").gt(@builder.val_int(3)))
  let q = @builder.select()
    .all()
    .from_sub(sub, "s")
    .where_(@builder.col("id").lt(@builder.val_int(9)))
    .build()
  assert_eq(
    q.sql,
    "SELECT * FROM (WITH \"seed\" AS (SELECT $1 AS \"id\") SELECT \"id\" FROM \"seed\" WHERE (\"id\" > $2)) AS \"s\" WHERE (\"id\" < $3)",
  )
  assert_eq(q.params, [@ast.Int(7), @ast.Int(3), @ast.Int(9)])
}

///|
test "having preserves parameters of its grouped expression" {
  let bucket = @builder.col("age").add(@builder.val_int(10))
  let q = @builder.select()
    .expr_as(bucket, "bucket")
    .from("users")
    .group_by_expr(bucket)
    .having(bucket.gt(@builder.val_int(20)))
    .build()
  assert_eq(
    q.sql,
    "SELECT (\"age\" + $1) AS \"bucket\" FROM \"users\" GROUP BY (\"age\" + $1) HAVING ((\"age\" + $1) > $2)",
  )
  assert_eq(q.params, [@ast.Int(10), @ast.Int(20)])
}

///|
test "repeated selected grouping expression shares its bind identity" {
  let bucket = @builder.col("age").add(@builder.val_int(10))
  let q = @builder.select()
    .expr_as(bucket, "a")
    .expr_as(bucket, "b")
    .from("users")
    .group_by_expr(bucket)
    .build()
  assert_eq(
    q.sql,
    "SELECT (\"age\" + $1) AS \"a\", (\"age\" + $1) AS \"b\" FROM \"users\" GROUP BY (\"age\" + $1)",
  )
  assert_eq(q.params, [@ast.Int(10)])
}

///|
test "group by reuses selected expression parameters within its scope" {
  let bucket = @builder.col("age").add(@builder.val_int(10))
  let q = @builder.select()
    .expr_as(bucket, "bucket")
    .expr(@builder.func("COUNT", [@builder.asterisk()]))
    .from("users")
    .where_(@builder.col("score").gt(@builder.val_int(10)))
    .group_by_expr(bucket)
    .build()
  assert_eq(
    q.sql,
    "SELECT (\"age\" + $1) AS \"bucket\", COUNT(*) FROM \"users\" WHERE (\"score\" > $2) GROUP BY (\"age\" + $1)",
  )
  assert_eq(q.params, [@ast.Int(10), @ast.Int(10)])
}

///|
test "statement snapshot owns columns and nested expression arrays" {
  let choices = [@builder.val_int(1)]
  let source = @builder.select()
    .column("id")
    .from("users")
    .where_(@builder.col("id").in_list(choices))
  let stmt = source.build_statement()
  ignore(source.column("name"))
  choices.push(@builder.val_int(2))
  let q = @ast.render_select(stmt)
  assert_eq(q.sql, "SELECT \"id\" FROM \"users\" WHERE \"id\" IN ($1)")
  assert_eq(q.params, [@ast.Int(1)])
}

///|
test "mixed set operations preserve left to right builder grouping" {
  let q = @builder.select()
    .expr(@builder.val_int(1))
    .union(@builder.select().expr(@builder.val_int(2)))
    .intersect(@builder.select().expr(@builder.val_int(2)))
    .build()
  assert_eq(q.sql, "(SELECT $1 UNION SELECT $2) INTERSECT SELECT $3")
  assert_eq(q.params, [@ast.Int(1), @ast.Int(2), @ast.Int(2)])
}

///|
test "union operand keeps its CTE order and limit local" {
  let rhs = @builder.select()
    .with_("b", @builder.select().expr_as(@builder.val_int(2), "id"))
    .column("id")
    .from("b")
    .order_by("id", @ast.Desc)
    .limit(1)
  let q = @builder.select()
    .expr_as(@builder.val_int(1), "id")
    .union(rhs)
    .order_by("id", @ast.Asc)
    .limit(10)
    .build()
  assert_eq(
    q.sql,
    "SELECT $1 AS \"id\" UNION (WITH \"b\" AS (SELECT $2 AS \"id\") SELECT \"id\" FROM \"b\" ORDER BY \"id\" DESC LIMIT $3) ORDER BY \"id\" ASC LIMIT $4",
  )
  assert_eq(q.params, [@ast.Int(1), @ast.Int(2), @ast.Int(1), @ast.Int(10)])
}

///|
test "order by does not reuse a selected literal with a different inferred type" {
  let stmt = @builder.select()
    .expr_as(@builder.val_str("2026-01-01"), "label")
    .column("created_at")
    .from("events")
    .build_statement()
  stmt.order_by.push({
    expr: @builder.col("created_at").gt(@builder.val_str("2026-01-01")),
    order: @ast.Asc,
  })
  let q = @ast.render_select(stmt)
  assert_eq(
    q.sql,
    "SELECT $1 AS \"label\", \"created_at\" FROM \"events\" ORDER BY (\"created_at\" > $2) ASC",
  )
  assert_eq(q.params, [@ast.String("2026-01-01"), @ast.String("2026-01-01")])
}

///|
test "having reuses a grouping expression absent from the select list" {
  let bucket = @builder.col("age").add(@builder.val_int(10))
  let q = @builder.select()
    .expr(@builder.func("COUNT", [@builder.asterisk()]))
    .from("users")
    .group_by_expr(bucket)
    .having(bucket.gt(@builder.val_int(20)))
    .build()
  assert_eq(
    q.sql,
    "SELECT COUNT(*) FROM \"users\" GROUP BY (\"age\" + $1) HAVING ((\"age\" + $1) > $2)",
  )
  assert_eq(q.params, [@ast.Int(10), @ast.Int(20)])
}

///|
test "group by reuses a grouping expression nested inside a selected expression" {
  let bucket = @builder.col("age").add(@builder.val_int(10))
  let q = @builder.select()
    .expr_as(bucket.mul(@builder.val_int(2)), "dbl")
    .expr(@builder.func("COUNT", [@builder.asterisk()]))
    .from("users")
    .group_by_expr(bucket)
    .build()
  assert_eq(
    q.sql,
    "SELECT ((\"age\" + $1) * $2) AS \"dbl\", COUNT(*) FROM \"users\" GROUP BY (\"age\" + $1)",
  )
  assert_eq(q.params, [@ast.Int(10), @ast.Int(2)])
}

///|
test "order by reuses grouped subexpressions but keeps unrelated values independent" {
  let bucket = @builder.col("age").add(@builder.val_int(10))
  let stmt = @builder.select()
    .expr(@builder.func("COUNT", [@builder.asterisk()]))
    .from("users")
    .group_by_expr(bucket)
    .build_statement()
  stmt.order_by.push({
    expr: bucket.add(@builder.val_int(10)),
    order: @ast.Desc,
  })
  let q = @ast.render_select(stmt)
  assert_eq(
    q.sql,
    "SELECT COUNT(*) FROM \"users\" GROUP BY (\"age\" + $1) ORDER BY ((\"age\" + $1) + $2) DESC",
  )
  assert_eq(q.params, [@ast.Int(10), @ast.Int(10)])
}

///|
test "statement snapshot isolates CTE lists in both directions" {
  let source = @builder.select()
    .with_("seed", @builder.select().expr_as(@builder.val_int(1), "id"))
    .all()
    .from("seed")
    .build_statement()
  let copy = source.snapshot()
  let original = @ast.render_select(copy)
  source.ctes.push({
    name: "source_only",
    query: @builder.select().expr(@builder.val_int(2)).build_statement(),
  })
  assert_eq(@ast.render_select(copy), original)
  let changed_source = @ast.render_select(source)
  copy.ctes.push({
    name: "copy_only",
    query: @builder.select().expr(@builder.val_int(3)).build_statement(),
  })
  assert_eq(@ast.render_select(source), changed_source)
}

///|
test "statement snapshot isolates nested CTE statements in both directions" {
  let source = @builder.select()
    .with_("seed", @builder.select().expr_as(@builder.val_int(1), "id"))
    .all()
    .from("seed")
    .build_statement()
  let copy = source.snapshot()
  let original = @ast.render_select(copy)
  source.ctes[0].query.columns.push(@ast.Expr(@builder.val_int(2)))
  assert_eq(@ast.render_select(copy), original)
  let changed_source = @ast.render_select(source)
  copy.ctes[0].query.columns.push(@ast.Expr(@builder.val_int(3)))
  assert_eq(@ast.render_select(source), changed_source)
}

///|
test "statement snapshot isolates FROM subqueries in both directions" {
  let source = @builder.select()
    .all()
    .from_sub(@builder.select().expr_as(@builder.val_int(1), "id"), "s")
    .build_statement()
  let copy = source.snapshot()
  let original = @ast.render_select(copy)
  let source_inner = match source.from {
    Some(SubQuery(stmt, _)) => stmt
    _ => panic()
  }
  let copy_inner = match copy.from {
    Some(SubQuery(stmt, _)) => stmt
    _ => panic()
  }
  source_inner.columns.push(@ast.Expr(@builder.val_int(2)))
  assert_eq(@ast.render_select(copy), original)
  let changed_source = @ast.render_select(source)
  copy_inner.columns.push(@ast.Expr(@builder.val_int(3)))
  assert_eq(@ast.render_select(source), changed_source)
}

///|
test "scalar subquery retains WITH and surrounding parameter order" {
  let seed = @builder.select()
    .expr_as(@builder.val_int(7).add(@builder.raw("0")), "id")
  let sub = @builder.select()
    .with_("seed", seed)
    .column("id")
    .from("seed")
    .where_(@builder.col("id").gt(@builder.val_int(3)))
  let q = @builder.select()
    .expr_as(@builder.val_int(9), "marker")
    .expr_as(@ast.Subquery(sub.build_statement()), "id")
    .build()
  assert_eq(q.sql, "SELECT $1 AS \"marker\", (WITH \"seed\" AS (SELECT ($2 + 0) AS \"id\") SELECT \"id\" FROM \"seed\" WHERE (\"id\" > $3)) AS \"id\"")
  assert_eq(q.params, [@ast.Int(9), @ast.Int(7), @ast.Int(3)])
}

///|
test "IN subquery retains WITH and surrounding parameter order" {
  let seed = @builder.select()
    .expr_as(@builder.val_int(7).add(@builder.raw("0")), "id")
  let sub = @builder.select()
    .with_("seed", seed)
    .column("id")
    .from("seed")
    .where_(@builder.col("id").gt(@builder.val_int(3)))
  let q = @builder.select()
    .expr_as(@builder.val_int(9), "marker")
    .where_(@builder.val_int(7).in_subquery(sub.build_statement()))
    .build()
  assert_eq(q.sql, "SELECT $1 AS \"marker\" WHERE $2 IN (WITH \"seed\" AS (SELECT ($3 + 0) AS \"id\") SELECT \"id\" FROM \"seed\" WHERE (\"id\" > $4))")
  assert_eq(q.params, [@ast.Int(9), @ast.Int(7), @ast.Int(7), @ast.Int(3)])
}

///|
test "NOT IN subquery retains WITH and surrounding parameter order" {
  let seed = @builder.select()
    .expr_as(@builder.val_int(7).add(@builder.raw("0")), "id")
  let sub = @builder.select()
    .with_("seed", seed)
    .column("id")
    .from("seed")
    .where_(@builder.col("id").gt(@builder.val_int(3)))
  let q = @builder.select()
    .expr_as(@builder.val_int(9), "marker")
    .where_(@builder.val_int(8).not_in_subquery(sub.build_statement()))
    .build()
  assert_eq(q.sql, "SELECT $1 AS \"marker\" WHERE $2 NOT IN (WITH \"seed\" AS (SELECT ($3 + 0) AS \"id\") SELECT \"id\" FROM \"seed\" WHERE (\"id\" > $4))")
  assert_eq(q.params, [@ast.Int(9), @ast.Int(8), @ast.Int(7), @ast.Int(3)])
}

///|
test "EXISTS subquery retains WITH and surrounding parameter order" {
  let seed = @builder.select()
    .expr_as(@builder.val_int(7).add(@builder.raw("0")), "id")
  let sub = @builder.select()
    .with_("seed", seed)
    .column("id")
    .from("seed")
    .where_(@builder.col("id").gt(@builder.val_int(3)))
  let q = @builder.select()
    .expr_as(@builder.val_int(9), "marker")
    .where_(@builder.exists_(sub))
    .build()
  assert_eq(q.sql, "SELECT $1 AS \"marker\" WHERE EXISTS (WITH \"seed\" AS (SELECT ($2 + 0) AS \"id\") SELECT \"id\" FROM \"seed\" WHERE (\"id\" > $3))")
  assert_eq(q.params, [@ast.Int(9), @ast.Int(7), @ast.Int(3)])
}

///|
test "NOT EXISTS subquery retains WITH and surrounding parameter order" {
  let seed = @builder.select()
    .expr_as(@builder.val_int(7).add(@builder.raw("0")), "id")
  let sub = @builder.select()
    .with_("seed", seed)
    .column("id")
    .from("seed")
    .where_(@builder.col("id").gt(@builder.val_int(20)))
  let q = @builder.select()
    .expr_as(@builder.val_int(9), "marker")
    .where_(@builder.not_exists(sub))
    .build()
  assert_eq(q.sql, "SELECT $1 AS \"marker\" WHERE NOT EXISTS (WITH \"seed\" AS (SELECT ($2 + 0) AS \"id\") SELECT \"id\" FROM \"seed\" WHERE (\"id\" > $3))")
  assert_eq(q.params, [@ast.Int(9), @ast.Int(7), @ast.Int(20)])
}
