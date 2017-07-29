using Microsoft.Analytics.Interfaces;
using Microsoft.Analytics.Types.Sql;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Parquet;
using Parquet.Data;

namespace Parquet.Adla.Outputter
{
   [SqlUserDefinedOutputter(AtomicFileProcessing = true)]
   public class ParquetOutputter : IOutputter
   {
      private DataSetBuilder _builder = new DataSetBuilder();

      public override void Output(IRow input, IUnstructuredWriter output)
      {
         _builder.Add(input, output.BaseStream);
      }

      public override void Close()
      {
         _builder.Dispose();
      }
   }
}