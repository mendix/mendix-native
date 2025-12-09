#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const rootDir = path.join(__dirname, '..');

console.log('Building package with TypeScript...');

try {
  // Try to find TypeScript in various locations
  const localTsc = path.join(rootDir, 'node_modules', '.bin', 'tsc');
  const parentTsc = path.join(
    rootDir,
    '..',
    '..',
    'node_modules',
    '.bin',
    'tsc'
  );

  let tscCommand;

  if (fs.existsSync(localTsc)) {
    tscCommand = localTsc;
  } else if (fs.existsSync(parentTsc)) {
    // When installed as git dependency, tsc might be in parent node_modules
    tscCommand = parentTsc;
  } else {
    // Fall back to npx
    tscCommand = 'npx -y typescript';
  }

  execSync(`${tscCommand} --project tsconfig.commonjs.json`, {
    stdio: 'inherit',
    cwd: rootDir,
  });

  console.log('✔ Build completed successfully');
} catch (error) {
  console.error('Build failed:', error.message);
  process.exit(1);
}
