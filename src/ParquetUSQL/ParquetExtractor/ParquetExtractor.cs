using Microsoft.Analytics.Interfaces;
using Microsoft.Analytics.Types.Sql;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace ParquetExtractor
{
   public class ParquetExtractor : IExtractor
   {
      public override IEnumerable<IRow> Extract(IUnstructuredReader input, IUpdatableRow output)
      {
         throw new NotImplementedException();
      }
   }
}