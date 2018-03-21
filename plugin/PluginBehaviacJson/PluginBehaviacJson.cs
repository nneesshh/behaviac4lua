using System;
using System.Reflection;
using System.Collections.Generic;
using System.Text;
using Behaviac.Design;
using PluginBehaviacJson.Properties;

namespace PluginBehaviacJson
{
    /// <summary>
    /// The plugin is loaded when you start the editor.
    /// The name for your plugin must be like as following.
    /// </summary>
    public class Plugin : Behaviac.Design.Plugin
    {
        public Plugin()
        {
            // register resource manager
            AddResourceManager(Resources.ResourceManager);

            // register all the exporters
            Exporters.Add(new ExporterInfo(typeof(Exporters.ExporterJson), "json", "Json", true));
        }
    }
}
