using System;
using System.Collections.Generic;
using System.Text;
using System.IO;

using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

using Behaviac.Design.Nodes;
using Behaviac.Design.Attributes;
using Behaviac.Design.Attachments;
using Behaviac.Design.FileManagers;

using PluginBehaviacJson.Properties;

namespace PluginBehaviacJson.Exporters
{
    /// <summary>
    /// This exporter generates .cs files which generate a static variable which holds the behaviour tree.
    /// </summary>
    public class ExporterJson : Behaviac.Design.Exporters.Exporter
    {
        protected static string __usedNamespace = "Behaviac.Behaviors";

        /// <summary>
        /// The namespace the behaviours will be exported to.
        /// </summary>
        public static string UsedNamespace
        {
            get
            {
                return __usedNamespace;
            }
            set
            {
                __usedNamespace = value;
            }
        }

        public ExporterJson(BehaviorNode node, string outputFolder, string filename, List<string> includedFilenames = null)
        : base(node, outputFolder, filename + ".json", includedFilenames)
        {
        }

        /// <summary>
        /// Exports a behaviour to the given file.
        /// </summary>
        /// <param name="file">The file we want to export to.</param>
        /// <param name="b">The behaviour we want to export.</param>
        protected void ExportBehavior(JObject file, BehaviorNode b)
        {
            if (b.FileManager == null)
            {
                return;
            }

            //file.WriteComment("EXPORTED BY TOOL, DON'T MODIFY IT!");
            //file.WriteComment("Source File: " + behavior.MakeRelative(behavior.FileManager.Filename));

            JObject behavior1 = new JObject();
            file.Add("behavior", behavior1);

            Behavior root = b as Behavior;
            Behaviac.Design.Debug.Check(root != null);
            Behaviac.Design.Debug.Check(root.Id == -1);

            //'\\' ->'/'
            string behaviorName = root.MakeRelative(root.Filename);
            behaviorName = behaviorName.Replace('\\', '/');
            int pos = behaviorName.IndexOf(".xml");

            if (pos != -1)
            {
                behaviorName = behaviorName.Remove(pos);
            }

            behavior1.Add("name", behaviorName);
            //file.WriteAttributeString("event", b.EventName);
            behavior1.Add("agenttype", root.AgentType.Name);

            if (root.IsFSM)
            {
                behavior1.Add("fsm", true);
            }

            behavior1.Add("version", root.Version.ToString());

            this.ExportProperties(behavior1, root);

            this.ExportPars(behavior1, root);

            if (!root.IsFSM)
            {
                this.ExportAttachments(behavior1, root);
            }

#if QUERY_EANBLED
            //after ExportProperties as DescritorRefs are exported as property
            this.ExportDescritorRefs(file, b);
#endif//#if QUERY_EANBLED

            if (root.IsFSM)
            {
                JObject node1 = new JObject();
                behavior1.Add("node", node1);

                node1.Add("class", "FSM");
                node1.Add("id", -1);

                JObject properties1 = new JObject();
                node1.Add("properties", properties1);

                properties1.Add("initialid", b.InitialStateId.ToString());

                foreach (Node child in((Node)b).FSMNodes)
                {
                    this.ExportNode(node1, b, child);
                }
            }
            else
            {
                // export the children
                foreach (Node child in((Node)b).Children)
                {
                    this.ExportNode(behavior1, b, child);
                }
            }
        }

        private void ExportPars(JObject file, Behavior root)
        {
            if (root.LocalVars.Count == 0)
            {
                return;
            }

            JArray pars1 = new JArray();
            file.Add("pars", pars1);

            for (int i = 0; i < root.LocalVars.Count; ++i)
            {
                Behaviac.Design.ParInfo par = root.LocalVars[i];

                WritePar(pars1, par, true);
            }
        }

#if QUERY_EANBLED
        private void ExportDescritorRefs(JObject file, Behavior b)
        {
            //if (Plugin.IsQueryFiltered)
            //{
            //    return;
            //}

             if (b.DescriptorRefs.Count > 0)
            {
                string propValue = DesignerArray.RetrieveExportValue(b.DescriptorRefs);
                file.Add("DescriptorRefs", propValue);
            }

            string propValue2 = b.Domains;

            if (!string.IsNullOrEmpty(propValue2))
            {
                file.Add("Domains", propValue2);
            }
        }
#endif//#endif//#if QUERY_EANBLED

        /// <summary>
        /// Exports a node to the given file.
        /// </summary>
        /// <param name="file">The file we want to export to.</param>
        /// <param name="b">The behaviour node we are currently exporting.</param>
        /// <param name="n">The node we want to export.</param>
        protected void ExportNode(JObject file, BehaviorNode b, Node n)
        {
            if (!n.Enable)
            {
                return;
            }

            JObject node1 = new JObject();
            file.Add("node", node1);

            node1.Add("class", n.ExportClass);
            node1.Add("id", n.Id.ToString());

            this.ExportProperties(node1, n);
            this.ExportAttachments(node1, n);

            if (!n.IsFSM && !(n is ReferencedBehavior))
            {
                JArray children1 = new JArray();
                node1.Add("children", children1);

                // export the child nodes
                foreach (Node c in n.Children)
                {
                    if (!n.GetConnector(c).IsAsChild)
                    {
                        JObject custom1 = new JObject();
                        JObject property1 = new JObject();
                        property1.Add("custom", custom1);
                        children1.Add(property1);

                        this.ExportNode(custom1, b, c);
                    }
                    else
                    {
                        JObject child1 = new JObject();
                        children1.Add(child1);

                        this.ExportNode(child1, b, c);
                    }
                }
            }
        }

        /// <summary>
        /// Exports node properties 
        /// </summary>
        /// <param name="file"></param>
        /// <param name="n"></param>
        private void ExportProperties(JObject file, Node n)
        {
            IList<DesignerPropertyInfo> properties = n.GetDesignerProperties();

            JArray properties1 = new JArray();
            file.Add("properties", properties1);

            foreach (DesignerPropertyInfo p in properties)
            {
                // we skip properties which are not marked to be exported
                if (p.Attribute.HasFlags(DesignerProperty.DesignerFlags.NoExport))
                {
                    continue;
                }

                object v = p.Property.GetValue(n, null);
                bool bExport = !Plugin.IsExportArray(v);

                if (bExport)
                {

                    // create the code which assigns the value to the node's property
                    //file.Write(string.Format("{0}\t{1}.{2} = {3};\r\n", indent, nodeName, properties[p].Property.Name, properties[p].GetExportValue(node)));
                    string propValue = p.GetExportValue(n);

                    if (propValue != string.Empty && propValue != "\"\"")
                    {
                        WriteProperty(properties1, p, n);
                    }
                }
            }

            if (n is Task)
            {
                Task task = n as Task;
                properties1.Add(new JObject { { "IsHTN", task.IsHTN ? "true" : "false" } });
            }

#if QUERY_EANBLED
            Behavior b = n as Behavior;

            if (b != null)
            {
                this.ExportDescritorRefs(properties1, b);
            }

#endif
        }

        /// <summary>
        /// Exports attachment properties
        /// </summary>
        /// <param name="file"></param>
        /// <param name="a"></param>
        private void ExportProperties(JObject file, Attachment a)
        {
            DesignerPropertyInfo propertyEffector = new DesignerPropertyInfo();
            IList<DesignerPropertyInfo> properties = a.GetDesignerProperties(true);

            JArray properties1 = new JArray();
            file.Add("properties", properties1);

            foreach (DesignerPropertyInfo p in properties)
            {
                // we skip properties which are not marked to be exported
                if (p.Attribute.HasFlags(DesignerProperty.DesignerFlags.NoExport))
                {
                    continue;
                }

                object v = p.Property.GetValue(a, null);
                bool bExport = !Plugin.IsExportArray(v);

                if (bExport)
                {
                    if (p.Property.Name == "Effectors")
                    {
                        propertyEffector = p;
                    }
                    else
                    {
                        WriteProperty(properties1, p, a);
                    }
                }
            }

            if (propertyEffector.Property != null)
            {
                List<TransitionEffector> listV = (List<TransitionEffector>)propertyEffector.Property.GetValue(a, null);

                if (listV != null)
                {
                    JArray attachments1 = new JArray();
                    file.Add("attachments", attachments1);

                    foreach (TransitionEffector te in listV)
                    {
                        IList<DesignerPropertyInfo> effectorProperties = te.GetDesignerProperties();
                        JObject attachment1 = new JObject();
                        attachments1.Add(attachment1);

                        JArray properties2 = new JArray();
                        attachment1.Add("properties", properties2);

                        foreach (DesignerPropertyInfo p in effectorProperties)
                        {
                            // we skip properties which are not marked to be exported
                            if (p.Attribute.HasFlags(DesignerProperty.DesignerFlags.NoExport))
                            {
                                continue;
                            }

                            WriteProperty(properties2, p, te);
                        }
                    }
                }
            }
        }

        /// <summary>
        /// Exports attachments
        /// </summary>
        /// <param name="file"></param>
        /// <param name="n"></param>
        protected void ExportAttachments(JObject file, Node n)
        {
            //int localVars = ReferencedBehaviorLocalVars(node);
            int localVars = 0;

            if (n.Attachments.Count > 0 || localVars > 0)
            {
                JArray attachments1 = new JArray();
                file.Add("attachments", attachments1);

                //this.ExportReferencedBehaviorLocalVars(node, attachments1);

                foreach (Attachment a in n.Attachments)
                {
                    if (!a.Enable)
                    {
                        continue;
                    }

                    JObject attachment1 = new JObject();
                    attachments1.Add(attachment1);

                    Type type = a.GetType();

                    attachment1.Add("class", a.ExportClass);
                    attachment1.Add("id", a.Id.ToString());
                    attachment1.Add("precondition", a.IsPrecondition);

                    bool bIsEffector = a.IsEffector;

                    if (a.IsTransition)
                    {
                        bIsEffector = false;
                    }

                    attachment1.Add("effector", bIsEffector);
                    attachment1.Add("transition", a.IsTransition);
                    attachment1.Add("event", !a.IsPrecondition && !bIsEffector);

                    this.ExportProperties(attachment1, a);

                    //this.ExportEventLocalVars(a, attachment1);
                }
            }
        }

        /// <summary>
        /// WritePar
        /// </summary>
        /// <param name="file"></param>
        /// <param name="par"></param>
        /// <param name="bExportValue"></param>
        static private void WritePar(JArray file, Behaviac.Design.ParInfo par, bool bExportValue)
        {
            JObject par1 = new JObject();
            file.Add(par1);

            par1.Add("name", par.BasicName);
            par1.Add("type", par.NativeType);

            if (bExportValue)
            {
                par1.Add("value", par.DefaultValue);
            }
        }

        /// <summary>
        /// WriteProperty
        /// </summary>
        /// <param name="file"></param>
        /// <param name="p"></param>
        /// <param name="o"></param>
        static private void WriteProperty(JArray file, DesignerPropertyInfo p, object o)
        {
            //WritePropertyValue(file, property, o);

            string name = p.Property.Name;
            string str = p.GetExportValue(o);
            file.Add(new JObject { { name, str } });
        }

        /// <summary>
        /// WritePropertyValue
        /// </summary>
        /// <param name="file"></param>
        /// <param name="p"></param>
        /// <param name="o"></param>
        static private void WritePropertyValue(JArray file, DesignerPropertyInfo p, object o)
        {
            string str = p.GetExportValue(o);
            string[] tokens = str.Split(' ');
            string valueString = null;

            if (tokens.Length == 3 && tokens[0] == "const")
            {
                valueString = tokens[2];

            }
            else if (tokens.Length == 1)
            {
                valueString = str;
            }

            bool bW = false;

            if (valueString != null)
            {
                object obj = p.Property.GetValue(o, null);

                object v = null;

                Type valueType = null;
                Behaviac.Design.VariableDef varType = obj as Behaviac.Design.VariableDef;

                if (varType != null)
                {
                    valueType = varType.ValueType;

                }
                else
                {
                    Behaviac.Design.RightValueDef rvarType = obj as Behaviac.Design.RightValueDef;

                    if (rvarType != null)
                    {
                        if (rvarType.Method == null)
                        {
                            valueType = rvarType.ValueType;
                        }

                    }
                    else
                    {
                        Behaviac.Design.MethodDef mType = obj as Behaviac.Design.MethodDef;

                        if (mType != null)
                        {
                            Behaviac.Design.Debug.Check(true);

                        }
                        else
                        {
                            valueType = obj.GetType();
                        }
                    }
                }

                if (valueType != null && Plugin.InvokeTypeParser(null, valueType, valueString, (object value) => v = value, null))
                {
                    file.Add(new JObject { { p.Property.Name, JsonConvert.SerializeObject(v) } });
                    bW = true;
                }
            }

            if (!bW)
            {
                file.Add(new JObject { { p.Property.Name, str } });
            }
        }

        /// <summary>
        /// Export the assigned node to the assigned file.
        /// </summary>
        /// <returns>Returns the result when the behaviour is exported.</returns>
        public override SaveResult Export()
        {
            string filename = Path.Combine(_outputFolder, _filename);
            SaveResult result = FileManager.MakeWritable(filename, Resources.ExportFileWarning);

            if (SaveResult.Succeeded != result)
            {
                return result;
            }

            // get the abolute folder of the file we want toexport
            string folder = Path.GetDirectoryName(filename);

            if (!Directory.Exists(folder))
            {
                Directory.CreateDirectory(folder);
            }

            // export to the file
            { 
                JObject root = new JObject();
                ExportBehavior(root, _node);

                // pretty print
                string sPrettyPrint = JsonConvert.SerializeObject(root, Formatting.Indented);
                using (StreamWriter sw = new StreamWriter(filename, false, Encoding.UTF8))
                {
                    sw.Write(sPrettyPrint);
                    sw.Close();
                }
            }
            return SaveResult.Succeeded;
        }
    }
}
