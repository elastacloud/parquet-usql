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
      private const int RowGroupSize = 1000;
      private List<DataField> _schema;
      private DataSet _ds;
      private ParquetWriter _writer;

      public DataSetBuilder()
      {
      }

      public void Add(IRow row, Stream targetStream)
      {
         if (_writer == null) BuildWriter(row.Schema, targetStream);

         if(_ds == null) _ds = new DataSet(_schema);

         _ds.Add(ToRow(row));

         if (_ds.Count >= RowGroupSize)
         {
            FlushDataSet();
         }
      }

      private void FlushDataSet()
      {
         if (_ds == null) return;

         _writer.Write(_ds);

         _ds = null;
      }

      private void BuildWriter(ISchema schema, Stream targetStream)
      {
         _schema = new List<DataField>();

         foreach (IColumn column in schema)
         {
            var se = new DataField(column.Name, column.Type);
            _schema.Add(se);
         }

         _writer = new ParquetWriter(targetStream);
      }

      private void BuildSchema(IRow row)
      {
         _schema = new List<DataField>();

         foreach(IColumn column in row.Schema)
         {
            var se = new DataField(column.Name, column.Type);
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

      public void Dispose()
      {
         if (_writer == null) return;

         FlushDataSet();
         _writer.Dispose();
         _writer = null;
      }
   }
}
