import assert from 'node:assert/strict';
import pg from 'pg';
import { loadQueries } from '../examples/node-postgres.mjs';

const queries = loadQueries();
const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
try {
  await client.connect();
  await client.query('BEGIN');
  await client.query('CREATE TEMP TABLE users (id integer PRIMARY KEY, name text, age integer)');
  await client.query("INSERT INTO users VALUES (1, 'Alice', 30), (2, 'Bob', 17), (3, 'Carol', 30)");
  await client.query('CREATE TEMP TABLE selected_ids (id integer)');
  await client.query('CREATE TEMP TABLE events (created_at timestamptz)');
  await client.query("INSERT INTO events VALUES ('2025-12-31T00:00:00Z'), ('2026-01-02T00:00:00Z')");
  const rows = async (name) => (await client.query(queries[name])).rows;
  assert.deepEqual(await rows('search'), [{ id: 1, name: 'Alice' }, { id: 3, name: 'Carol' }]);
  assert.deepEqual(await rows('nested_cte'), [{ id: 7 }]);
  assert.deepEqual(await rows('insert_cte'), [{ id: 7 }]);
  assert.deepEqual(await rows('order_group'), [{ count: '2' }, { count: '1' }]);
  assert.deepEqual(await rows('scalar_cte'), [{ marker: '9', id: 7 }]);
  for (const name of ['in_cte', 'not_in_cte', 'exists_cte', 'not_exists_cte']) {
    assert.deepEqual(await rows(name), [{ marker: '9' }], name);
  }
  assert.deepEqual(await rows('union_limit'), [{ id: 0 }, { id: 3 }]);
  assert.deepEqual(await rows('mixed_set'), [{ id: '2' }]);
  assert.deepEqual(await rows('nested_set'), [{ id: '1' }]);
  assert.deepEqual((await rows('group')).sort((a, b) => a.bucket - b.bucket), [
    { bucket: 27, count: '1' }, { bucket: 40, count: '2' },
  ]);
  assert.deepEqual(await rows('group_unselected'), [{ count: '2' }]);
  assert.deepEqual((await rows('group_subexpression')).sort((a, b) => a.dbl - b.dbl), [
    { dbl: 54, count: '1' }, { dbl: 80, count: '2' },
  ]);
  assert.deepEqual(await rows('order_literal'), [
    { label: '2026-01-01', created_at: new Date('2025-12-31T00:00:00Z') },
    { label: '2026-01-01', created_at: new Date('2026-01-02T00:00:00Z') },
  ]);
  assert.deepEqual(await rows('having_literal'), []);
  await client.query("DELETE FROM events WHERE created_at < '2026-01-01T00:00:00Z'");
  assert.deepEqual(await rows('having_literal'), [
    { label: '2026-01-01', first: new Date('2026-01-02T00:00:00Z') },
  ]);
  assert.deepEqual(await rows('snapshot'), [{ id: 1 }]);
  assert.deepEqual(await rows('join'), [
    { id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }, { id: 3, name: 'Carol' },
  ]);
  assert.deepEqual(await rows('upsert'), [{ name: 'Updated' }]);
  assert.deepEqual(await rows('values'), [{ large: '9007199254740993', text: "日本語 '$1'", missing: null }]);
  console.log(`PostgreSQL: ${Object.keys(queries).length} query scenarios passed`);
} finally {
  await client.query('ROLLBACK').catch(() => {});
  await client.end();
}
