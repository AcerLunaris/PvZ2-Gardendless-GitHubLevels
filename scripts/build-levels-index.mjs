import { execFileSync } from 'node:child_process'
import { lstat, readFile, writeFile } from 'node:fs/promises'
import { createHash } from 'node:crypto'

const paths = execFileSync('git', ['ls-files', '-z'], { encoding: 'utf8' })
  .split('\0')
  .filter(path => path.toLowerCase().endsWith('.json') && path !== 'levels-index.json')
  .sort()

const levels = []
const invalid = []
const reject = (path, reason) => invalid.push({ path, reason })

for (const path of paths) {
  const stat = await lstat(path)
  if (!stat.isFile()) {
    reject(path, 'not-a-regular-file')
    continue
  }
  if (stat.size > 10_000_000) {
    reject(path, 'level-byte-limit')
    continue
  }
  const bytes = await readFile(path)
  let data
  try {
    data = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes))
  } catch {
    reject(path, 'invalid-json-or-utf8')
    continue
  }
  if (!data || typeof data !== 'object' || Array.isArray(data) ||
      !Array.isArray(data.objects) ||
      !data.objects.some(object => object?.objclass === 'LevelDefinition')) {
    reject(path, 'level-definition-missing')
    continue
  }
  // Bound structure traversal without recursion or executing level content.
  const queue = [{ value: data, depth: 1 }]
  let reason
  for (let i = 0; i < queue.length; i++) {
    const { value, depth } = queue[i]
    if (typeof value === 'number' && !Number.isFinite(value)) {
      reason = 'level-nonfinite-number'
      break
    }
    if (!value || typeof value !== 'object') continue
    if (depth > 64) {
      reason = 'level-depth-limit'
      break
    }
    for (const child of Object.values(value)) {
      if (queue.length >= 200_000) {
        reason = 'level-node-limit'
        break
      }
      queue.push({ value: child, depth: depth + 1 })
    }
    if (reason) break
  }
  if (reason) {
    reject(path, reason)
    continue
  }
  levels.push({
    path,
    size: bytes.length,
    sha256: createHash('sha256').update(bytes).digest('hex'),
  })
}

await writeFile('levels-index.json', JSON.stringify({ version: 1, levels, invalid }, null, 2) + '\n')
console.log(JSON.stringify({ levels: levels.length, invalid: invalid.length }))
for (const item of invalid) console.warn(JSON.stringify(item))
