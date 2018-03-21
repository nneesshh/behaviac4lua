using System;
using System.Collections.Generic;
using System.Text;
using PluginBehaviacJson.Properties;
using Behaviac.Design;
using Behaviac.Design.Attributes;
using Behaviac.Design.Nodes;

namespace PluginBehaviacJson.Nodes
{
    [NodeDesc("Decorators", NodeIcon.Decorator)]
    class CountOnce : Behaviac.Design.Nodes.Decorator
    {
        public CountOnce() : base(Resources.CountOnce, Resources.CountOnceDesc)
        {

        }

        public override string ExportClass
        {
            get { return "DecoratorCountOnce"; }
        }

        private VariableDef _count = new VariableDef(1);
        [DesignerPropertyEnum("Count", "执行次数", "CategoryBasic", DesignerProperty.DisplayMode.Parameter, 0, DesignerProperty.DesignerFlags.NoFlags, DesignerPropertyEnum.AllowStyles.ConstAttributes, "", "", ValueTypes.Int)]
        public VariableDef Count
        {
            get { return _count; }
            set { this._count = value; }
        }

        protected override void CloneProperties(Node newnode)
        {
            base.CloneProperties(newnode);

            CountOnce dec = (CountOnce)newnode;
            if (_count != null)
            {
                dec._count = (VariableDef)_count.Clone();
            }
        }
    }
}
