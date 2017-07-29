# Apache Parquet for Azure Data Lake [![Build status](https://ci.appveyor.com/api/projects/status/e8inekwpv0femv8b/branch/master?svg=true)](https://ci.appveyor.com/project/aloneguid/parquet-usql/branch/master)

## Azure Data Lake Analytics custom extractor for parquet

This custom extractor consumes parquet-dotnet to enable reads of parquet files in Azure Data Lake Analytics. The extractor supports both the native Apache Parquet format and the type representation using Apache Spark, HIVE and Impala so that the outputs are interchangable as there are several discrepencies in representation for annotated types.
