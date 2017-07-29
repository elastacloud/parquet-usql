<#
    Custom deployment steps.
    todo: add uploading to blob, remote registration etc.
#>

param(
    [string] $ProjectDir,
    [string] $Configuration,
	[string] $BlobStorageAccountName = "",
	[string] $BlobStorageAccountKey = "",
	[string] $BlobStorageContainer = "",
	[string] $BlobStoragePath = ""
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
Write-Host "    configuration: $Configuration"
Write-Host "    blob storage account name: $BlobStorageAccountName"
Write-Host "    account Key: $BlobStorageAccountKey"
Write-Host "    container: $BlobStorageContainer"
Write-Host "    account Key: $BlobStoragePath"

$outDir = "$ProjectDir\bin\$Configuration-Merged"
$targetDllPath = "$outDir\Parquet.Adla.dll"
$blobName = $BlobStoragePath

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

function PublishToBlobStorage {
	# Check to see whether we need to upload to blob
	if([string]::IsNullOrEmpty($BlobStorageAccountName)) {
        Write-Host "No blob information specified. Not uploading to storage"
		return
	}
		
	$blobContext = New-AzureStorageContext -StorageAccountName $BlobStorageAccountName -StorageAccountKey $BlobStorageAccountKey
	# Modify the path if it's not correct
	if(!$BlobStoragePath.EndsWith("/")) {
		$blobName = "$($blobName)/Parquet.Adla.dll"
	} else {
		$blobName = "$($blobName)Parquet.Adla.dll"
	}
	# Check to see whether the container exists 
	Try {  
        New-AzureStorageContainer -Name $BlobStorageContainer -Permission Off -Context $blobContext -Verbose -ErrorAction Stop
    } catch [Microsoft.WindowsAzure.Storage.StorageException] {
    }

	Set-AzureStorageBlobContent -File $targetDllPath -Container $BlobStorageContainer -Blob $blobName -Context $blobContext -Force
}

MergeDll
PublishToBlobStorage