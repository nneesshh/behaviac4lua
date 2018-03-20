using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Text;
using PluginBehaviacJson.Nodes;
using PluginBehaviacJson.Properties;
using Behaviac.Design;
using Behaviac.Design.Attributes;
using Behaviac.Design.Nodes;

namespace PluginBehaviacJson.decoratorEveryTime
{
    [NodeDesc("Decorators", NodeIcon.Decorator)]
    class EveryTime : Behaviac.Design.Nodes.Decorator
    {
        public EveryTime() : base(Resources.EveryTime, Resources.EveryTimeDesc)
        {

        }

        public override string ExportClass
        {
            get { return "DecoratorEveryTime"; }
        }

        private VariableDef _time = new VariableDef(1000);
        [DesignerPropertyEnum("Time", "间隔时间,毫秒", "CategoryBasic", DesignerProperty.DisplayMode.Parameter, 0, DesignerProperty.DesignerFlags.NoFlags, DesignerPropertyEnum.AllowStyles.ConstAttributes, "", "", ValueTypes.Int)]
        public VariableDef Time
        {
            get { return _time; }
            set { this._time = value; }
        }

        protected override void CloneProperties(Node newnode)
        {
            base.CloneProperties(newnode);

            EveryTime dec = (EveryTime)newnode;
            if (_time != null)
            {
                dec._time = (VariableDef)_time.Clone();
            }
        }
    }
}
