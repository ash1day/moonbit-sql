import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

export function loadQueries() {
  const output = execFileSync('moon', ['run', 'src/examples/node_postgres', '--target', 'js'], {
    cwd: fileURLToPath(new URL('..', import.meta.url)),
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'inherit'],
  });
  return JSON.parse(output);
}

// Run against an application database containing users(id, name, age).
// The driver receives SQL and values separately and owns result decoding.
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
  try {
    await client.connect();
    const result = await client.query(loadQueries().search);
    console.log(result.rows);
  } finally {
    await client.end();
  }
}
