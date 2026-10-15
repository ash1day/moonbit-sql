///|
/// The application owns this adapter. PostgreSQL accepts text parameters;
/// encoding Int64 as a JSON string avoids JavaScript Number precision loss.
fn to_pg_query(query : @ast.CompiledQuery) -> Json {
  let values = query.params.map(fn(value) {
    match value {
      Null => Json::null()
      Bool(v) => Json::string(if v { "true" } else { "false" })
      Int(v) => Json::string(v.to_string())
      Int64(v) => Json::string(v.to_string())
      Double(v) => Json::string(v.to_string())
      String(v) => Json::string(v)
    }
  })
  Json::object({
    "text": Json::string(query.sql),
    "values": Json::array(values),
  })
}

///|
/// A dynamic search: only supplied filters become WHERE predicates.
fn search_users(min_age : Int32?, name : String?) -> @ast.CompiledQuery raise {
  let query = @builder.select().columns(["id", "name"]).from("users")
  if min_age is Some(age) {
    ignore(query.where_(@builder.col("age").gte(@builder.val_int(age))))
  }
  if name is Some(name) {
    ignore(query.where_(@builder.col("name").eq(@builder.val_str(name))))
  }
  query.order_by("id", @ast.Asc).build()
}

///|
/// These queries are also executed by scripts/test-postgres.mjs. They exercise
/// composition against PostgreSQL, beyond checking generated SQL strings.
fn example_queries() -> Map[String, Json] raise {
  let seed = @builder.select().expr_as(
    @builder.val_int(7).add(@builder.raw("0")),
    "id",
  )
  let cte = @builder.select().with_("seed", seed).column("id").from("seed")
  let bucket = @builder.col("age").add(@builder.val_int(10))
  let rhs = @builder.select()
    .column("id")
    .from("users")
    .order_by("id", @ast.Desc)
    .limit(1)
  let inner_set = @builder.select()
    .expr(@builder.val_int(2))
    .except_(@builder.select().expr(@builder.val_int(2)))
  let choices = [@builder.val_int(1)]
  let source = @builder.select()
    .column("id")
    .from("users")
    .where_(@builder.col("id").in_list(choices))
  let snapshot = source.build_statement()
  choices.push(@builder.val_int(2))
  ignore(source.column("name"))
  let ordered = @builder.select()
    .expr_as(@builder.val_str("2026-01-01"), "label")
    .column("created_at")
    .from("events")
    .build_statement()
  ordered.order_by.push({
    expr: @builder.col("created_at").gt(@builder.val_str("2026-01-01")),
    order: @ast.Asc,
  })
  let ordered_group = @builder.select()
    .expr_as(@builder.func("COUNT", [@builder.asterisk()]), "count")
    .from("users")
    .group_by_expr(bucket)
    .build_statement()
  ordered_group.order_by.push({
    expr: bucket.add(@builder.val_int(10)),
    order: @ast.Desc,
  })
  let filtered_cte = @builder.select()
    .with_("seed", seed)
    .column("id")
    .from("seed")
    .where_(@builder.col("id").gt(@builder.val_int(3)))
  let empty_cte = @builder.select()
    .with_("seed", seed)
    .column("id")
    .from("seed")
    .where_(@builder.col("id").gt(@builder.val_int(20)))
  {
    "order_group": to_pg_query(@ast.render_select(ordered_group)),
    "scalar_cte": to_pg_query(
      @builder.select()
      .expr_as(@builder.val_int(9), "marker")
      .expr_as(@ast.Subquery(filtered_cte.build_statement()), "id")
      .build(),
    ),
    "in_cte": to_pg_query(
      @builder.select()
      .expr_as(@builder.val_int(9), "marker")
      .where_(@builder.val_int(7).in_subquery(filtered_cte.build_statement()))
      .build(),
    ),
    "not_in_cte": to_pg_query(
      @builder.select()
      .expr_as(@builder.val_int(9), "marker")
      .where_(
        @builder.val_int(8).not_in_subquery(filtered_cte.build_statement()),
      )
      .build(),
    ),
    "exists_cte": to_pg_query(
      @builder.select()
      .expr_as(@builder.val_int(9), "marker")
      .where_(@builder.exists_(filtered_cte))
      .build(),
    ),
    "not_exists_cte": to_pg_query(
      @builder.select()
      .expr_as(@builder.val_int(9), "marker")
      .where_(@builder.not_exists(empty_cte))
      .build(),
    ),
    "order_literal": to_pg_query(@ast.render_select(ordered)),
    "having_literal": to_pg_query(
      @builder.select()
      .expr_as(@builder.val_str("2026-01-01"), "label")
      .expr_as(@builder.func("MIN", [@builder.col("created_at")]), "first")
      .from("events")
      .having(
        @builder.func("MIN", [@builder.col("created_at")]).gt(
          @builder.val_str("2026-01-01"),
        ),
      )
      .build(),
    ),
    "group_unselected": to_pg_query(
      @builder.select()
      .expr_as(@builder.func("COUNT", [@builder.asterisk()]), "count")
      .from("users")
      .group_by_expr(bucket)
      .having(bucket.gt(@builder.val_int(30)))
      .build(),
    ),
    "group_subexpression": to_pg_query(
      @builder.select()
      .expr_as(bucket.mul(@builder.val_int(2)), "dbl")
      .expr_as(@builder.func("COUNT", [@builder.asterisk()]), "count")
      .from("users")
      .group_by_expr(bucket)
      .build(),
    ),
    "search": to_pg_query(search_users(Some(18), None)),
    "nested_cte": to_pg_query(
      @builder.select().all().from_sub(cte, "s").build(),
    ),
    "insert_cte": to_pg_query(
      @builder.insert_into("selected_ids")
      .columns(["id"])
      .from_select(cte)
      .returning(["id"])
      .build(),
    ),
    "union_limit": to_pg_query(
      @builder.select()
      .expr_as(@builder.val_int(0), "id")
      .union(rhs)
      .order_by("id", @ast.Asc)
      .build(),
    ),
    "mixed_set": to_pg_query(
      @builder.select()
      .expr_as(@builder.val_int(1), "id")
      .union(@builder.select().expr(@builder.val_int(2)))
      .intersect(@builder.select().expr(@builder.val_int(2)))
      .build(),
    ),
    "nested_set": to_pg_query(
      @builder.select()
      .expr_as(@builder.val_int(1), "id")
      .except_(inner_set)
      .build(),
    ),
    "group": to_pg_query(
      @builder.select()
      .expr_as(bucket, "bucket")
      .expr_as(@builder.func("COUNT", [@builder.asterisk()]), "count")
      .from("users")
      .group_by_expr(bucket)
      .having(bucket.gt(@builder.val_int(0)))
      .build(),
    ),
    "snapshot": to_pg_query(@ast.render_select(snapshot)),
    "join": to_pg_query(
      @builder.select()
      .expr(@builder.table_col("u", "id"))
      .expr(@builder.table_col("o", "name"))
      .from_as("users", "u")
      .join_as(
        "users",
        "o",
        @builder.table_col("u", "id").eq(@builder.table_col("o", "id")),
      )
      .order_by("id", @ast.Asc)
      .build(),
    ),
    "upsert": to_pg_query(
      @builder.insert_into("users")
      .columns(["id", "name", "age"])
      .values([
        @builder.val_int(1),
        @builder.val_str("Updated"),
        @builder.val_int(30),
      ])
      .on_conflict_do_update(["id"], [
        ("name", @builder.table_col("excluded", "name")),
      ])
      .returning(["name"])
      .build(),
    ),
    "values": to_pg_query(
      @builder.select()
      .expr_as(@builder.val_int64(9007199254740993L), "large")
      .expr_as(@builder.val_str("日本語 '$1'"), "text")
      .expr_as(@builder.val_null(), "missing")
      .build(),
    ),
  }
}

///|
fn main {
  let queries = example_queries() catch {
    error => {
      println(error)
      panic()
    }
  }
  println(Json::object(queries).stringify())
}
