/**
 * Opens FlutterFlow in a visible browser so you stay logged in.
 * Run: node scripts/flutterflow-browser.mjs
 */
import { chromium } from 'playwright';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const profileDir = path.join(__dirname, '..', '.browser-profile');

const browser = await chromium.launchPersistentContext(profileDir, {
  headless: false,
  viewport: { width: 1400, height: 900 },
});

const page = browser.pages()[0] || (await browser.newPage());
await page.goto('https://app.flutterflow.io/', { waitUntil: 'domcontentloaded' });

console.log('FlutterFlow opened. Log in if needed.');
console.log('Keep this window open — your session is saved for next runs.');
console.log('Press Ctrl+C in this terminal to close.');

await new Promise(() => {});