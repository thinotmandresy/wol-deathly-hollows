//==============================================================================
// Deathly Hollows scripted map by AlistairJah
//==============================================================================

// ============================================================================
// Debug. Not used in the final version.
// ============================================================================

rule Debug
inactive
runImmediately
{
    xsDisableSelf();
}


// ============================================================================
// Some useful functions
// ============================================================================

vector getMapCenter()
{
    int ctx = xsGetContextPlayer();
    xsSetContextPlayer(0);
    vector map_center = kbGetMapCenter();
    xsSetContextPlayer(ctx);

    return(map_center);
}

vector getUnitPosition(int unit_id = -1)
{
    int ctx = xsGetContextPlayer();
    xsSetContextPlayer(0);
    kbLookAtAllUnitsOnMap();
    vector unit_pos = kbUnitGetPosition(unit_id);
    xsSetContextPlayer(ctx);

    return(unit_pos);
}

int getUnit(int unit_type_id = -1, int owner_id = 1, vector location = cInvalidVector, float radius = 5000.0, int index = 0)
{
    int ctx = xsGetContextPlayer();
    xsSetContextPlayer(owner_id);
    kbLookAtAllUnitsOnMap();
    
    int unit_query_id = kbUnitQueryCreate("QuickUnitQuery");
    
    kbUnitQueryResetResults(unit_query_id);
    kbUnitQuerySetUnitType(unit_query_id, unit_type_id);
    kbUnitQuerySetState(unit_query_id, 2);

    if (location != cInvalidVector)
    {
        kbUnitQuerySetAscendingSort(unit_query_id, true);
        kbUnitQuerySetPosition(unit_query_id, location);
        kbUnitQuerySetMaximumDistance(unit_query_id, radius);
    }

    if (kbIsPlayerValid(owner_id) == true)
    {
        kbUnitQuerySetPlayerRelation(unit_query_id, -1);
        kbUnitQuerySetPlayerID(unit_query_id, owner_id, false);
    }
    else
    {
        kbUnitQuerySetPlayerID(unit_query_id, -1, false);
        kbUnitQuerySetPlayerRelation(unit_query_id, owner_id);
    }

    kbUnitQueryExecute(unit_query_id);

    int unit_id = kbUnitQueryGetResult(unit_query_id, index);
    kbUnitQueryDestroy(unit_query_id);
    xsSetContextPlayer(ctx);

    return(unit_id);
}

int getUnitCount(int unit_type_id = -1, int owner_id = -1, int state_id = 2)
{
    int ctx = xsGetContextPlayer();
    xsSetContextPlayer(owner_id);
    int count = kbUnitCount(owner_id, unit_type_id, state_id);
    xsSetContextPlayer(ctx);
    return(count);
}

// ============================================================================
// Initialization
// ============================================================================

rule Init
active
runImmediately
{
    xsDisableSelf();
    int i = 0;
    while(true)
    {
        if (kbGetUnitTypeName(i) == kbGetUnitTypeName(-1)) break;
        if (kbGetUnitTypeName(i) == "All") trQuestVarSet("UTypeAll", i);
        if (kbGetUnitTypeName(i) == "AbstractCavalry") trQuestVarSet("UTypeAbstractCavalry", i);
        i++;
    }
}

// ============================================================================
// Day/Night cycle
// ============================================================================

rule Night1
active
minInterval 1
runImmediately
{
    if (trTime() - cActivationTime < 300)
        return;

    xsDisableSelf();
    trSetLighting("spc14anight", 120);
    xsEnableRule("Eclipse");
}

rule Eclipse
inactive
minInterval 1
runImmediately
{
    if (trTime() - cActivationTime < 400)
        return;

    xsDisableSelf();
    trSetLighting("hollows_eclipse", 5);
    xsEnableRule("Night2");
}

rule Night2
inactive
minInterval 1
runImmediately
{
    if (trTime() - cActivationTime < 10)
        return;

    xsDisableSelf();
    trSetLighting("spc14anight", 5);
    xsEnableRule("Morning");
}

rule Morning
inactive
minInterval 1
runImmediately
{
    if (trTime() - cActivationTime < 300)
        return;

    xsDisableSelf();
    trSetLighting("316a_russians", 120);
    xsEnableRule("Day");
}

rule Day
inactive
minInterval 1
runImmediately
{
    if (trTime() - cActivationTime < 400)
        return;

    xsDisableSelf();
    trSetLighting("spc14a", 120);
    xsEnableRule("Night1");
}

// ============================================================================
// Warnings
// ============================================================================

rule Warning1
active
runImmediately
{
    xsDisableSelf();
    trMessageSetText("Old Native: Stranger! You must not settle here. I was left behind to warn explorers like you to avoid this cursed place.", 10000);
}

rule Warning2
active
minInterval 360
{
    xsDisableSelf();
    trMessageSetText("Old Native: This is your last chance! The sun sets, and soon Dullahan will rise and destroy the weakest of your colonies. Go!", 10000);
}

rule Warning3
active
minInterval 720
{
    xsDisableSelf();
    trMessageSetText("Old Native: It is too late. I can help you no longer. Goodbye.", 10000);
}

// ============================================================================
// Dullahan appearances
// ============================================================================

rule DullahanArrives
active
minInterval 720
{
    // --------------------------------------------------
    // Make the Dullahan appear at the map center
    // --------------------------------------------------

    static int level = -1;
    level = level + 1;
    string dullahan_unit = "Catastrophe";
         if (level == 0) dullahan_unit = "Catastrophe";
    else if (level == 1) dullahan_unit = "CatastropheStronger";
                    else dullahan_unit = "CatastropheStrongest";

    vector map_center = getMapCenter();
    trUnitCreate(dullahan_unit, "Default", xsVectorGetX(map_center), 0.0, xsVectorGetZ(map_center), 0, 0);
    
    // --------------------------------------------------
    // Find the weakest player (to be the Dullahan's target)
    // --------------------------------------------------

    trQuestVarSet("HollowsWeakestPlayer", -1);
    int weakest_player_pop = 999999;
    for (i = 1; < 9)
    {
        if (kbIsPlayerValid(i) == false) break;
        int pop = trPlayerGetPopulation(i);
        if (pop < weakest_player_pop)
        {
            trQuestVarSet("HollowsWeakestPlayer", i);
            weakest_player_pop = pop;
        }
    }
    
    // --------------------------------------------------
    // Play the Dullahan's theme music
    // --------------------------------------------------
    trMusicPlay("Wotta\Music\Modes\Dullahanstheme.mp3", "", 4.0);
    trSoundPlayFN("Wotta\Catastrophe\CATASTROPHElaugh2.wav", "", -1, "","");

    // --------------------------------------------------
    // Shut down after the 3rd appearance
    // --------------------------------------------------
    if (level == 2) xsDisableSelf();
}

rule DullahanAttacks
active
minInterval 5
{
    if (getUnitCount(trQuestVarGet("UTypeAbstractCavalry"), 0, 2) == 0)
        return;
    
    int dullahan = getUnit(trQuestVarGet("UTypeAbstractCavalry"), 0);
    int target = getUnit(trQuestVarGet("UTypeAll"), trQuestVarGet("HollowsWeakestPlayer"), kbGetMapCenter());
    vector target_pos = getUnitPosition(target);

    trUnitSelectClear();
    trUnitSelectByID(dullahan);
    if (trUnitDistanceToUnit("" + target) > 15) {
        trUnitMoveToPoint(xsVectorGetX(target_pos), 0, xsVectorGetZ(target_pos), -1, true);
    } else {
        trUnitDoWorkOnUnit("" + target);
    }
}
