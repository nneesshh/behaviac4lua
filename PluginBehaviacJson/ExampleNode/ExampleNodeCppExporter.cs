using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using Behaviac.Design;
using Behaviac.Design.Nodes;
using PluginBehaviac.NodeExporters;
using PluginBehaviacJson.Nodes;

namespace PluginBehaviacJson.NodeExporters
{
    public class ExampleNodeCppExporter : NodeCppExporter
    {
        protected override bool ShouldGenerateClass(Node node)
        {
            return true;
        }

        protected override void GenerateConstructor(Node node, StringWriter stream, string indent, string className)
        {
            base.GenerateConstructor(node, stream, indent, className);

            ExampleNode wait = node as ExampleNode;
            Debug.Check(wait != null);

            stream.WriteLine("{0}\t\t\tm_ignoreTimeScale = {1};", indent, wait.IgnoreTimeScale ? "true" : "false");
        }

        protected override void GenerateMethod(Node node, StringWriter stream, string indent)
        {
            base.GenerateMethod(node, stream, indent);

            ExampleNode wait = node as ExampleNode;
            Debug.Check(wait != null);

            if (wait.Time != null)
            {
                stream.WriteLine("{0}\t\tvirtual float GetTime(Agent* pAgent) const", indent);
                stream.WriteLine("{0}\t\t{{", indent);
                stream.WriteLine("{0}\t\t\tBEHAVIAC_UNUSED_VAR(pAgent);", indent);

                //string retStr = VariableCppExporter.GenerateCode(wait.Time, stream, indent + "\t\t\t", string.Empty, string.Empty, string.Empty);
                string retStr = "";

                stream.WriteLine("{0}\t\t\treturn {1};", indent, retStr);
                stream.WriteLine("{0}\t\t}}", indent);
            }
        }
    }
}
