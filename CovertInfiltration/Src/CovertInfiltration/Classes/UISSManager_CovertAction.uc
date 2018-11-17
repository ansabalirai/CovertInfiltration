//---------------------------------------------------------------------------------------
//  AUTHOR:  Xymanek
//  PURPOSE: This is responsible for adjusting squad select screen to behave suitable for
//           covert action intstead of a mission. It relies heavily on SSAAT to do the
//           heavy lifting
//---------------------------------------------------------------------------------------
//  WOTCStrategyOverhaul Team
//---------------------------------------------------------------------------------------

class UISSManager_CovertAction extends Object;

var UICovertActionsGeoscape CovertOpsScreen;
var bool SkipIntro;

var protected SSAAT_SquadSelectConfiguration Configuration;
var protectedwrite UISquadSelect SquadSelect;

var protected bool bCreatedUIElements;
var protected UISS_CovertActionRisks RisksDisplay;

var localized string strSlotOptionalNote;
var localized string strSlotRequiredPrefix;

simulated function OpenSquadSelect()
{
	BuildConfiguration();
	SubscribeToEvents();

	SquadSelect = class'SSAAT_Opener'.static.ShowSquadSelect(Configuration);
	PostScreenInit();
}

simulated protected function PostScreenInit()
{
	local UISS_CovertActionInfo ActionInfo;

	ActionInfo = SquadSelect.Spawn(class'UISS_CovertActionInfo', SquadSelect);
	ActionInfo.bAnimateOnInit = false;
	ActionInfo.InitCovertActionInfo('CovertActionInfo');
	ActionInfo.UpdateData(GetAction());
	
	RisksDisplay = SquadSelect.Spawn(class'UISS_CovertActionRisks', SquadSelect);
	RisksDisplay.InitRisks();

	bCreatedUIElements = true;
	UpdateUIElements();
}

simulated protected function BuildConfiguration()
{
	local XComGameStateHistory History;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_CovertAction CovertAction;
	local XComGameState_Reward RewardState;

	local array<SSAAT_SlotConfiguration> Slots;
	local int i;

	Configuration = new class'SSAAT_SquadSelectConfiguration';
	History = `XCOMHISTORY;

	CovertAction = GetAction();
	
	Slots.Length = CovertAction.StaffSlots.Length;

	for (i = 0; i < Slots.Length; ++i)
	{
		StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(CovertAction.StaffSlots[i].StaffSlotRef.ObjectID));
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(CovertAction.StaffSlots[i].RewardRef.ObjectID));

		if (RewardState != none) Slots[i].Notes.AddItem(ConvertRewardToNote(RewardState));
		if (CovertAction.StaffSlots[i].bOptional) Slots[i].Notes.AddItem(CreateOptionalNote());
		if (StaffSlotState.RequiredClass != '') Slots[i].Notes.AddItem(CreateClassNote(StaffSlotState.RequiredClass));
		// The original covert action staff slot code never passed a class here. We're passing one. If `RequiredClass` == '' or the class doesn't
		// have explicit rank names set up, it'll use the standard code path of falling back to the default ranks.
		if (StaffSlotState.RequiredMinRank > 0) Slots[i].Notes.AddItem(CreateRankNote(StaffSlotState.RequiredMinRank, StaffSlotState.RequiredClass));
		

		// Change the slot type if needed
		if (StaffSlotState.IsEngineerSlot())
		{
			Slots[i].PersonnelType = eUIPersonnel_Engineers;
		}
		else if (StaffSlotState.IsScientistSlot())
		{
			Slots[i].PersonnelType = eUIPersonnel_Scientists;
		}

		Slots[i].CanUnitBeSelectedFn = CanSelectUnit;
	}

	Configuration.SetDisallowAutoFill(true);
	Configuration.SetSkipIntroAnimation(SkipIntro);

	Configuration.SetSlots(Slots);
	Configuration.SetHideMissionInfo(true);
	Configuration.RemoveTerrainAndEnemiesPanels();
	
	Configuration.SetCanClickLaunchFn(CanClickLaunch);
	Configuration.SetLaunchBehaviour(OnLaunch, false);
	
	Configuration.SetPreventOnSizeLimitedEvent(true);
	Configuration.SetPreventOnSuperSizeEvent(true);

	Configuration.SetFrozen();
}

///////////////////
/// UI Elements ///
///////////////////

simulated protected function UpdateUIElements()
{
	RisksDisplay.UpdateData(GetAction());
}

//////////////////
/// Slot notes ///
//////////////////

static function SSAAT_SlotNote ConvertRewardToNote(XComGameState_Reward RewardState)
{
	local SSAAT_SlotNote Note;
	local string RewardText;

	RewardText = RewardState.GetRewardPreviewString();
	if (RewardText != "" && RewardState.GetMyTemplateName() != 'Reward_DecreaseRisk')
	{
		RewardText = class'UICovertActionStaffSlot'.default.m_strSoldierReward @ RewardText;
	}

	Note.Text = RewardText;
	Note.TextColor = "000000";
	Note.BGColor = class'UIUtilities_Colors'.const.GOOD_HTML_COLOR;

	return Note;
}

static function SSAAT_SlotNote CreateOptionalNote()
{
	local SSAAT_SlotNote Note;
	
	Note.Text = default.strSlotOptionalNote; // The localized text reads "OPTIONAL:"
	Note.TextColor = "000000";
	Note.BGColor = class'UIUtilities_Colors'.const.WARNING_HTML_COLOR;

	return Note;
}

static function SSAAT_SlotNote CreateClassNote(name SoldierClassName)
{
	local SSAAT_SlotNote Note;
	local X2SoldierClassTemplateManager ClassManager;
	local X2SoldierClassTemplate ClassTemplate;
	local string DisplayString;

	ClassManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	ClassTemplate = ClassManager.FindSoldierClassTemplate(SoldierClassName);

	if (ClassTemplate != none)
	{
		DisplayString = ClassTemplate.DisplayName;
	}

	Note.Text = default.strSlotRequiredPrefix @ DisplayString;
	Note.TextColor = "000000";
	Note.BGColor = class'UIUtilities_Colors'.const.WARNING_HTML_COLOR;

	return Note;
}

static function SSAAT_SlotNote CreateRankNote(int Rank, name SoldierClassName)
{
	local SSAAT_SlotNote Note;
	
	Note.Text = default.strSlotRequiredPrefix @ class'X2ExperienceConfig'.static.GetRankName(Rank, SoldierClassName);
	Note.TextColor = "000000";
	Note.BGColor = class'UIUtilities_Colors'.const.WARNING_HTML_COLOR;

	return Note;
}

////////////////////////
/// Slot interaction ///
////////////////////////

simulated protected function bool CanSelectUnit(XComGameState_Unit Unit, int iSlot)
{
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(GetAction().StaffSlots[iSlot].StaffSlotRef.ObjectID));
	
	return StaffSlotState.ValidUnitForSlot(CreateStaffInfo(Unit.GetReference()));
}

simulated protected function StaffUnitInfo CreateStaffInfo(StateObjectReference UnitRef)
{
	local StaffUnitInfo StaffInfo;

	StaffInfo.UnitRef = UnitRef;
	StaffInfo.bGhostUnit = false;

	return StaffInfo;
}

simulated protected function EventListenerReturn OnSquadSelectUpdate(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XcomHQ;
	local XComGameState_StaffSlot StaffSlot;

	local StateObjectReference UnitRef;
	local CovertActionStaffSlot CovertActionSlot;
	
	local bool IsSlotFilled;
	local int i;

	History = `XCOMHISTORY;
	XcomHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	foreach XcomHQ.Squad(UnitRef, i)
	{
		CovertActionSlot = GetAction().StaffSlots[i];
		StaffSlot = XComGameState_StaffSlot(History.GetGameStateForObjectID(CovertActionSlot.StaffSlotRef.ObjectID));
		IsSlotFilled = UnitRef.ObjectID != 0;

		// Do nothing if evrything is correct already
		if (UnitRef.ObjectID == StaffSlot.AssignedStaff.UnitRef.ObjectID) continue;

		if (IsSlotFilled)
		{
			StaffSlot.AssignStaffToSlot(CreateStaffInfo(UnitRef));
		}
		else
		{	
			StaffSlot.EmptySlot();
		}
	}

	if (bCreatedUIElements) UpdateUIElements();

	return ELR_NoInterrupt;
}

//////////////
/// Launch ///
//////////////

simulated protected function bool CanClickLaunch()
{
	return GetAction().CanBeginAction();	
}

simulated protected function OnLaunch()
{
	SquadSelect = none;
	UnsubscribeFromAllEvents();

	GetAction().ConfirmAction();
	
	CovertOpsScreen.FocusCameraOnCurrentAction(); // Look at covert action instead of region
	CovertOpsScreen.MakeMapProperlyShow();

	CovertOpsScreen.bConfirmScreenWasOpened = true;
}

////////////////////////////////////
/// Event interaction management ///
////////////////////////////////////

simulated protected function SubscribeToEvents()
{
	local X2EventManager EventManager;
	local Object ThisObj;

	EventManager = `XEVENTMGR;
    ThisObj = self;

	EventManager.RegisterForEvent(ThisObj, 'rjSquadSelect_UpdateData', OnSquadSelectUpdate);
}

simulated protected function UnsubscribeFromAllEvents()
{
    local Object ThisObj;

    ThisObj = self;
    `XEVENTMGR.UnRegisterFromAllEvents(ThisObj);
}

///////////////
/// Helpers ///
///////////////

simulated function XComGameState_CovertAction GetAction()
{
	return CovertOpsScreen.GetAction();
}