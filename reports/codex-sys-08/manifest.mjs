import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const dir = path.dirname(fileURLToPath(import.meta.url)), repo = path.resolve(dir, '../..');
const product = ['design/AUDIO.md', 'smash-nine-prototype/scripts/realms/RealmHazards.gd',
  'smash-nine-prototype/scripts/audio/AudioCatalog.gd', 'smash-nine-prototype/scripts/audio/AudioManager.gd',
  'smash-nine-prototype/scripts/story/StorySession.gd', 'smash-nine-prototype/scripts/ui/StoryDialogue.gd',
  'smash-nine-prototype/scripts/ui/StoryScreens.gd', 'smash-nine-prototype/tests/test_audio.gd', 'smash-nine-prototype/tests/test_realm_gimmicks.gd'];
const report = ['README.md','run.ps1','regressions.ps1','suite.ps1','prepare.mjs','analyze.mjs','build-report.mjs',
  'render-chart.ps1','verify.mjs','manifest.mjs','commit.ps1','files.txt','comparison.json','comparison.png','comparison.svg',
  'chart-data.json','gate-windows.md','sound-tables.md','gate-soak-2105.json','gate-soak-2106.json','rate-comparison.json',
  'story-no-fix.json','regression-checks.json','suite-meta.json','suite-summary.log','verification.json'];
const walk = rel => fs.readdirSync(path.join(repo, rel), {withFileTypes:true}).flatMap(e => e.isDirectory() ? walk(rel+'/'+e.name) : [rel+'/'+e.name]);
const tests = walk('smash-nine-prototype/tests/analysis/codex_sys_08').filter(p => /\.gd(?:\.uid)?$/.test(p));
const logs = fs.readdirSync(path.join(dir,'logs')).filter(n=>n.endsWith('.log') && !/^gate-soak-/.test(n)).map(n=>'logs/'+n);
const captures = fs.readdirSync(dir).filter(n=>/^sound-(br|story)-\d+-events\.json\.gz$/.test(n));
const suite = walk('reports/codex-sys-08/suite');
const files = [...new Set([...product,...tests,...report.concat(logs,captures).map(p=>'reports/codex-sys-08/'+p),...suite])].sort();
fs.writeFileSync(path.join(dir,'files.txt'),files.join('\n')+'\n');
console.log(`SYS08 manifest: ${files.length} explicit files (raw replay inputs and invalid seed runs excluded).`);
