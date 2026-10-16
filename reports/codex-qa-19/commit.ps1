$ErrorActionPreference = "Stop"

$paths = @(
	"reports/codex-qa-19/README.md",
	"reports/codex-qa-19/boards",
	"reports/codex-qa-19/clip_measurements.json",
	"reports/codex-qa-19/effect_inventory.json",
	"reports/codex-qa-19/effect_measurements.json",
	"reports/codex-qa-19/head_scale_measurements.json",
	"reports/codex-qa-19/sheet_measurements.json",
	"reports/codex-qa-19/commit.ps1",
	"tests/analysis/codex_qa_19/audit_assets.py",
	"tests/analysis/codex_qa_19/make_head_board.py",
	"tests/analysis/codex_qa_19/measure_head_consistency.py"
)

git add -- $paths
if ($LASTEXITCODE -ne 0) { throw "git add failed" }

git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw "git diff --cached --check failed" }

git commit -m "qa: audit current fighter sprites and effects"
if ($LASTEXITCODE -ne 0) { throw "git commit failed" }
