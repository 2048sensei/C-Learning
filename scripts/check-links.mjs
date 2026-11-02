#!/usr/bin/env node
/**
 * 检查 学习资源/ 内部链接：HTML 的 href/src 与 CSS 的 url()。
 * 只校验站内相对路径与 / 开头的站点绝对路径，外部链接与锚点跳过。
 *
 * 用法：node scripts/check-links.mjs
 * 退出码：0 全部可解析；1 存在断链或目标越界。
 */
import { readdirSync, readFileSync, existsSync, statSync } from 'node:fs';
import { dirname, join, resolve, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const siteRoot = join(root, '学习资源');

function walk(dir) {
  const out = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.name.startsWith('.')) continue;
    const full = join(dir, entry.name);
    if (entry.isDirectory()) out.push(...walk(full));
    else if (entry.isFile()) out.push(full);
  }
  return out;
}

const attrPattern = /\b(?:href|src)\s*=\s*(?:"([^"]*)"|'([^']*)')/gi;
const cssUrlPattern = /url\(\s*(?:"([^"]*)"|'([^']*)'|([^)'"\s]+))\s*\)/gi;

function targetsOf(file) {
  const text = readFileSync(file, 'utf8');
  const found = [];
  const ext = file.toLowerCase().slice(file.lastIndexOf('.'));
  if (ext === '.html' || ext === '.htm') {
    for (const match of text.matchAll(attrPattern)) {
      found.push(match[1] ?? match[2] ?? '');
    }
  } else if (ext === '.css') {
    for (const match of text.matchAll(cssUrlPattern)) {
      found.push(match[1] ?? match[2] ?? match[3] ?? '');
    }
  }
  return found;
}

function isExternal(value) {
  return /^(?:[a-z][a-z0-9+.-]*:|\/\/)/i.test(value);
}

const htmlFiles = walk(siteRoot).filter((f) => /\.html?$/i.test(f));
const cssFiles = walk(siteRoot).filter((f) => f.toLowerCase().endsWith('.css'));
const problems = [];
let checked = 0;

for (const file of [...htmlFiles, ...cssFiles]) {
  for (const raw of targetsOf(file)) {
    const value = raw.trim();
    if (!value || value.startsWith('#') || isExternal(value)) continue;

    const withoutSuffix = value.split('#')[0].split('?')[0];
    if (!withoutSuffix) continue;
    if (/^(?:mailto:|tel:|javascript:|data:)/i.test(withoutSuffix)) continue;

    let decoded;
    try {
      decoded = decodeURIComponent(withoutSuffix);
    } catch {
      problems.push(`${relative(root, file)} → ${raw}（URL 编码无法解析）`);
      continue;
    }

    const base = decoded.startsWith('/') ? siteRoot : dirname(file);
    let target = decoded.startsWith('/') ? join(siteRoot, decoded) : join(base, decoded);
    if (decoded.endsWith('/')) target = join(target, 'index.html');
    target = resolve(target);

    const relToSite = relative(siteRoot, target);
    if (relToSite.startsWith('..')) {
      problems.push(`${relative(root, file)} → ${raw}（指向站点目录之外）`);
      continue;
    }

    checked++;
    if (!existsSync(target) || (existsSync(target) && statSync(target).isDirectory())) {
      problems.push(`${relative(root, file)} → ${raw}`);
    }
  }
}

console.log(`检查 ${htmlFiles.length} 个页面、${cssFiles.length} 个样式表，共 ${checked} 个站内链接。`);

if (problems.length > 0) {
  console.error(`\n发现 ${problems.length} 个断链：`);
  for (const problem of problems) console.error(`  ✗ ${problem}`);
  process.exit(1);
}

console.log('链接检查通过。');
