<#
    Custom deployment steps.
    todo: add uploading to blob, remote registration etc.
#>

param(
    [string] $ProjectDir,
    [string] $Configuration
)


if($ProjectDir -eq "")
{
    $ProjectDir = "$PSScriptRoot\Parquet.Adla"
}

if($Configuration -eq "")
{
    $Configuration = "Debug"
}

Write-Host "Parameters:"
Write-Host "    project dir: $ProjectDir"
Write-Host "    configuraiton: $Configuration"

$outDir = "$ProjectDir\bin\$Configuration-Merged"
$targetDllPath = "$outDir\Parquet.Adla.dll"

function MergeDll{
    $srcDir = "$ProjectDir\bin\$Configuration"
    if(Test-Path -Path $outDir)
    {
        Remove-Item -Path $outDir -Recurse -Force
    }
    $tmp = New-Item -Path $outDir -ItemType Directory

    $MergeAssemblies = @(
        "Parquet*.dll",
        "apache-thrift-netcore.dll",
        "NetBox.dll",
        "Newtonsoft.Json.dll",
        "Snappy.Sharp.dll",
        "System.ValueTuple.dll"
    )

    $ilMergePaths = $MergeAssemblies | ForEach-Object { "$srcDir\$_" }

    Invoke-Expression "$PSScriptRoot\..\tools\ilmerge.exe /wildcards /out:$targetDllPath /targetplatform:v4 $ilMergePaths"

    Write-Host "dll written to $targetDllPath"   
}

MergeDll