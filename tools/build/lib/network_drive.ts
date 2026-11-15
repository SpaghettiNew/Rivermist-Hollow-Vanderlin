import { createHash } from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import Juke from '../juke/index.js';
import { runBun } from './bun';

/** True when the folder's real path is a UNC network path. */
export function isNetworkPath(dir: string): boolean {
  try {
    return fs.realpathSync.native(dir).startsWith('\\\\');
  } catch {
    return false;
  }
}

/**
 * Bun resolves a mapped network drive to its UNC path, and cmd.exe and Bun's bin
 * shims fail in UNC folders. Uses the launch folder's drive form of the root instead.
 */
export function preferMappedDrive(fromDir: string) {
  const root = process.cwd();
  if (!root.startsWith('\\\\')) {
    return;
  }
  const realRoot = fs.realpathSync.native(root).toLowerCase();
  for (let dir = fromDir; ; dir = path.dirname(dir)) {
    try {
      if (fs.realpathSync.native(dir).toLowerCase() === realRoot) {
        process.chdir(dir);
        return;
      }
    } catch {
      // Unreadable folders cannot be the root; keep walking up.
    }
    if (path.dirname(dir) === dir) {
      return;
    }
  }
}

/**
 * Rspack's native code fails on network shares, so tgui is built in a local copy.
 * The copy keeps its node_modules between builds; emitted files are copied back.
 */
export async function buildTguiInLocalMirror() {
  const source = path.resolve('tgui');
  const realSource = fs.realpathSync.native(source).toLowerCase();
  const hash = createHash('sha1').update(realSource).digest('hex').slice(0, 12);
  const mirror = path.join(os.tmpdir(), `cbt-tgui-${hash}`);
  Juke.logger.info(`tgui is on a network share, building it in ${mirror}`);

  fs.mkdirSync(mirror, { recursive: true });
  for (const entry of fs.readdirSync(mirror)) {
    if (entry !== 'node_modules') {
      fs.rmSync(path.join(mirror, entry), { recursive: true, force: true });
    }
  }
  fs.cpSync(source, mirror, {
    recursive: true,
    filter: (src) =>
      !path.relative(source, src).split(path.sep).includes('node_modules'),
  });

  await runBun(mirror, ['install', '--frozen-lockfile', '--ignore-scripts']);
  const buildStart = Date.now();
  await runBun(mirror, ['run', 'tgui:build']);

  copyNewFiles(path.join(mirror, 'public'), path.join(source, 'public'), buildStart);
}

function copyNewFiles(from: string, to: string, since: number) {
  for (const entry of fs.readdirSync(from, { withFileTypes: true })) {
    const fromPath = path.join(from, entry.name);
    const toPath = path.join(to, entry.name);
    if (entry.isDirectory()) {
      copyNewFiles(fromPath, toPath, since);
    } else if (fs.statSync(fromPath).mtimeMs >= since) {
      fs.mkdirSync(to, { recursive: true });
      fs.copyFileSync(fromPath, toPath);
    }
  }
}
