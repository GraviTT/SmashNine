$runner=Join-Path $PSScriptRoot 'run.ps1'
& $runner -Condition trace -Count 1 -TraceMode physics -Poll idle
& $runner -Condition trace -Count 1 -TraceMode physics -Poll idle -Fps 10
& $runner -Condition trace -Count 3 -TraceMode physics -Poll idle -StallMs 150
& $runner -Condition trace -Count 3 -TraceMode idle -Poll idle -StallMs 150
& $runner -Condition trace -Count 3 -TraceMode physics -Poll physics -StallMs 150
