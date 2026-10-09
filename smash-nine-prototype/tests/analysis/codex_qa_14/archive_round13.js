const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const reportDir = path.resolve(__dirname, '../../../../reports/codex-qa-14');
for (const variant of ['a', 'b']) {
  const resultPath = path.join(reportDir, `round13-${variant}-results.json`);
  let text = fs.readFileSync(resultPath, 'utf8');
  if (text.charCodeAt(0) === 0xfeff) text = text.slice(1);
  const full = JSON.parse(text);
  if (!Array.isArray(full.fall_frames)) {
    console.log(`${variant}: already compact`);
    continue;
  }
  const archiveName = `round13-${variant}-full.json.gz`;
  fs.writeFileSync(path.join(reportDir, archiveName), zlib.gzipSync(Buffer.from(text, 'utf8'), { level: 9 }));
  const compact = { ...full, full_archive: archiveName, fall_frame_count: full.fall_frames.length };
  delete compact.fall_frames;
  fs.writeFileSync(resultPath, `${JSON.stringify(compact, null, 2)}\n`, 'utf8');
  console.log(`${variant}: ${text.length} bytes -> ${fs.statSync(path.join(reportDir, archiveName)).size} byte archive; compact=${fs.statSync(resultPath).size}`);
}
