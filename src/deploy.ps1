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
	[string] $BlobStoragePath = "",
	[string] $AzureDataLakeStoreName = "", 
	[string] $AzureDataLakeAnalyticsName = "",
	[string] $TenantId = "",
	[string] $ApplicationId = "",
	[string] $ApplicationKey = "",
	[string] $SubscriptionId = ""
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
Write-Host "    path: $BlobStoragePath"

Write-Host "    Data Lake Store Name: $AzureDataLakeStoreName"
Write-Host "    Data Lake Analytics Name: $AzureDataLakeAnalyticsName"
Write-Host "    Tenant Id: $TenantId"
Write-Host "    Application Id: $ApplicationId"
Write-Host "    Application Key: $ApplicationKey"

Write-Host "    Subscription Id: $SubscriptionId"


$outDir = "$ProjectDir\bin\$Configuration-Merged"
$targetDllPath = "$outDir\Parquet.Adla.dll"
$blobName = $BlobStoragePath

function MergeDll{
    $srcDir = "$ProjectDir\bin\$Configuration"
    if(Test-Path -Path $outDir)
    {        Remove-Item -Path $outDir -Recurse -Force
    }
    $tmp = New-Item -Path $outDir -ItemType Directory

    $MergeAssemblies = @(
        "Parquet*.dll",
        "apache-thrift-netcore.dll",
        "NetBox.dll",
        "Newtonsoft.Json.dll",
        "Snappy.Sharp.dll",
        "System.ValueTuple.dll"    )

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


function UploadAssembliesToAdls() {
	# Check to see whether we need to upload to blob
	if([string]::IsNullOrEmpty($AzureDataLakeStoreName)) {
        Write-Host "No data lake information specified. Not uploading to storage."
		return
	}


  $ApplicationKey = ConvertTo-SecureString -String $ApplicationKey -AsPlainText -Force
	$creds = New-Object System.Management.Automation.PSCredential($ApplicationId, $ApplicationKey)
	Login-AzureRmAccount -Credential $creds -ServicePrincipal -TenantId $TenantId
	Set-AzureRMContext -SubscriptionId $SubscriptionId 
  Write-Host "Setting subscription to $SubscriptionId"
	# Copy the assembly to the ADLS
	Import-AzureRmDataLakeStoreItem -AccountName $AzureDataLakeStoreName -Path $targetDllPath -Destination "/Assemblies/Parquet.Adla.dll" -Force
  Write-Host "Registering Parquet.Adla.dll assembly to $AzureDataLakeStoreName"
	# Register the assembly once to avoid this in each script (master db)
	$job = Submit-AzureRmDataLakeAnalyticsJob -Name "Create Assembly" -AccountName $AzureDataLakeAnalyticsName -ScriptPath "$PSScriptRoot\registerassembly.usql" -DegreeOfParallelism 1
  Write-Host "Registering script with $AzureDataLakeAnalyticsName"
	# Check to see make that the job has ended
	While (($t = Get-AzureRmDataLakeAnalyticsJob -AccountName $AzureDataLakeAnalyticsName -JobId $job.JobId).State -ne "Ended") {
		Write-Host "Job status: "$t.State"..."
		Start-Sleep -seconds 10
	}
}

MergeDll
PublishToBlobStorage
UploadAssembliesToAdls