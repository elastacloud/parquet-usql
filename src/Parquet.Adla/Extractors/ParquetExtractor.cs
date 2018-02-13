using System;
using System.Collections.Generic;
using System.IO;
using Microsoft.Analytics.Interfaces;
using Parquet.Data;


namespace Parquet.Adla.Extractors
{
   [SqlUserDefinedOutputter(AtomicFileProcessing = true)]
   public class ParquetExtractor : IExtractor
   {
      private DataSet _parquet;
      private readonly Dictionary<string, int> _columnNameToIndex = new Dictionary<string, int>();

      public override IEnumerable<IRow> Extract(IUnstructuredReader input, IUpdatableRow output)
      {
         Read(input);

         foreach(Row parquetRow in _parquet)
         {
            foreach(IColumn outputColumn in output.Schema)
            {
               int parquetIndex = _columnNameToIndex[outputColumn.Name];
               object value = parquetRow[parquetIndex];

               if (value is DateTimeOffset offset)
               {
                  output.Set(outputColumn.Name, offset.DateTime);
               }
               else
               {
                  output.Set(outputColumn.Name, value);
               }
            }

            yield return output.AsReadOnly();
         }
      }

      private void Read(IUnstructuredReader reader)
      {
         //i'm not sure how to read this any other way as Parquet needs seekable stream
         using (var ms = new MemoryStream())
         {
            reader.BaseStream.CopyTo(ms);
            ms.Position = 0;
            _parquet = ParquetReader.Read(ms, new ParquetOptions() { TreatByteArrayAsString = true });
         }

         _columnNameToIndex.Clear();
         for(int i = 0; i < _parquet.Schema.Length; i++)
         {
            _columnNameToIndex[_parquet.Schema[i].Name] = i;
         }
      }
   }
}