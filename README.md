# moonbit-sql

A PostgreSQL query builder for MoonBit. Published as `ash1day/sql`.

This README describes `0.2.0`. The `0.1.0` release does not include the
composition fixes and legacy package removal below.

## Changes in 0.2.0

- **Breaking:** remove `pg` and `decode` from the module and drop their dependencies.
  Use `ast` + `builder` with an application-owned driver adapter; see
  [migration](#migrating-from-pg-and-decode). Old source and tests remain in `legacy/`.
- Preserve nested WITH clauses, set-operation grouping, and operand-local clauses.
- Preserve GROUP BY parameter identities across SELECT, HAVING, and ORDER BY
  without merging unrelated literal parameters.
- Capture independent AST snapshots when composing queries.
- Add a node-postgres example, execution tests, and CI for the pinned toolchain.

## Scope

The maintained core is `ast` + `builder`: compose PostgreSQL queries and obtain
`CompiledQuery { sql, params }`. Your database driver owns connections,
transactions, parameter binding, and result decoding.

- SELECT / INSERT / UPDATE / DELETE
- Quoted identifiers and separate `$1`, `$2`, ... parameters
- Subqueries, CTEs, set operations, upsert, CASE, and window functions
- Pure MoonBit core, tested on JS, Wasm, Wasm GC, and native

This is a query builder, not an ORM or a schema type checker. Column names and
SQL expression types are not checked against your database at compile time.
`raw()` inserts trusted SQL verbatim; never use it for untrusted input.

The old `pg` and `decode` packages are **removed from this module's build**.
Their source and tests are archived in [legacy/](legacy/README.md); see
[migration](#migrating-from-pg-and-decode) before updating an application that imports them.

## Installation

```bash
moon add ash1day/sql
```

Declare only the core packages in your `moon.pkg.json` (also supported by the pinned toolchain):

```json
{
  "import": [
    "ash1day/sql/ast",
    "ash1day/sql/builder"
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

// q.sql    => SELECT "id", "name", "email" FROM "users" WHERE ("active" = $1) ORDER BY "name" ASC LIMIT $2
// q.params => [Bool(true), Int(20)]
assert_eq(q.params, [@ast.Bool(true), @ast.Int(20)])
```

---

## SELECT

```moonbit
// Basic
let _ = @builder.select()
  .columns(["id", "name"])      // specific columns
  .from("users")
  .build()

// All columns (*)
let _ = @builder.select().all().from("users").build()

// DISTINCT
let _ = @builder.select().distinct().columns(["country"]).from("users").build()

// FROM with alias
let _ = @builder.select().all().from_as("users", "u").build()

// FROM with schema
let _ = @builder.select().all().from_schema("public", "users").build()

// Single column
let _ = @builder.select().column("id").from("users").build()

// Expression with alias
let _ = @builder.select()
  .expr_as(@builder.col("price").mul(@builder.val_int(2)), "double_price")
  .from("products")
  .build()

// table.*
let _ = @builder.select().table_all_columns("users").from("users").build()
```

### WHERE

Multiple `.where_()` calls are combined with AND:

```moonbit
let _ = @builder.select()
  .all()
  .from("users")
  .where_(@builder.col("age").gte(@builder.val_int(18)))
  .where_(@builder.col("active").eq(@builder.val_bool(true)))
  .build()
// WHERE (("age" >= $1) AND ("active" = $2))
```

### JOIN

```moonbit
let _ = @builder.select()
  .expr(@builder.table_col("orders", "id"))
  .expr(@builder.table_col("users", "name"))
  .from("orders")
  .left_join("users", @builder.table_col("orders", "user_id").eq(@builder.table_col("users", "id")))
  .build()

// With alias
let _ = @builder.select()
  .all()
  .from("orders")
  .left_join_as("users", "u", @builder.table_col("orders", "user_id").eq(@builder.table_col("u", "id")))
  .build()
```

Available joins: `join` (INNER), `left_join`, `right_join`, `full_join`, `cross_join` — each has an `_as` variant for aliases.

### GROUP BY / HAVING

```moonbit
let _ = @builder.select()
  .columns(["department"])
  .expr_as(@builder.func("COUNT", [@builder.asterisk()]), "cnt")
  .from("employees")
  .group_by("department")
  .having(@builder.func("COUNT", [@builder.asterisk()]).gt(@builder.val_int(5)))
  .build()
```

### ORDER BY / LIMIT / OFFSET

```moonbit
let _ = @builder.select()
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
let _ = @builder.insert_into("users")
  .columns(["name", "email"])
  .values([@builder.val_str("Alice"), @builder.val_str("alice@example.com")])
  .build()

// Multi-row
let _ = @builder.insert_into("users")
  .columns(["name", "email"])
  .values([@builder.val_str("Alice"), @builder.val_str("alice@example.com")])
  .values([@builder.val_str("Bob"),   @builder.val_str("bob@example.com")])
  .build()

// RETURNING
let _ = @builder.insert_into("users")
  .columns(["name"])
  .values([@builder.val_str("Carol")])
  .returning(["id", "created_at"])
  .build()
```

`.build()` raises `BuildError::EmptyValues` if no rows were added.

---

## UPDATE

```moonbit
let _ = @builder.update("users")
  .set("name", @builder.val_str("Bob"))
  .set("active", @builder.val_bool(false))
  .where_(@builder.col("id").eq(@builder.val_int(42)))
  .returning(["id", "name"])
  .build()
```

`.build()` raises `BuildError::EmptyAssignments` if no `.set()` calls were made.

---

## DELETE

```moonbit
let _ = @builder.delete_from("users")
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
| `func("UPPER", [col("name")])` | Function call (raises on invalid name) |
| `asterisk()` | `*` |
| `window_func(...)` | Window function (see below) |
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

let _ = @builder.select().all().from_sub(sub, "active_users").build()
// SELECT * FROM (SELECT "id", "name" FROM "users" WHERE ("active" = $1)) AS "active_users"

// NOT IN subquery
let banned = @builder.select().columns(["user_id"]).from("bans")
let _ = @builder.select()
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

let _ = @builder.select()
  .with_("active_users", active)
  .all()
  .from("active_users")
  .build()
// WITH "active_users" AS (SELECT "id", "name" FROM "users" WHERE ("active" = $1))
// SELECT * FROM "active_users"
```

### Set Operations

```moonbit
let _ = @builder.select().columns(["id"]).from("admins")
  .union(@builder.select().columns(["id"]).from("moderators"))
  .build()
// SELECT "id" FROM "admins" UNION SELECT "id" FROM "moderators"
```

Available: `union`, `union_all`, `intersect`, `intersect_all`, `except_`, `except_all`.

### Upsert (INSERT ON CONFLICT)

```moonbit
let _ = @builder.insert_into("users")
  .columns(["id", "name", "email"])
  .values([@builder.val_int(1), @builder.val_str("Alice"), @builder.val_str("alice@example.com")])
  .on_conflict_do_update(["id"], [("name", @builder.table_col("excluded", "name"))])
  .build()
// INSERT INTO "users" ("id", "name", "email") VALUES ($1, $2, $3)
// ON CONFLICT ("id") DO UPDATE SET "name" = "excluded"."name"

// Do nothing on conflict
let _ = @builder.insert_into("users")
  .columns(["id", "name"])
  .values([@builder.val_int(1), @builder.val_str("Alice")])
  .on_conflict_do_nothing(["id"])
  .build()
```

### Window Functions

```moonbit
let _ = @builder.select()
  .expr_as(
    @builder.window_func(
      "ROW_NUMBER",
      [],
      partition_by=["department"],
      order_by=[("salary", @ast.Desc)]
    ),
    "rank"
  )
  .from("employees")
  .build()
// SELECT ROW_NUMBER() OVER (PARTITION BY "department" ORDER BY "salary" DESC) AS "rank"
// FROM "employees"
```

---

## Executing with a driver

Pass `q.sql` and converted `q.params` separately to your PostgreSQL driver's
parameterized query API. Do not substitute values into the SQL string.

The runnable [node-postgres example](examples/node-postgres.mjs) builds a dynamic
search in MoonBit, transfers `{ text, values }` as JSON, and calls:

```javascript
const result = await client.query({ text: q.sql, values: driverValues });
```

Its [MoonBit adapter](src/examples/node_postgres/main.mbt) encodes non-null
parameters as strings, including Int64, and preserves SQL NULL as JSON null.
[node-postgres accepts text parameters](https://node-postgres.com/features/queries);
this avoids sending a large Int64 through JavaScript's lossy Number type.
Parameter types are inferred from the SQL context. Use an explicit cast in trusted
SQL when the context does not determine a type. Results retain the driver's types
(for example, node-postgres normally returns bigint as a string).

With an existing `users(id, name, age)` table:

```bash
npm ci
DATABASE_URL=postgresql://localhost/mydb node examples/node-postgres.mjs
```

For native applications, use the same `CompiledQuery` boundary with a maintained
PostgreSQL driver such as [moonbit-community/postgres](https://github.com/moonbit-community/postgres.mbt).
Map every `ast.Value` variant to the driver's parameter representation, preserving
NULL, Int64 precision, and strings. This repository's executable adapter covers
node-postgres; it does not provide a new native connection abstraction.

## Composition semantics

- **Builders are mutable.** Chained calls modify the same builder. Construct a
  fresh builder when branching a query; assigning it to another variable does
  not copy it.
- **`build_statement()` takes a deep snapshot.** Subqueries, CTEs and set operands
  also capture snapshots. Later changes to the source builder or expression
  arrays do not change a captured statement.
- **Set operations chain left-to-right.** `a.union(b).intersect(c)` means
  `(a UNION b) INTERSECT c`. Clauses on the outer builder apply to the combined
  result. Clauses inside `b` apply only to that operand.
- **Nested WITH clauses are retained**, including in INSERT ... SELECT.
- **GROUP BY expressions share parameter identities within one SELECT.**
  Structurally equal grouping expressions reuse placeholders in SELECT (including
  subexpressions), GROUP BY, HAVING, and ORDER BY, even if absent from the SELECT
  list. Bare literal values are excluded: equal values in unrelated type contexts
  remain separate parameters. This reuse does not cross subquery boundaries;
  correlated subqueries referencing parameterized outer grouping expressions are
  not supported by this reuse mechanism.
- **Identifiers are literal names.** `col("users.id")` names a single column
  containing a dot. Use `table_col("users", "id")` for qualification and
  `.expr(...)` to select it. String-based `columns`, `group_by`, `order_by` and
  `returning` follow the same literal-name rule.

## Migrating from pg and decode

This update removes `ash1day/sql/pg` and `ash1day/sql/decode` from the module's
build and removes their dependencies, `moonbitlang/async` and `mattn/postgres`.
**This is a breaking change for applications importing either legacy package.**
Import only `ast` and `builder`, execute `CompiledQuery` through your chosen
driver, and decode the driver's rows; see [driver integration](#executing-with-a-driver).
The published `0.1.0` remains unchanged. Defer upgrading if you still depend on
those packages, while migrating away from their limitations below.

The source and all legacy tests are retained in [legacy/](legacy/README.md) for
reference, outside the module's `src` root. They are not supported packages.
The previous plan to retain them with deprecation warnings was insufficient:
`moonbitlang/async@0.16.6` has parse errors with the pinned `moonc 0.10.14`,
including on native, and the mixed JS/native imports also fail target checks.
Legacy checks were last verified with `moonc v0.8.2+3382e0600`.

Known legacy limitations remain:

- Native parameter substitution also rewrites `$N` inside quoted SQL. It is not
  protocol-level binding, and its escaping must not be treated as a general
  injection-safety guarantee.
- The native dependency loses NULL versus empty-string information and mishandles
  non-ASCII text. Its value heuristics also turn text such as `"00123"` and `"t"`
  into integers or booleans.
- The JS adapter sends Int64 through JSON numbers, losing precision above 2^53.
  Neither adapter reliably produces the `ColumnValue::Int64` variant.

## Development

The core's supported toolchain is pinned in [.moonbit-version](.moonbit-version):
`moonc v0.10.14+7d59c7ec9` (moon `0.1.20260920`). CI installs that exact version.
Older toolchains are not the core compatibility target. Install the pin using the
[official installer](https://www.moonbitlang.com/download/):

```bash
curl -fsSL https://cli.moonbitlang.com/install/unix.sh -o /tmp/install-moon.sh
bash /tmp/install-moon.sh "$(cat .moonbit-version)"
moon update
moon check --target all
moon test --target all
python3 scripts/check-readme.py
```

The module has no third-party MoonBit dependencies. `ast` and `builder` require
no PostgreSQL server, libpq, or npm packages. Whole-module checks and tests cover
all four targets; the archived legacy packages are outside the source root.
Legacy Show implementations remain for source compatibility and can produce
deprecation warnings on the pinned compiler.

For execution tests, use a PostgreSQL database where your user can create temporary
tables. Tests use a transaction and temporary tables, then roll back:

```bash
npm ci
DATABASE_URL=postgresql://localhost/postgres npm run test:postgres
```

These tests execute the generated queries through node-postgres and cover nested
CTEs, INSERT ... SELECT, set-operation scope, GROUP BY parameters (including
unselected and nested expressions), HAVING/ORDER BY parameter type independence,
AST snapshots, qualified JOINs, upsert, NULL, Unicode, and large integer transport.

## Inspiration

- [sea-query](https://github.com/SeaQL/sea-query) (Rust) — ADT-based AST and expression design
- [squirrel](https://github.com/Masterminds/squirrel) (Go) — Builder API design

## License

MIT
