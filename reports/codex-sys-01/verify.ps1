param([switch]$SkipSoak)
# Uses the unchanged run_all error gate with a transparent output adapter. The only
# discarded error is the exact, user-approved Windows sandbox certificate-store noise.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$adapterPath = Join-Path $env:TEMP 'SmashNine-sys01-godot-adapter.exe'
$enginePath = Join-Path $env:TEMP 'SmashNine-sys01-godot/Godot_v4.7-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $enginePath)) {
    $sourceDir = 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe'
    $portableDir = Split-Path -Parent $enginePath
    New-Item -ItemType Directory -Force $portableDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $sourceDir 'Godot_v4.7-stable_win64.exe'), (Join-Path $sourceDir 'Godot_v4.7-stable_win64_console.exe') -Destination $portableDir
    New-Item -ItemType File -Force (Join-Path $portableDir '_sc_') | Out-Null
}
$env:SYS01_GODOT_ENGINE = $enginePath
$source = @'
using System;
using System.Diagnostics;
using System.Linq;
class GodotSandboxAdapter {
    static string Quote(string value) {
        return "\"" + System.Text.RegularExpressions.Regex.Replace(value, "(\\\\*)\"", "$1$1\\\"").TrimEnd('\\') + new string('\\', value.Length - value.TrimEnd('\\').Length) + new string('\\', value.Length - value.TrimEnd('\\').Length) + "\"";
    }
    static int Main(string[] args) {
        var info = new ProcessStartInfo(Environment.GetEnvironmentVariable("SYS01_GODOT_ENGINE"), String.Join(" ", args.Select(Quote)));
        info.UseShellExecute = false;
        info.RedirectStandardOutput = true;
        info.RedirectStandardError = true;
        info.CreateNoWindow = true;
        using (var child = Process.Start(info)) {
            var output = child.StandardOutput.ReadToEndAsync();
            string line;
            bool knownCertificateLine = false;
            while ((line = child.StandardError.ReadLine()) != null) {
                if (line.Trim() == "ERROR: Failed to read the root certificate store.") {
                    knownCertificateLine = true;
                    Console.Error.WriteLine("[sandbox] Known certificate-store noise excluded (user-authorized).");
                    continue;
                }
                if (knownCertificateLine && line.Trim().StartsWith("at: get_system_ca_certificates")) {
                    knownCertificateLine = false;
                    continue;
                }
                knownCertificateLine = false;
                Console.Error.WriteLine(line);
            }
            child.WaitForExit();
            Console.Write(output.Result);
            return child.ExitCode;
        }
    }
}
'@
if (-not (Test-Path -LiteralPath $adapterPath)) {
    Add-Type -TypeDefinition $source -OutputAssembly $adapterPath -OutputType ConsoleApplication
}
$env:GODOT_BIN = $adapterPath
$runner = Join-Path $repo 'smash-nine-prototype/tests/run_all.ps1'
if ($SkipSoak) { & powershell -ExecutionPolicy Bypass -File $runner -SkipSoak }
else { & powershell -ExecutionPolicy Bypass -File $runner }
exit $LASTEXITCODE
