# Apache Parquet for Azure Data Lake [![Build status](https://ci.appveyor.com/api/projects/status/e8inekwpv0femv8b/branch/master?svg=true)](https://ci.appveyor.com/project/aloneguid/parquet-usql/branch/master)

## Summary

This custom extractor and outputter consumes parquet-dotnet to enable reads of parquet files in Azure Data Lake Analytics. 
The extractor supports both the native Apache Parquet format and the type representation using Apache Spark, 
HIVE and Impala so that the outputs are interchangable as there are several discrepencies in representation for annotated types.

## Deployment

The Parquet.Adla project compiles with all dependent assemblies into a single assembly created through ILMerge. The deploy.ps1 Powershell script can be run locally 
to:

-	Merge all dependent assemblies into Parquet.Adla.dll
-	Copy the assembly to your chosen blob storage container
-	Copy and register the assembly to the catalog of your chosen ADLS database 

To install for use with ADLA open a command script at the solution root and enter the following:

	powershell -File .\deploy.ps1 -BlobStorageAccountName xx
		-BlobStorageAccountKey xx
		-BlobStorageContainer xx
		-BlobStoragePath xx
		-AzureDataLakeStoreName xx
		-AzureDataLakeAnalyticsName xx
		-TenantId xx
		-ApplicationId xx
		-ApplicationKey xx
		-SubscriptionId xx

If the Blob storage parameters are omitted then the script will not deploy to storage and if the ADLS and ADLA names are omitted then the dll will not be deployed to ADLS and regsitered with the catalog.

The deployment uses a Service Principal which must be created to enable a non-interctive login. Use the following guide to create one.

[Creating a Service Principal](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal)

Follow the steps to get the ApplicationId and the Key and then use them in the deployment script. You will also need to select the resources in the Azure Portal (ADLA and ADLS) and add give the Service Principal at least a contributor role under the IAM tab.

To find out your TenantId use the following Uri.

https://login.windows.net/xxx.onmicrosoft.com/.well-known/openid-configuration

Replacing xxx with your own Azure Active Directory name. This should give you a list of your subscriptions. The Guid character in each of the Urls is the TenantId.

## Usage
### Outputter
To use the outputter reference Parquet.Adla as follows.

	REFERENCE ASSEMBLY [Parquet.Adla];

	@a  = 
    SELECT * FROM 
        (VALUES
            ("Contoso", 1500.0),
            ("Woodgrove", 2700.0)
        ) AS 
              D( customer, amount );
	OUTPUT @a
		TO "/pqnet/test1.parquet"
		USING new Parquet.Adla.Outputter.ParquetOutputter();

### Extractor
To use the Extractor reference Parquet.Adla as follows.

	USE DATABASE master;
	REFERENCE ASSEMBLY [Parquet.Adla];

	DECLARE @input_file string = @"alltypes.plain.parquet";
	DECLARE @output_file string = @"alltypes.plain.csv";

	@a =
		EXTRACT bool_col bool, timestamp_col DateTime
		FROM @input_file USING new Parquet.Adla.Extractors.ParquetExtractor();

	OUTPUT @a
		TO @output_file
		USING Outputters.Csv();

## Limitations