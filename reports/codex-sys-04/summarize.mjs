import fs from 'node:fs';
import { createHash } from 'node:crypto';
const root = 'reports/codex-sys-04/';
const read = name => fs.readFileSync(root + name, 'utf8');
const all = read('all.log');
const testCount = [...all.matchAll(/^PASS (?:test_\S+|visual_preview)\b/gm)].length;
if (!/^ALL PASSED\s*$/m.test(all) || testCount !== 48 || /^FAIL /m.test(all)) throw new Error('Final 48-test gate must pass.');
let certificateLines = 0;
for (const name of fs.readdirSync(root + 'raw-logs')) {
  const text = read('raw-logs/' + name);
  const errors = text.split(/\r?\n/).filter(line => /^\s*(SCRIPT ERROR|ERROR|Parse Error)/.test(line));
  for (const line of errors) {
    if (line.trim() === 'ERROR: Failed to read the root certificate store.') certificateLines++;
    else throw new Error(name + ': ' + line);
  }
}
const soakMatch = all.match(/SOAK_RESULT (\{[^\r\n]+\})/);
if (!soakMatch) throw new Error('Soak result missing.');
const soak = JSON.parse(soakMatch[1]);
if (!soak.match_over || soak.nan_positions !== 0 || !soak.winner) throw new Error('Soak must finish without NaN.');
const journeys = JSON.parse(read('continuous-journeys.json'));
if (journeys.failed || journeys.journeys.length !== 14 || journeys.journeys.some(row => row.cleared !== 9 || !row.done || row.final_cards.length !== 3)) throw new Error('All fourteen continuous journeys must clear.');
const reloadJourneys = JSON.parse(read('continuous-journeys-reload.json'));
if (reloadJourneys.failed || reloadJourneys.journeys.length !== 14 || reloadJourneys.journeys.some(row => row.cleared !== 9 || !row.done || row.final_cards.length !== 3)) throw new Error('All fourteen F2 stress journeys must clear.');
const routes = ['frey', 'luna', 'yuki', 'nova', 'rio'].map(id => {
  const text = read('route-' + id + '.log');
  const match = text.match(/ESCAPE_ROUTE_RESULT (\{[^\r\n]+\})/);
  if (!match) throw new Error('Route result missing for ' + id);
  const row = JSON.parse(match[1]);
  if (row.failed || row.crystals !== 3 || row.phase !== 'result' || row.seconds >= 60) throw new Error('Escape route must clear: ' + id);
  return row;
});
const combat = JSON.parse(read('combat-probe.json'));
if (combat.results.length !== 20) throw new Error('Expected twenty runtime combat runs.');
const captures = ['00-stage-five-overview-ko', '01-stage-five-crystals-ko', '02-stage-seven-boss-ko', '03-stage-nine-rivals-ko', '04-stage-nine-shadow-dialogue-ko', '05-stage-nine-band-ko', '06-story-ending-ko', '07-boss-post-warning-hidden-ko', '08-story-map-all-ready-ko', '09-story-clear-select-ko', '10-stage-five-time-up-ko'];
for (const name of [...captures, 'contact-sheet']) if (!fs.existsSync(root + name + '.png')) throw new Error('Missing capture ' + name);
const summary = {
  recorded_utc: new Date().toISOString(), all_passed: true, headless_tests: testCount,
  final_gate_log_sha256: createHash('sha256').update(all).digest('hex'),
  source_sha256: Object.fromEntries([...read('commit.ps1').matchAll(/^    '(smash-nine-prototype\/[^']+)'/gm)].map(match => [match[1], createHash('sha256').update(fs.readFileSync(match[1])).digest('hex')])),
  unexpected_engine_errors_in_final_raw_logs: 0, known_certificate_lines_in_raw_logs: certificateLines,
  battle_royale_soak: { seed: 1001, seconds: soak.seconds_simulated, winner: soak.winner, match_over: soak.match_over, nan_positions: soak.nan_positions },
  continuous_journeys: { checks: journeys.checks, completed: journeys.journeys.length, bodies: 7, difficulties: ['normal', 'easy'], final_souls: [...new Set(journeys.journeys.map(row => row.final_souls))] },
  extended_f2_journeys: { checks: reloadJourneys.checks, completed: reloadJourneys.journeys.length, final_souls: [...new Set(reloadJourneys.journeys.map(row => row.final_souls))] },
  protected_physical_escape_routes: routes.map(row => ({ hero: row.id, seconds: row.seconds })),
  real_bot_combat_runs: combat.results.length, real_bot_combat_note: combat.note,
  korean_captures: captures.length, contact_sheet: 'contact-sheet.png',
  git_commit: /index\.lock.*Permission denied/.test(read('git-stage.log')) ? 'not_created_index_permission_denied' : 'see_git_stage_log',
  commit_handoff: 'commit.ps1', commit_message: 'commit-message.txt',
  intermittent_existing_test: { name: 'test_luna_kit', observation: 'One full run missed a moving echo bloom in 1 of 4 trials; unchanged isolated retest passed. Not ignored as certificate noise.', failed_full_log: 'diagnostics/final-gate-luna-intermittent.log', engine_log: 'diagnostics/luna-intermittent-engine.log', isolated_retest: 'test_luna_kit.log' },
  limitations: ['Progression probes force enemy defeats; escape route heroes are protected.', 'Human difficulty tuning and real-user save-file manual checks were not performed.', 'No web build, merge or publishing.']
};
if (!read('commit-message.txt').trimEnd().endsWith('Co-Authored-By: Codex <noreply@openai.com>')) throw new Error('Commit message trailer missing.');
fs.writeFileSync(root + 'validation-summary.json', JSON.stringify(summary, null, 2) + '\n', 'utf8');
console.log('PASS: 48 tests + BR soak; 14 continuous + 14 F2 stress journeys; 5 physical escape routes; 20 bot combat runs; 11 Korean captures.');
