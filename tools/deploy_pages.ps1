# Builds the web export and publishes it to the gh-pages branch for GitHub Pages
# (https://<owner>.github.io/<repo>/). gh-pages is a deploy-only branch holding one
# commit: each deploy replaces it (force push to gh-pages only, never main), so
# 40 MB wasm builds do not pile up in history.
# Usage (from the repo root): powershell -ExecutionPolicy Bypass -File tools/deploy_pages.ps1
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "build_web.ps1")
if ($LASTEXITCODE -ne 0) { exit 1 }

$webDir = Join-Path $repo "build\web"
$stage = Join-Path $repo "build\gh-pages"
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Force -Path $stage | Out-Null
Copy-Item -Path (Join-Path $webDir "*") -Destination $stage -Recurse
New-Item -ItemType File -Path (Join-Path $stage ".nojekyll") | Out-Null
Copy-Item (Join-Path $repo "smash-nine-prototype\assets\THIRD_PARTY_ASSETS.md") (Join-Path $stage "CREDITS.md")

$origin = (git -C $repo remote get-url origin).Trim()
$source = (git -C $repo rev-parse --short HEAD).Trim()
git -C $stage init -q -b gh-pages
git -C $stage -c core.autocrlf=false add -A
git -C $stage commit -q -m "Deploy web build from $source"
git -C $stage push -q --force $origin gh-pages
if ($LASTEXITCODE -ne 0) { Write-Output "Push to gh-pages failed"; exit 1 }
$path = ($origin -replace '\.git$', '') -replace '^https://github\.com/', ''
$owner, $name = $path.Split('/')
Write-Output "Deployed $source to gh-pages. Site: https://$($owner.ToLower()).github.io/$name/"
