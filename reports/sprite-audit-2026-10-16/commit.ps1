$ErrorActionPreference = "Stop"

$paths = @(
	"reports/sprite-audit-2026-10-16/images",
	"reports/sprite-audit-2026-10-16/images.md",
	"reports/sprite-audit-2026-10-16/commit.ps1",
	"tests/analysis/codex_doc_02/build_images.py"
)

git add -- $paths
if ($LASTEXITCODE -ne 0) { throw "git add failed" }

git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw "git diff --cached --check failed" }

git commit -m "docs: illustrate sprite audit findings"
if ($LASTEXITCODE -ne 0) { throw "git commit failed" }
