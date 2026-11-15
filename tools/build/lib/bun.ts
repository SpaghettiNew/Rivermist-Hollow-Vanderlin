import { mkdirSync, realpathSync } from 'node:fs';
import Juke from '../juke/index.js';

let hasInstallFolder = false;

// Runs the current Bun binary directly. A shell would start cmd.exe, which cannot use UNC folders.
export function runBun(cwd: string, args: any[]): Promise<Juke.ExecReturn> {
  const bunArgs = args.filter((arg) => typeof arg === 'string');
  // bun install crashes on a mapped network drive but works from the real (UNC) path.
  if (bunArgs[0] === 'install') {
    cwd = realpathSync.native(cwd);
  }
  return Juke.exec(process.execPath, bunArgs, { cwd });
}

export function bun(...args: any[]): Promise<Juke.ExecReturn> {
  if (!hasInstallFolder) {
    mkdirSync('./tgui/node_modules/', { recursive: true });
    hasInstallFolder = true;
  }

  return runBun('./tgui', args);
}

export function bunRoot(...args: any[]): Promise<Juke.ExecReturn> {
  if (!hasInstallFolder) {
    mkdirSync('./node_modules/', { recursive: true });
    hasInstallFolder = true;
  }

  return runBun('./', args);
}
