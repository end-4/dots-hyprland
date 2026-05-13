#!/usr/bin/env node
/**
 * sync-custom-docs.mjs
 *
 * Reads all .md/.mdx files from ../dots/custom/ and copies them into
 * src/content/docs/custom/, injecting Starlight frontmatter if missing.
 * Creates a placeholder index.md if no source files are found.
 */

import { readdir, readFile, writeFile, mkdir, stat } from 'node:fs/promises';
import { join, basename, extname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = fileURLToPath(new URL('.', import.meta.url));
const SRC_DIR = resolve(__dirname, '..', '..', 'dots', 'custom');
const DEST_DIR = resolve(__dirname, '..', 'src', 'content', 'docs', 'custom');

async function exists(path) {
  try {
    await stat(path);
    return true;
  } catch {
    return false;
  }
}

function titleFromFilename(filename) {
  return basename(filename, extname(filename))
    .replace(/[-_]/g, ' ')
    .replace(/\b\w/g, c => c.toUpperCase());
}

function hasFrontmatter(content) {
  return content.trimStart().startsWith('---');
}

function injectFrontmatter(content, filename) {
  if (hasFrontmatter(content)) return content;
  const title = titleFromFilename(filename);
  return `---\ntitle: "${title}"\ndescription: "Custom addition: ${title}"\n---\n\n${content}`;
}

async function syncDocs() {
  await mkdir(DEST_DIR, { recursive: true });

  const srcExists = await exists(SRC_DIR);
  if (!srcExists) {
    console.log(`Source directory ${SRC_DIR} does not exist — creating placeholder.`);
    await writeFile(
      join(DEST_DIR, 'index.md'),
      `---\ntitle: "Custom Additions"\ndescription: "User-specific customizations"\n---\n\nNo custom documentation files found in \`dots/custom/\`.\n\nAdd \`.md\` or \`.mdx\` files to that directory and they will appear here automatically on the next build.\n`
    );
    return;
  }

  let entries;
  try {
    entries = await readdir(SRC_DIR);
  } catch {
    entries = [];
  }

  const mdFiles = entries.filter(f => /\.(md|mdx)$/i.test(f));

  if (mdFiles.length === 0) {
    console.log('No .md/.mdx files found in source — creating placeholder.');
    await writeFile(
      join(DEST_DIR, 'index.md'),
      `---\ntitle: "Custom Additions"\ndescription: "User-specific customizations"\n---\n\nNo custom documentation files found in \`dots/custom/\`.\n\nAdd \`.md\` or \`.mdx\` files to that directory and they will appear here automatically on the next build.\n`
    );
    return;
  }

  let synced = 0;
  for (const file of mdFiles) {
    const content = await readFile(join(SRC_DIR, file), 'utf-8');
    const output = injectFrontmatter(content, file);
    const destFile = file.toLowerCase().replace(/\s+/g, '-');
    await writeFile(join(DEST_DIR, destFile), output, 'utf-8');
    console.log(`  synced: ${file} → custom/${destFile}`);
    synced++;
  }

  console.log(`Synced ${synced} custom doc(s).`);
}

syncDocs().catch(err => {
  console.error('sync-custom-docs failed:', err);
  process.exit(1);
});
