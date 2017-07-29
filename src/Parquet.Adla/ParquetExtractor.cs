using System;
using System.Collections.Generic;
using System.IO;
using Microsoft.Analytics.Interfaces;
using Parquet;
using Parquet.Data;

namespace Parquet.Adla
{
   [SqlUserDefinedOutputter(AtomicFileProcessing = true)]
   public class ParquetExtractor : IExtractor
   {
      public override IEnumerable<IRow> Extract(IUnstructuredReader input, IUpdatableRow output)
      {
         DataSet ds;
         using (var reader = new ParquetReader(input.BaseStream))
         {
            ds = reader.Read();
         }

         
         for (int i = 0; i < ds.RowCount; i++)
         {
            for (int j = 0; j < ds.ColumnCount; j++)
            {
               output.Set(ds.Schema.ColumnNames[j], ds[i][j]);
            }
            yield return output.AsReadOnly();
         }
         
      }
   }
}