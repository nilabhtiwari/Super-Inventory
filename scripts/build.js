const fs = require('fs');
const path = require('path');

const src = path.join(__dirname, '..', 'flutter_app', 'web_preview');
const dest = path.join(__dirname, '..', 'public');

if (!fs.existsSync(dest)) {
  fs.mkdirSync(dest, { recursive: true });
}

fs.cpSync(src, dest, { recursive: true });
// Also ensure index.html exists in root for any static server fallbacks
fs.copyFileSync(path.join(src, 'index.html'), path.join(__dirname, '..', 'index.html'));
console.log('Successfully prepared public directory and root index.html for Vercel deployment');
