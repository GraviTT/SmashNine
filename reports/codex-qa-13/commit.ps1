$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
Set-Location $repoRoot

$allowed = @(
	"reports/codex-qa-13/",
	"smash-nine-prototype/tests/analysis/codex_qa_13/"
)

git add -- reports/codex-qa-13 smash-nine-prototype/tests/analysis/codex_qa_13
$staged = @(git diff --cached --name-only)
$outside = @($staged | Where-Object {
	$path = $_
	-not ($allowed | Where-Object { $path.StartsWith($_) })
})
if ($outside.Count -gt 0) {
	throw "Refusing to commit paths outside QA-13 writable roots: $($outside -join ', ')"
}

$message = "QA-13 review combat and realm scale`n`nCo-Authored-By: Codex <noreply@openai.com>"
git commit -m $message
