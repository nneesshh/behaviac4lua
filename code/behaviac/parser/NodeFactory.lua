--- Behaviac lib Component: node factory.
-- @module NodeFactory.lua
-- @author n.lee
-- @copyright 2016
-- @license MIT/X11

local _M = {}

-- Localize
local pdir = (...):gsub('%.[^%.]+%.[^%.]+$', '') .. "."
local cwd = (...):gsub('%.[^%.]+$', '') .. "."

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------
-- core
_M.BaseNode                     = require(pdir .. "core.BaseNode")
_M.Branch                       = require(pdir .. "core.Branch")
_M.SingleChild                  = require(pdir .. "core.SingleChild")
_M.BehaviorTree                 = require(pdir .. "core.BehaviorTree")
_M.Composite                    = require(pdir .. "core.Composite")
_M.Decorator                    = require(pdir .. "core.Decorator")
_M.Leaf                         = require(pdir .. "core.Leaf")
_M.Action                       = require(pdir .. "core.Action")
_M.Condition                    = require(pdir .. "core.Condition")

-- attachments
_M.AttachAction                 = require(pdir .. "attachments.AttachAction")
_M.Effector                     = require(pdir .. "attachments.Effector")
_M.Event                        = require(pdir .. "attachments.Event")
_M.Precondition                 = require(pdir .. "attachments.Precondition")

-- node.actions
_M.Assignment                   = require(pdir .. "node.actions.Assignment")
_M.Compute                      = require(pdir .. "node.actions.Compute")
_M.End                          = require(pdir .. "node.actions.End")
_M.Noop                         = require(pdir .. "node.actions.Noop")
_M.Wait                         = require(pdir .. "node.actions.Wait")
_M.WaitForSignal                = require(pdir .. "node.actions.WaitForSignal")
_M.WaitFrames                   = require(pdir .. "node.actions.WaitFrames")

-- node.composites
_M.CompositeStochastic          = require(pdir .. "node.composites.CompositeStochastic")
_M.IfElse                       = require(pdir .. "node.composites.IfElse")
_M.Parallel                     = require(pdir .. "node.composites.Parallel")
_M.ReferencedBehavior           = require(pdir .. "node.composites.ReferencedBehavior")
_M.Selector                     = require(pdir .. "node.composites.Selector")
_M.SelectorLoop                 = require(pdir .. "node.composites.SelectorLoop")
_M.SelectorProbability          = require(pdir .. "node.composites.SelectorProbability")
_M.SelectorStochastic           = require(pdir .. "node.composites.SelectorStochastic")
_M.Sequence                     = require(pdir .. "node.composites.Sequence")
_M.SequenceStochastic           = require(pdir .. "node.composites.SequenceStochastic")
_M.WithPrecondition             = require(pdir .. "node.composites.WithPrecondition")

-- node.conditions
_M.And                          = require(pdir .. "node.conditions.And")
_M.False                        = require(pdir .. "node.conditions.False")
_M.Or                           = require(pdir .. "node.conditions.Or")
_M.True                         = require(pdir .. "node.conditions.True")

-- node.decorators
_M.DecoratorAlwaysFailure       = require(pdir .. "node.decorators.DecoratorAlwaysFailure")
_M.DecoratorAlwaysRunning       = require(pdir .. "node.decorators.DecoratorAlwaysRunning")
_M.DecoratorAlwaysSuccess       = require(pdir .. "node.decorators.DecoratorAlwaysSuccess")
_M.DecoratorCount               = require(pdir .. "node.decorators.DecoratorCount")
_M.DecoratorCountLimit          = require(pdir .. "node.decorators.DecoratorCountLimit")
_M.DecoratorCountOnce           = require(pdir .. "node.decorators.DecoratorCountOnce")
_M.DecoratorFailureUntil        = require(pdir .. "node.decorators.DecoratorFailureUntil")
_M.DecoratorFrames              = require(pdir .. "node.decorators.DecoratorFrames")
_M.DecoratorIterator            = require(pdir .. "node.decorators.DecoratorIterator")
_M.DecoratorLog                 = require(pdir .. "node.decorators.DecoratorLog")
_M.DecoratorLoop                = require(pdir .. "node.decorators.DecoratorLoop")
_M.DecoratorLoopUntil           = require(pdir .. "node.decorators.DecoratorLoopUntil")
_M.DecoratorNot                 = require(pdir .. "node.decorators.DecoratorNot")
_M.DecoratorRepeat              = require(pdir .. "node.decorators.DecoratorRepeat")
_M.DecoratorSuccessUntil        = require(pdir .. "node.decorators.DecoratorSuccessUntil")
_M.DecoratorTime                = require(pdir .. "node.decorators.DecoratorTime")
_M.DecoratorEveryTime           = require(pdir .. "node.decorators.DecoratorEveryTime")
_M.DecoratorWeight              = require(pdir .. "node.decorators.DecoratorWeight")

-- fsm
_M.State                        = require(pdir .. "fsm.State")

-- htn
_M.Task                         = require(pdir .. "htn.Task")

return _M