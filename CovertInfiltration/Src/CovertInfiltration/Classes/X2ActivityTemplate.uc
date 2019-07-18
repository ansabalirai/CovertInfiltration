//---------------------------------------------------------------------------------------
//  AUTHOR:  Xymanek
//  PURPOSE: Base template for an activity. An activity can be absolutely anything, eg.
//           missions, CA, etc. This template controls how the underlying state object
//           (ie. CA) is spawned and cleaned up, as well as any associated states
//           (ie. rewards). The properties here are used by the chain to intereact with
//           the activity, it's recommened to make a subclass for a concrete type of
//           activity (ie. CA) and add the specific properties there
//---------------------------------------------------------------------------------------
//  WOTCStrategyOverhaul Team
//---------------------------------------------------------------------------------------

class X2ActivityTemplate extends X2StrategyElementTemplate abstract config(Infiltration);

var class<XComGameState_Activity> StateClass;

/////////////////
/// Lifecycle ///
/////////////////

// Called right after the activity is instantiated - CANNOT rely on other activites in chain being instantiated yet
delegate SetupChainEarly(XComGameState NewGameState, XComGameState_Activity ActivityState);

// Called at start of the chain - all activities in chain are instantiated
delegate SetupChain(XComGameState NewGameState, XComGameState_Activity ActivityState);

// Called when this activity/stage is reached
delegate SetupStage(XComGameState NewGameState, XComGameState_Activity ActivityState);

// Called when this activity/stage is finished and no longer accessible by player
delegate CleanupStage(XComGameState NewGameState, XComGameState_Activity ActivityState);

// Same as before, but called next geoscape tick, right before the chain is notified
delegate CleanupStageDeffered(XComGameState NewGameState, XComGameState_Activity ActivityState);

// Called when the whole chain is finished and no longer accessible by player
delegate CleanupChain(XComGameState NewGameState, XComGameState_Activity ActivityState);

// Called after the activity has been completed and if the chain has a next stage
// If not set, true is assumed
delegate bool ShouldProgressChain(XComGameState_Activity ActivityState);

defaultproperties
{
	StateClass = class'XComGameState_Activity'
}