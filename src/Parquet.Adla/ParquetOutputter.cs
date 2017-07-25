using Microsoft.Analytics.Interfaces;
using Microsoft.Analytics.Types.Sql;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Parquet;
using Parquet.Data;

namespace Parquet.Adla
{
    [SqlUserDefinedOutputter(AtomicFileProcessing = true)]
    public class ParquetOutputter : IOutputter
    {
        private DataSet _ds;
        private ParquetWriter _writer;
        private MemoryStream _tempStream;
        private Stream _resultStream;

        public override void Output(IRow input, IUnstructuredWriter output)
        {
            ISchema schema = input.Schema;

            if (_ds == null)
            {
                _ds = new DataSet(new SchemaElement<string>("test"));

                _tempStream = new MemoryStream();
                _resultStream = output.BaseStream;

                _writer = new ParquetWriter(_tempStream);

                //create DS based on schema
                //input.Schema
            }

            for (int i = 0; i < schema.Count; i++)
            {
                if (i == 0)
                {
                    object value = input.Get<object>(i);
                    string sv = value.ToString();
                    _ds.Add(sv);
                }

                //todo: add more
            }


        }

        public override void Close()
        {
            _writer.Write(_ds);
            _writer.Dispose();

            _tempStream.Position = 0;
            _tempStream.CopyTo(_resultStream);
        }
    }
}