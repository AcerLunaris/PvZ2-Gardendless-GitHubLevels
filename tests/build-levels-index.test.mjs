import test from 'node:test'
import assert from 'node:assert/strict'
import { execFileSync } from 'node:child_process'
import { mkdtemp, mkdir, readFile, rm, symlink, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { createHash } from 'node:crypto'

const script = fileURLToPath(new URL('../scripts/build-levels-index.mjs', import.meta.url))
const level = JSON.stringify({ objects: [{ objclass: 'LevelDefinition', objdata: { WrittenBy: '作者' } }] })

test('index preserves bytes, skips invalid files, excludes itself and handles updates/deletions', async () => {
  const cwd = await mkdtemp(join(tmpdir(), 'levels-index-'))
  const git = (...args) => execFileSync('git', args, { cwd, stdio: 'pipe' })
  const run = () => execFileSync(process.execPath, [script], { cwd, encoding: 'utf8', stdio: 'pipe' })
  try {
    git('init', '--quiet')
    await mkdir(join(cwd, '作者'))
    await writeFile(join(cwd, '作者/one.JSON'), level)
    await writeFile(join(cwd, 'broken.json'), '{')
    await writeFile(join(cwd, 'config.json'), '{}')
    await writeFile(join(cwd, 'encoding.json'), new Uint8Array([255]))
    await writeFile(join(cwd, 'levels-index.json'), '{}')
    await writeFile(join(cwd, 'untracked.json'), level)
    await symlink('作者/one.JSON', join(cwd, 'link.json'))
    git('add', '--', '作者/one.JSON', 'broken.json', 'config.json', 'encoding.json', 'levels-index.json', 'link.json')
    assert.deepEqual(JSON.parse(run()), { levels: 1, invalid: 4 })
    const first = await readFile(join(cwd, 'levels-index.json'), 'utf8')
    const index = JSON.parse(first)
    assert.deepEqual(index.levels, [{
      path: '作者/one.JSON',
      size: Buffer.byteLength(level),
      sha256: createHash('sha256').update(level).digest('hex'),
    }])
    assert.deepEqual(index.invalid, [
      { path: 'broken.json', reason: 'invalid-json-or-utf8' },
      { path: 'config.json', reason: 'level-definition-missing' },
      { path: 'encoding.json', reason: 'invalid-json-or-utf8' },
      { path: 'link.json', reason: 'not-a-regular-file' },
    ])
    run()
    assert.equal(await readFile(join(cwd, 'levels-index.json'), 'utf8'), first)
    await writeFile(join(cwd, 'broken.json'), level)
    git('rm', '--cached', '--', '作者/one.JSON')
    run()
    const updated = JSON.parse(await readFile(join(cwd, 'levels-index.json'), 'utf8'))
    assert.deepEqual(updated.levels.map(item => item.path), ['broken.json'])
    assert.equal(updated.invalid.length, 3)
  } finally {
    await rm(cwd, { recursive: true, force: true })
  }
})

test('oversized, deeply nested and nonfinite levels are excluded', async () => {
  const cwd = await mkdtemp(join(tmpdir(), 'levels-index-limits-'))
  try {
    execFileSync('git', ['init', '--quiet'], { cwd })
    await writeFile(join(cwd, 'large.json'), ' '.repeat(10_000_001))
    await writeFile(join(cwd, 'deep.json'), level.replace('"作者"', '['.repeat(65) + '0' + ']'.repeat(65)))
    await writeFile(join(cwd, 'infinite.json'), level.replace('"作者"', '1e999'))
    execFileSync('git', ['add', '.'], { cwd })
    execFileSync(process.execPath, [script], { cwd, stdio: 'pipe' })
    const index = JSON.parse(await readFile(join(cwd, 'levels-index.json'), 'utf8'))
    assert.deepEqual(index.levels, [])
    assert.deepEqual(index.invalid.map(item => item.reason), ['level-depth-limit', 'level-nonfinite-number', 'level-byte-limit'])
  } finally {
    await rm(cwd, { recursive: true, force: true })
  }
})
