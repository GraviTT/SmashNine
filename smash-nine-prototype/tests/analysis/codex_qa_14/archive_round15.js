const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const reportDir = path.resolve(__dirname, '../../../../reports/codex-qa-14');
const resultPath = path.join(reportDir, 'round15-results.json');
const text = fs.readFileSync(resultPath, 'utf8').replace(/^\uFEFF/, '');
const full = JSON.parse(text);
if (!Array.isArray(full.fall_frames)) {
  console.log('Round 15 already compact');
  process.exit(0);
}
const archiveName = 'round15-full.json.gz';
fs.writeFileSync(path.join(reportDir, archiveName), zlib.gzipSync(Buffer.from(text, 'utf8'), { level: 9 }));
const compact = { ...full, full_archive: archiveName, fall_frame_count: full.fall_frames.length };
delete compact.fall_frames;
fs.writeFileSync(resultPath, `${JSON.stringify(compact, null, 2)}\n`, 'utf8');
console.log(`${text.length} bytes -> ${fs.statSync(path.join(reportDir, archiveName)).size} byte archive; compact=${fs.statSync(resultPath).size}`);
