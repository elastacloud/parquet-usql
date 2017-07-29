using Microsoft.Analytics.Interfaces;
using Parquet.Data;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Parquet.Adla.Outputter
{
   class DataSetBuilder : IDisposable
   {
      private List<SchemaElement> _schema;
      private readonly List<Row> _rows = new List<Row>();
      private Stream _targetStream;
      private bool _isWrite;

      public DataSetBuilder()
      {
         _isWrite = true;
      }

      public void Add(IRow row, Stream targetStream)
      {
         _targetStream = targetStream;

         if (_schema == null) BuildSchema(row);

         _rows.Add(ToRow(row));
      }

      public void Dispose()
      {
         if (!_isWrite)
            return;

         var ds = new DataSet(_schema.ToArray());
         ds.AddRange(_rows);

         //parquet needs to be written in memory first as ADLA doesn't support seekable streams

         using (var ms = new MemoryStream())
         {
            using (var parquet = new ParquetWriter(ms))
            {
               parquet.Write(ds);
            }

            ms.Position = 0;
            ms.CopyTo(_targetStream);
         }
      }

      private void BuildSchema(IRow row)
      {
         _schema = new List<SchemaElement>();

         foreach(IColumn column in row.Schema)
         {
            var se = new SchemaElement(column.Name, column.Type);
            _schema.Add(se);
         }
      }

      private Row ToRow(IRow row)
      {
         //you can get any type as object, it will be just unboxed

         var pqRow = new List<object>();
         for (int i = 0; i < _schema.Count; i++)
         {
            object value = row.Get<object>(i);
            pqRow.Add(value);
         }

         return new Row(pqRow);
      }
   }
}
