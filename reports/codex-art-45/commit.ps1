$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
Set-Location $repoRoot

$preStaged = @(git diff --cached --name-only)
if ($preStaged.Count -gt 0) {
	throw "이미 staged 상태인 파일이 있습니다. 기존 staging을 먼저 정리한 뒤 다시 실행하세요.`n$($preStaged -join "`n")"
}

$rows = @(
	"walk",
	"jump",
	"fall",
	"hurt",
	"shield",
	"attack",
	"brave_combo",
	"brave_upper",
	"brave_low",
	"brave_air_side",
	"brave_dive",
	"comet_drive",
	"luna_breaker",
	"heart_laser",
	"tumble"
)

$candidatePaths = @()
foreach ($row in $rows) {
	$candidatePaths += "art/bakeoff/luna/luna_brave-$row-v1.png"
	$candidatePaths += "art/bakeoff/luna/luna_brave-$row-v1.json"
}

git add -- $candidatePaths
git add -- reports/codex-art-45

$staged = @(git diff --cached --name-only)
$allowedCandidates = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($path in $candidatePaths) {
	[void]$allowedCandidates.Add($path)
}

$unexpected = @(
	$staged | Where-Object {
		-not $_.StartsWith("reports/codex-art-45/") -and -not $allowedCandidates.Contains($_)
	}
)
if ($unexpected.Count -gt 0) {
	throw "허용 범위 밖 파일이 staged 되었습니다. 커밋하지 않습니다.`n$($unexpected -join "`n")"
}

if ($staged | Where-Object { $_.StartsWith("art/raw/") }) {
	throw "art/raw 파일은 커밋 대상이 아닙니다."
}

$message = @"
art: add Brave Luna row candidates

Co-Authored-By: Codex <noreply@openai.com>
"@

git commit -m $message
