# moonbit-sql

A SQL query builder for MoonBit with parameterized queries and PostgreSQL support.

## Features

- Builder DSL for SELECT / INSERT / UPDATE / DELETE
- Parameterized queries (`$1`, `$2`, ...) — safe from SQL injection by default
- PostgreSQL connection on both **JS target** (Node.js via node-postgres) and **native target** (libpq via mattn/postgres)
- Type-safe row decoding helpers
- Advanced queries: subqueries, CTEs (WITH), UNION / INTERSECT / EXCEPT, upsert (INSERT ON CONFLICT), window functions

## Prerequisites

**JS target:** Node.js + `pg` npm package

```bash
npm install pg
```

**Native target:** libpq. On macOS with Homebrew:

```bash
brew install postgresql@14
export C_INCLUDE_PATH="/opt/homebrew/include/postgresql@14"
```

## Installation

```bash
moon add ash1day/sql
```

Declare the packages you need in your `moon.pkg.json`:

```json
{
  "import": [
    "ash1day/sql/ast",
    "ash1day/sql/builder",
    "ash1day/sql/pg",
    "ash1day/sql/decode"
  ]
}
```

## Quick Start

```moonbit
let q = @builder.select()
  .columns(["id", "name", "email"])
  .from("users")
  .where_(@builder.col("active").eq(@builder.val_bool(true)))
  .order_by("name", @ast.Asc)
  .limit(20)
  .build()

// q.sql    => SELECT "id", "name", "email" FROM "users" WHERE "active" = $1 ORDER BY "name" ASC LIMIT $2
// q.params => [Bool(true), Int(20)]
```

---

## SELECT

```moonbit
// Basic
@builder.select()
  .columns(["id", "name"])      // specific columns
  .from("users")
  .build()

// All columns (*)
@builder.select().all().from("users").build()

// DISTINCT
@builder.select().distinct().columns(["country"]).from("users").build()

// FROM with alias
@builder.select().all().from_as("users", "u").build()

// FROM with schema
@builder.select().all().from_schema("public", "users").build()

// Single column
@builder.select().column("id").from("users").build()

// Expression with alias
@builder.select()
  .expr_as(@builder.col("price").mul(@builder.val_int(2)), "double_price")
  .from("products")
  .build()

// table.*
@builder.select().table_all_columns("users").from("users").build()
```

### WHERE

Multiple `.where_()` calls are combined with AND:

```moonbit
@builder.select()
  .all()
  .from("users")
  .where_(@builder.col("age").gte(@builder.val_int(18)))
  .where_(@builder.col("active").eq(@builder.val_bool(true)))
  .build()
// WHERE "age" >= $1 AND "active" = $2
```

### JOIN

```moonbit
@builder.select()
  .columns(["orders.id", "users.name"])
  .from("orders")
  .left_join("users", @builder.table_col("orders", "user_id").eq(@builder.table_col("users", "id")))
  .build()

// With alias
@builder.select()
  .all()
  .from("orders")
  .left_join_as("users", "u", @builder.table_col("orders", "user_id").eq(@builder.table_col("u", "id")))
  .build()
```

Available joins: `join` (INNER), `left_join`, `right_join`, `full_join`, `cross_join` — each has an `_as` variant for aliases.

### GROUP BY / HAVING

```moonbit
@builder.select()
  .columns(["department"])
  .expr_as(@builder.func("COUNT", [@builder.asterisk()])!, "cnt")
  .from("employees")
  .group_by("department")
  .having(@builder.func("COUNT", [@builder.asterisk()])!.gt(@builder.val_int(5)))
  .build()
```

### ORDER BY / LIMIT / OFFSET

```moonbit
@builder.select()
  .all()
  .from("products")
  .order_by("price", @ast.Desc)
  .limit(10)
  .offset(20)
  .build()
```

---

## INSERT

```moonbit
// Single row
@builder.insert_into("users")
  .columns(["name", "email"])
  .values([@builder.val_str("Alice"), @builder.val_str("alice@example.com")])
  .build()!

// Multi-row
@builder.insert_into("users")
  .columns(["name", "email"])
  .values([@builder.val_str("Alice"), @builder.val_str("alice@example.com")])
  .values([@builder.val_str("Bob"),   @builder.val_str("bob@example.com")])
  .build()!

// RETURNING
@builder.insert_into("users")
  .columns(["name"])
  .values([@builder.val_str("Carol")])
  .returning(["id", "created_at"])
  .build()!
```

`.build()` raises `BuildError::EmptyValues` if no rows were added.

---

## UPDATE

```moonbit
@builder.update("users")
  .set("name", @builder.val_str("Bob"))
  .set("active", @builder.val_bool(false))
  .where_(@builder.col("id").eq(@builder.val_int(42)))
  .returning(["id", "name"])
  .build()!
```

`.build()` raises `BuildError::EmptyAssignments` if no `.set()` calls were made.

---

## DELETE

```moonbit
@builder.delete_from("users")
  .where_(@builder.col("id").in_list([@builder.val_int(1), @builder.val_int(2), @builder.val_int(3)]))
  .returning(["id"])
  .build()
```

---

## Expression Helpers

| Function | Description |
|----------|-------------|
| `col("name")` | Column reference: `"name"` |
| `table_col("t", "col")` | Table-qualified column: `"t"."col"` |
| `val_int(42)` | Integer literal |
| `val_str("hello")` | String literal |
| `val_bool(true)` | Boolean literal |
| `val_double(3.14)` | Double literal |
| `val_int64(9999999999L)` | Int64 literal |
| `val_null()` | NULL |
| `func("UPPER", [col("name")])!` | Function call (raises on invalid name) |
| `asterisk()` | `*` |
| `window_func(...)!` | Window function (see below) |
| `in_sub(expr, sub_builder)` | `expr IN (subquery)` |
| `not_in_sub(expr, sub_builder)` | `expr NOT IN (subquery)` |

## Expression Operators

Operators are methods on `Expr`:

| Method | SQL |
|--------|-----|
| `.eq(other)` | `= other` |
| `.ne(other)` | `<> other` |
| `.gt(other)` | `> other` |
| `.lt(other)` | `< other` |
| `.gte(other)` | `>= other` |
| `.lte(other)` | `<= other` |
| `.and_(other)` | `AND other` |
| `.or_(other)` | `OR other` |
| `.like("pat%")` | `LIKE 'pat%'` |
| `.is_null()` | `IS NULL` |
| `.is_not_null()` | `IS NOT NULL` |
| `.in_list([...])` | `IN (...)` |
| `.not_in_list([...])` | `NOT IN (...)` |
| `.between(low, high)` | `BETWEEN low AND high` |
| `.not_between(low, high)` | `NOT BETWEEN low AND high` |
| `.add(other)` | `+ other` |
| `.sub_(other)` | `- other` |
| `.mul(other)` | `* other` |
| `.div(other)` | `/ other` |
| `.not_()` | `NOT expr` |
| `.neg()` | `-expr` |

---

## Advanced Features

### Subqueries

```moonbit
// FROM subquery
let sub = @builder.select()
  .columns(["id", "name"])
  .from("users")
  .where_(@builder.col("active").eq(@builder.val_bool(true)))

@builder.select().all().from_sub(sub, "active_users").build()
// SELECT * FROM (SELECT "id", "name" FROM "users" WHERE "active" = $1) AS "active_users"

// NOT IN subquery
let banned = @builder.select().columns(["user_id"]).from("bans")
@builder.select()
  .all()
  .from("users")
  .where_(@builder.not_in_sub(@builder.col("id"), banned))
  .build()
```

### CTEs (WITH)

```moonbit
let active = @builder.select()
  .columns(["id", "name"])
  .from("users")
  .where_(@builder.col("active").eq(@builder.val_bool(true)))

@builder.select()
  .with_("active_users", active)
  .all()
  .from("active_users")
  .build()
// WITH "active_users" AS (SELECT "id", "name" FROM "users" WHERE "active" = $1)
// SELECT * FROM "active_users"
```

### Set Operations

```moonbit
@builder.select().columns(["id"]).from("admins")
  .union(@builder.select().columns(["id"]).from("moderators"))
  .build()
// SELECT "id" FROM "admins" UNION SELECT "id" FROM "moderators"
```

Available: `union`, `union_all`, `intersect`, `intersect_all`, `except_`, `except_all`.

### Upsert (INSERT ON CONFLICT)

```moonbit
@builder.insert_into("users")
  .columns(["id", "name", "email"])
  .values([@builder.val_int(1), @builder.val_str("Alice"), @builder.val_str("alice@example.com")])
  .on_conflict_do_update(["id"], [("name", @builder.col("excluded.name"))])
  .build()!
// INSERT INTO "users" ("id", "name", "email") VALUES ($1, $2, $3)
// ON CONFLICT ("id") DO UPDATE SET "name" = "excluded"."name"

// Do nothing on conflict
@builder.insert_into("users")
  .columns(["id", "name"])
  .values([@builder.val_int(1), @builder.val_str("Alice")])
  .on_conflict_do_nothing(["id"])
  .build()!
```

### Window Functions

```moonbit
@builder.select()
  .expr_as(
    @builder.window_func(
      "ROW_NUMBER",
      [],
      partition_by=["department"],
      order_by=[("salary", @ast.Desc)]
    )!,
    "rank"
  )
  .from("employees")
  .build()
// SELECT ROW_NUMBER() OVER (PARTITION BY "department" ORDER BY "salary" DESC) AS "rank"
// FROM "employees"
```

---

## PostgreSQL Connection

### JS Target (Node.js)

```moonbit
async fn main {
  let conn = @pg.Connection::connect("postgresql://user:pass@localhost/mydb").wait()!
  let q = @builder.select().all().from("users").build()
  let rows = conn.query(q).wait()!
  conn.close().wait()
}
```

### Native Target (libpq)

```moonbit
fn main {
  let conn = @pg.Connection::connect("postgresql://user:pass@localhost/mydb")!
  let q = @builder.select().all().from("users").build()
  let rows = conn.query(q)!
  conn.close()
}
```

> **Note:** The native target inlines parameters as SQL literals rather than using protocol-level parameterized binding. String values are escaped with single-quote doubling (`'` → `''`).

### Error Types

```moonbit
pub suberror PgError {
  ConnectionError(String)
  QueryError(String)
  ParseError(String)
}
```

---

## Row Decoding

The `decode` package provides typed accessors for `Row` values returned by `pg.query`:

```moonbit
let rows = conn.query(q)!
for row in rows {
  let id    = @decode.get_int(row, "id")!             // Int!DecodeError
  let name  = @decode.get_str(row, "name")!           // String!DecodeError
  let bio   = @decode.get_optional_str(row, "bio")!   // String?!DecodeError
  let score = @decode.get_double(row, "score")!       // Double!DecodeError
}
```

Available decoders:

| Function | Return type |
|----------|------------|
| `get_str(row, col)` | `String!DecodeError` |
| `get_int(row, col)` | `Int!DecodeError` |
| `get_bool(row, col)` | `Bool!DecodeError` |
| `get_double(row, col)` | `Double!DecodeError` |
| `get_int64(row, col)` | `Int64!DecodeError` |
| `get_optional_str(row, col)` | `String?!DecodeError` |
| `get_optional_int(row, col)` | `Int?!DecodeError` |
| `get_optional_bool(row, col)` | `Bool?!DecodeError` |
| `get_optional_double(row, col)` | `Double?!DecodeError` |
| `get_optional_int64(row, col)` | `Int64?!DecodeError` |

`get_optional_*` returns `None` for SQL NULL; non-optional variants raise `DecodeError::NullValue`.

```moonbit
pub suberror DecodeError {
  ColumnNotFound(String)
  TypeMismatch(String, String)
  NullValue(String)
}
```

---

## Known Limitations

- **Column names are strings.** Compile-time schema validation (like kysely's type-level column checking) is not available in MoonBit.
- **`Int64` is never returned from query results.** The JS target converts all numeric values via JavaScript's `Number` (max safe integer: 2⁵³), so large integers become `Int` or `Double`. The native target uses heuristic string parsing that only attempts `Int` and `Double`. Use `get_int64` / `get_optional_int64` only when you are certain the value fits in a 32-bit integer and the driver returns it as `Int`.
- **Native target: heuristic type detection.** Column values are returned as strings by libpq and converted heuristically. The single-character strings `"t"` and `"f"` are always interpreted as boolean `true`/`false`, which can conflict with actual string columns containing those values.
- **Native target uses literal inlining.** Parameters are inlined as SQL literals rather than sent as protocol-level parameters. This is safe for all supported value types but differs from the JS target's behavior.
- **SELECT + GROUP BY duplicate parameters.** When the same `Expr` object appears in both the SELECT list and GROUP BY clause, the renderer assigns separate `$N` placeholders to each occurrence. PostgreSQL rejects queries where a GROUP BY expression contains `$N` parameters that differ from the SELECT list. **Workaround:** wrap the expression in a subquery with an alias, then GROUP BY the alias column name in the outer query.

  ```moonbit
  // Problem: same Expr in SELECT and GROUP BY produces duplicate $N params
  // let expr = @builder.func("TO_CHAR", [...])!
  // .expr_as(expr, "label").group_by_expr(expr) // PostgreSQL error

  // Solution: use a subquery with alias
  let inner = @builder.select()
    .expr_as(@builder.func("TO_CHAR", [@builder.col("created_at"), @builder.val_str("YYYY-MM")])!, "month")
    .columns(["amount"])
    .from("orders")

  @builder.select()
    .columns(["month"])
    .expr_as(@builder.func("SUM", [@builder.col("amount")])!, "total")
    .from_sub(inner, "sub")
    .group_by("month")
    .build()
  ```

## Inspiration

- [sea-query](https://github.com/SeaQL/sea-query) (Rust) — ADT-based AST and expression design
- [squirrel](https://github.com/Masterminds/squirrel) (Go) — Builder API design

## License

MIT
