const fs = require('fs');
const cp = require('child_process');
const paths = [
 'characters/common/PlayerBase.gd', 'scripts/Main.gd', 'scripts/RealmMonster.gd',
 'scripts/RealmMonsterSpawner.gd', 'scripts/realms/RealmHazards.gd', 'scripts/ui/MatchHud.gd',
].map(p=>'smash-nine-prototype/'+p);
const normalize = s=>s.replace(/\r\n/g,'\n').split('\n').filter(line=>line.trim()!=='').join('\n');
const owners = paths.map(path=>{
 const before=cp.execFileSync('git',['show','HEAD:'+path],{encoding:'utf8'});
 const after=fs.readFileSync(path,'utf8');
 const stripped=after.split('\n').filter(line=>!/^const AUDIO := preload\(/.test(line)&&!/^\s*AUDIO\./.test(line)).join('\n');
 return {path, hookLines:after.split('\n').filter(line=>/^\s*AUDIO\./.test(line)).length, gameplaySourceUnchanged:normalize(before)===normalize(stripped)};
});
const allowed = new Set([...paths,
 'smash-nine-prototype/scripts/ui/FrontendMenu.gd',
 'smash-nine-prototype/assets/i18n/strings.csv',
 'smash-nine-prototype/tests/run_all.ps1',
]);
const modified=cp.execFileSync('git',['diff','--name-only'],{encoding:'utf8'}).trim().split(/\r?\n/).filter(Boolean);
const outside=modified.filter(path=>!allowed.has(path));
const report={owners,modifiedTrackedFiles:modified,outsideCard:outside,
 forbiddenCharactersChanged:modified.filter(p=>/^smash-nine-prototype\/characters\/(?!common\/PlayerBase.gd$)/.test(p)),
 forbiddenStoryChanged:modified.filter(p=>p.startsWith('smash-nine-prototype/scripts/story/')),
 audioAssetsAdded:fs.existsSync('smash-nine-prototype/assets/audio'),
};
fs.writeFileSync('reports/codex-sys-05/source-audit.json',JSON.stringify(report,null,2)+'\n');
if(owners.some(x=>!x.gameplaySourceUnchanged)||outside.length||report.forbiddenCharactersChanged.length||report.forbiddenStoryChanged.length||report.audioAssetsAdded) process.exitCode=1;
console.log(JSON.stringify(report,null,2));
