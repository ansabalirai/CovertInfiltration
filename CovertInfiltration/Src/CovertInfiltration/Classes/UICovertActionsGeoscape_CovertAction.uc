//---------------------------------------------------------------------------------------
//  AUTHOR:  Xymanek
//  PURPOSE: This is a single entry for a CA in the UICovertActionsGeoscape screen's list
//---------------------------------------------------------------------------------------
//  WOTCStrategyOverhaul Team
//---------------------------------------------------------------------------------------

class UICovertActionsGeoscape_CovertAction extends UIListItemString;

var protectedwrite XComGameState_CovertAction Action;

simulated function InitCovertAction(XComGameState_CovertAction InAction)
{
	Action = InAction;
	InitListItem(GetActionLocString());
	NeedsAttention(class'X2Helper_Infiltration'.static.IsInfiltrationAction(Action));
}

// Copied from UICovertActions
simulated function String GetActionLocString()
{
	local string PrefixStr;

	if(Action.bNewAction)
	{
		PrefixStr = class'UICovertActions'.default.CovertActions_NewAction;
	}

	return PrefixStr $ Action.GetObjective();
}

defaultproperties
{
	bAnimateOnInit = false; // Animated by the whole list
}