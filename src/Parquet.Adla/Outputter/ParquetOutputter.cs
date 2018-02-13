using Microsoft.Analytics.Interfaces;

namespace Parquet.Adla.Outputter
{
   [SqlUserDefinedOutputter(AtomicFileProcessing = true)]
   public class ParquetOutputter : IOutputter
   {
      private readonly DataSetBuilder _builder = new DataSetBuilder();

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