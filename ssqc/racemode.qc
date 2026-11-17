// ============================================================================
// QWTF Live - Standalone Race Mode
// ============================================================================
// Features:
// - Single active racer at a time, auto-assigned to Blue team (team_no = 1)
// - Everyone else waits in an automatic FIFO spectator queue until their turn
// - Deterministic Blue spawn selection (always uses the exact same Blue spawn)
// - Class selection allowed before countdown starts
// - 15-second ready timer upon joining Blue team; moves player to back of queue
//   if 'race' is not typed within 15 seconds
// - 'race' starts a 3-second countdown in spawn with movement/weapons frozen
// - High-precision timer starts in spawn at the end of countdown and stops on
//   flag capture (with flag pickup split tracking)
// - 'unrace' abandons the current run at any time
// - Built-in Top 10 leaderboard persistence per map + JSON/Webhook export
// ============================================================================

#define MAX_RACE_RECORDS 10
#define RACE_MAX_RUN_TIME 90.0

struct RaceRecord {
    float rec_time;
    float rec_split;
    string racer;
    float playerclass;
    string date;
};

static RaceRecord map_records[MAX_RACE_RECORDS];
static float num_map_records;

string (float sec) Race_FormatTime = {
    if (sec <= 0)
        return "0.000s";
    float mins = floor(sec / 60);
    float rem = sec - (mins * 60);
    if (mins > 0) {
        return sprintf("%d:%06.3f", mins, rem);
    }
    return sprintf("%0.3fs", rem);
};

static string () Race_RecordFilePath = {
    return strcat("race_", mapname, ".dat");
};

static string () Race_JsonFilePath = {
    return strcat("race_top10_", mapname, ".json");
};

static void () Race_SaveRecords = {
    float fd = fopen(Race_RecordFilePath(), FILE_WRITE);
    if (fd >= 0) {
        for (float i = 0; i < num_map_records; i++) {
            fputs(fd, sprintf("%0.4f\t%0.4f\t%s\t%d\t%s\n",
                map_records[i].rec_time,
                map_records[i].rec_split,
                map_records[i].racer,
                map_records[i].playerclass,
                map_records[i].date));
        }
        fclose(fd);
    }

    float jfd = fopen(Race_JsonFilePath(), FILE_WRITE);
    if (jfd >= 0) {
        fputs(jfd, strcat("{\n  \"map\": \"", mapname, "\",\n  \"records\": [\n"));
        for (float j = 0; j < num_map_records; j++) {
            string comma = (j + 1 < num_map_records) ? "," : "";
            string row_p1 = sprintf("    {\"rank\": %d, \"racer\": \"%s\", \"time\": %0.3f, \"split\": %0.3f, ",
                j + 1,
                clearString(map_records[j].racer),
                map_records[j].rec_time,
                map_records[j].rec_split);
            string row_p2 = sprintf("\"class\": \"%s\", \"date\": \"%s\"}%s\n",
                TeamFortress_GetClassName(map_records[j].playerclass),
                map_records[j].date,
                comma);
            fputs(jfd, strcat(row_p1, row_p2));
        }
        fputs(jfd, "  ]\n}\n");
        fclose(jfd);
    }
};

static void () Race_LoadRecords = {
    num_map_records = 0;
    race_best_time = 0;
    race_best_holder = "";

    float fd = fopen(Race_RecordFilePath(), FILE_READ);
    if (fd < 0)
        return;

    while (num_map_records < MAX_RACE_RECORDS) {
        string ln = fgets(fd);
        if (ln == "" || ln == string_null)
            break;
        ln = strreplace("\n", "", ln);
        float argc = tokenizebyseparator(ln, "\t");
        if (argc >= 3) {
            float t = stof(argv(0));
            if (t > 0) {
                map_records[num_map_records].rec_time = t;
                map_records[num_map_records].rec_split = stof(argv(1));
                map_records[num_map_records].racer = strzone(argv(2));
                map_records[num_map_records].playerclass = (argc >= 4) ? stof(argv(3)) : PC_SOLDIER;
                map_records[num_map_records].date = strzone((argc >= 5) ? argv(4) : "");
                num_map_records++;
            }
        }
    }
    fclose(fd);

    if (num_map_records > 0) {
        race_best_time = map_records[0].rec_time;
        race_best_holder = map_records[0].racer;
    }
};

static float (entity pl, float elapsed, float split) Race_InsertRecord = {
    float insert_idx = -1;
    for (float i = 0; i < num_map_records; i++) {
        if (elapsed < map_records[i].rec_time) {
            insert_idx = i;
            break;
        }
    }
    if (insert_idx == -1) {
        if (num_map_records < MAX_RACE_RECORDS) {
            insert_idx = num_map_records;
        } else {
            return 0; // Not in Top 10
        }
    }

    if (num_map_records < MAX_RACE_RECORDS) {
        num_map_records++;
    } else {
        if (map_records[MAX_RACE_RECORDS - 1].racer != "")
            strunzone(map_records[MAX_RACE_RECORDS - 1].racer);
        if (map_records[MAX_RACE_RECORDS - 1].date != "")
            strunzone(map_records[MAX_RACE_RECORDS - 1].date);
    }

    for (float j = num_map_records - 1; j > insert_idx; j--) {
        map_records[j].rec_time = map_records[j - 1].rec_time;
        map_records[j].rec_split = map_records[j - 1].rec_split;
        map_records[j].racer = map_records[j - 1].racer;
        map_records[j].playerclass = map_records[j - 1].playerclass;
        map_records[j].date = map_records[j - 1].date;
    }

    map_records[insert_idx].rec_time = elapsed;
    map_records[insert_idx].rec_split = split;
    map_records[insert_idx].racer = strzone(strdecolorize(pl.netname));
    map_records[insert_idx].playerclass = pl.playerclass;
    map_records[insert_idx].date = strzone(strftime(TRUE, "%Y-%m-%d %H:%M"));

    race_best_time = map_records[0].rec_time;
    race_best_holder = map_records[0].racer;

    Race_SaveRecords();
    return insert_idx + 1; // 1-based rank (1..10)
};

// Deterministic Blue spawn lookup: always returns the exact same Blue spawn on the map
entity () Race_GetBlueSpawn = {
    if (race_blue_spawn != world && race_blue_spawn.classname != "deadpoint")
        return race_blue_spawn;

    entity spot = find(world, team_str_home, "ts1");
    while (spot != world) {
        if (Activated(spot, self)) {
            race_blue_spawn = spot;
            return spot;
        }
        spot = find(spot, team_str_home, "ts1");
    }

    // Fallback if no activated ts1 found: pick first ts1 regardless of criteria
    spot = find(world, team_str_home, "ts1");
    if (spot != world) {
        race_blue_spawn = spot;
        return spot;
    }

    // Fallback: any info_player_teamspawn with team_no == 1
    spot = find(world, classname, "info_player_teamspawn");
    while (spot != world) {
        if (spot.team_no == 1) {
            race_blue_spawn = spot;
            return spot;
        }
        spot = find(spot, classname, "info_player_teamspawn");
    }

    spot = find(world, classname, "info_player_teamspawn");
    if (spot != world) {
        race_blue_spawn = spot;
        return spot;
    }

    spot = find(world, classname, "info_player_start");
    if (spot != world) {
        race_blue_spawn = spot;
        return spot;
    }

    spot = find(world, classname, "info_player_deathmatch");
    race_blue_spawn = spot;
    return spot;
};

// Resets all flags, projectiles, buildings, and doors between race runs
void () Race_ResetMapState = {
    entity te, oldself;

    // 1. Return all goal items (flags/keys) immediately to their home positions
    te = find(world, classname, "item_tfgoal");
    while (te != world) {
        if (te.owner != world) {
            tfgoalitem_RemoveEffectsFromPlayer(te, te.owner);
            te.owner.has_flag = FALSE;
            RemoveFlagFollow(te.owner);
            te.owner = world;
        }
        te.goal_state = TFGS_INACTIVE;
        if (te.goal_activation & 8192)
            te.solid = SOLID_BBOX;
        else
            te.solid = SOLID_TRIGGER;
        te.movetype = 0;
        te.velocity = '0 0 0';
        te.touch = item_tfgoal_touch;
        te.origin = te.oldorigin;
        if (te.mdl != string_null) {
            oldself = self;
            self = te;
            TF_Item_ApplyGlow();
            self = oldself;
            FO_SetModel(te, te.mdl);
        }
        setsize(te, te.goal_min, te.goal_max);
        setorigin(te, te.origin);
        te.nextthink = 0;
        te.think = SUB_Null;
        te = find(te, classname, "item_tfgoal");
    }
    flag_update = 1;
    ClientsFlagUpdate(world);

    // 2. Restore any breakables
    te = find(world, classname, "func_breakable");
    while (te != world) {
        setmodel(te, te.mdl);
        te.solid = SOLID_BSP;
        te = find(te, classname, "func_breakable");
    }

    // 3. Remove active grenades, pipebombs, detpacks, buildings, backpacks, ammoboxes
    RemoveAllEntsByClassname("grenade");
    RemoveAllEntsByClassname("pipebomb");
    RemoveAllEntsByClassname("detpack");
    RemoveAllEntsByClassname("primer");
    RemoveAllEntsByClassname("primetimer");
    RemoveAllEntsByClassname("gastimer");
    RemoveAllEntsByClassname("backpack");
    RemoveAllEntsByClassname("ammobox");
    RemoveAllEntsByClassname("flagfollow");
    RemoveAllEntsByClassname("building_sentrygun");
    RemoveAllEntsByClassname("building_sentrygun_base");
    RemoveAllEntsByClassname("building_dispenser");
};

static float (entity exclude_pl) Race_CountWaitingPlayers = {
    float cnt = 0;
    entity e = find(world, classname, "player");
    while (e != world) {
        if (!e.has_disconnected && e != exclude_pl && !e.race_afk_waiting) {
            cnt++;
        }
        e = find(e, classname, "player");
    }
    return cnt;
};

static void () Race_UpdateQueuePositions = {
    // Compute 1-based queue position for every waiting player ordered by race_queue_time
    entity p = find(world, classname, "player");
    while (p != world) {
        if (p.has_disconnected || p == race_active_racer) {
            p.race_queue_pos = 0;
        } else {
            float pos = 1;
            entity other_p = find(world, classname, "player");
            while (other_p != world) {
                if (!other_p.has_disconnected && other_p != race_active_racer && other_p != p) {
                    if (other_p.race_queue_time < p.race_queue_time ||
                        (other_p.race_queue_time == p.race_queue_time && num_for_edict(other_p) < num_for_edict(p))) {
                        pos++;
                    }
                }
                other_p = find(other_p, classname, "player");
            }
            p.race_queue_pos = pos;
        }
        p = find(p, classname, "player");
    }
};

static void (entity pl, float to_back) Race_MakeQueuedSpectator = {
    entity oldself = self;
    self = pl;

    TeamFortress_RemoveTimers();
    RemovePrimedGrenades(pl);
    RemoveFlagFollow(pl);
    Engineer_QuietlyRemoveBuildings(pl);

    if (to_back || !pl.race_queue_time)
        pl.race_queue_time = time;

    pl.race_state = RACE_STATE_NONE;
    pl.race_start_time = 0;
    pl.race_flag_split_time = 0;
    pl.has_flag = FALSE;
    pl.items &= ~(IT_KEY1 | IT_KEY2 | IT_INVULNERABILITY | IT_INVISIBILITY | IT_QUAD | IT_SUIT);

    pl.team_no = 0;
    pl.playerclass = PC_UNDEFINED;
    pl.last_playerclass = PC_UNDEFINED;
    pl.tfstate = 0;
    pl.takedamage = DAMAGE_NO;
    pl.solid = SOLID_NOT;
    pl.movetype = MOVETYPE_NOCLIP;
    pl.flags = FL_CLIENT | FL_NOTARGET;
    pl.deadflag = DEAD_NO;
    pl.health = 100;
    pl.max_health = 100;
    pl.armorvalue = 0;
    pl.armortype = 0;
    pl.weapon = 0;
    pl.current_slot = SlotNull;
    pl.weaponmodel = string_null;
    pl.model = string_null;
    pl.mdl = string_null;
    setmodel(pl, string_null);
    pl.modelindex = modelindex_null;
    pl.view_ofs = '0 0 22';
    pl.velocity = '0 0 0';
    pl.maxspeed = SPEC_MAXSPEED;
    pl.csqc_maxspeed = SPEC_MAXSPEED;

    entity spot = Race_GetBlueSpawn();
    if (spot != world) {
        setorigin(pl, spot.origin + '0 0 24');
        pl.angles = spot.angles;
        pl.fixangle = 1;
    }

    forceinfokey(pl, "team_no", "0");
    forceinfokey(pl, "playerclass", "0");
    SetTeamName(pl);
    stuffcmd(pl, "color 0 0\n");
    UpdateClientMenu_Close(pl);

    self = oldself;
    Race_UpdateQueuePositions();
};

static void (entity pl) Race_AssignActiveRacer = {
    race_active_racer = pl;
    pl.race_afk_waiting = 0;
    pl.race_state = RACE_STATE_PRERUN;
    pl.race_ready_deadline = time + 15.0;
    pl.race_last_tick = 16;
    pl.race_start_time = 0;
    pl.race_flag_split_time = 0;

    race_state_global = RACE_STATE_PRERUN;
    race_timer_start = pl.race_ready_deadline;
    race_split_time = 0;

    Race_ResetMapState();

    float chosen_pc = pl.race_saved_pc;
    if (chosen_pc < 1 || chosen_pc > 10)
        chosen_pc = PC_SOLDIER;

    pl.race_saved_pc = chosen_pc;
    pl.team_no = TEAM_BLUE;
    pl.playerclass = chosen_pc;
    pl.nextpc = chosen_pc;
    pl.last_playerclass = PC_UNDEFINED;

    forceinfokey(pl, "team_no", "1");
    forceinfokey(pl, "playerclass", ftos(chosen_pc));

    entity oldself = self;
    self = pl;
    SetTeamName(pl);
    stuffcmd(pl, strcat("color ", ftos(TeamFortress_TeamGetColor(TEAM_BLUE) - 1), "\n"));
    PutClientInServer();
    self = oldself;

    UpdateAllClientsTeamScores();
    Race_UpdateQueuePositions();

    // Open class selection menu so the racer can pick/change class before countdown
    UpdateClientClasses(pl, TEAM_BLUE);
    UpdateClientMenu_Class(pl);

    bprint(PRINT_HIGH, sprintf("^4[RACE]^7 %s is up on ^4BLUE^7 team! (15s to pick class and type '^2race^7')\n", pl.netname));
    sprint(pl, PRINT_HIGH, "^2Your turn to race!^7 Pick your class (1-9) and type '^2race^7' in console within 15 seconds (or '^3unrace^7' to skip).\n");
    CenterPrint(pl, "\n\n\bYour turn on BLUE team!\b\nPick your class & type '\srace\s' within 15s\n");
    localcmd(strcat("serverinfo status \"Pre-Race: ", pl.netname, "\"\n"));
};

static void () Race_PromoteNextRacer = {
    if (intermission_running)
        return;

    if (race_active_racer != world) {
        if (!race_active_racer.has_disconnected && race_active_racer.classname == "player")
            return;
        race_active_racer = world;
    }

    entity best = world;
    entity e = find(world, classname, "player");
    while (e != world) {
        if (!e.has_disconnected && !e.race_afk_waiting) {
            if (best == world || e.race_queue_time < best.race_queue_time ||
                (e.race_queue_time == best.race_queue_time && num_for_edict(e) < num_for_edict(best))) {
                best = e;
            }
        }
        e = find(e, classname, "player");
    }

    if (best != world) {
        Race_AssignActiveRacer(best);
    } else {
        race_state_global = RACE_STATE_NONE;
        race_timer_start = 0;
        race_split_time = 0;
        localcmd("serverinfo status \"Waiting for racers\"\n");
    }
};

void (entity pl) Race_OnClientConnect = {
    pl.race_queue_time = time;
    pl.race_state = RACE_STATE_NONE;
    pl.race_afk_waiting = 0;
    if (pl.race_saved_pc < 1 || pl.race_saved_pc > 10)
        pl.race_saved_pc = PC_SOLDIER;

    stuffcmd(pl, "alias race \"cmd race\"\n");
    stuffcmd(pl, "alias unrace \"cmd unrace\"\n");
    stuffcmd(pl, "alias top10 \"cmd top10\"\n");
    stuffcmd(pl, "alias records \"cmd top10\"\n");
    stuffcmd(pl, "alias queue \"cmd queue\"\n");
};

void (entity pl) Race_OnClientDisconnect = {
    if (pl == race_active_racer) {
        race_active_racer = world;
        Race_ResetMapState();
        Race_PromoteNextRacer();
    } else {
        Race_UpdateQueuePositions();
    }
};

// Called inside PutClientInServer before normal class/equipment setup.
// Returns TRUE if the player was placed in queued spectator mode (skipping normal spawn).
float (entity pl) Race_OnPutClientInServer = {
    if (race_active_racer == world && !pl.race_afk_waiting) {
        race_active_racer = pl;
        pl.race_state = RACE_STATE_PRERUN;
        pl.race_ready_deadline = time + 15.0;
        pl.race_last_tick = 16;
        race_state_global = RACE_STATE_PRERUN;
        race_timer_start = pl.race_ready_deadline;
        race_split_time = 0;
        bprint(PRINT_HIGH, sprintf("^4[RACE]^7 %s is up on ^4BLUE^7 team! (15s to pick class and type '^2race^7')\n", pl.netname));
        localcmd(strcat("serverinfo status \"Pre-Race: ", pl.netname, "\"\n"));
    }

    if (pl != race_active_racer) {
        Race_MakeQueuedSpectator(pl, FALSE);
        sprint(pl, PRINT_HIGH, sprintf("^4[RACE]^7 You are #%d in the race queue (Current racer: %s). Waiting for your turn...\n",
            pl.race_queue_pos, race_active_racer.netname));
        return TRUE;
    }

    // Active racer on Blue team
    pl.team_no = TEAM_BLUE;
    forceinfokey(pl, "team_no", "1");
    if (pl.playerclass < 1 || pl.playerclass > 10) {
        pl.playerclass = (pl.race_saved_pc >= 1 && pl.race_saved_pc <= 10) ? pl.race_saved_pc : PC_SOLDIER;
    }
    pl.race_saved_pc = pl.playerclass;
    pl.nextpc = pl.playerclass;
    forceinfokey(pl, "playerclass", ftos(pl.playerclass));
    return FALSE;
};

void (entity pl) Race_PostPutClientInServer = {
    if (pl != race_active_racer)
        return;

    entity spot = Race_GetBlueSpawn();
    if (spot != world) {
        setorigin(pl, spot.origin + '0 0 1');
        pl.angles = spot.angles;
        pl.fixangle = 1;
    }

    if (pl.race_state == RACE_STATE_PRERUN || pl.race_state == RACE_STATE_COUNTDOWN) {
        pl.velocity = '0 0 0';
        pl.tfstate |= (TFSTATE_CANT_MOVE | TFSTATE_NO_WEAPON);
        TeamFortress_SetSpeed(pl);
    }
};

float (entity pl, float newteam) Race_AllowTeamChange = {
    if (pl == race_active_racer) {
        sprint(pl, PRINT_HIGH, "^4[RACE]^7 You are already on Blue team! Pick a class and type '^2race^7' to start.\n");
        return FALSE;
    }
    if (race_active_racer == world) {
        pl.race_afk_waiting = 0;
        Race_AssignActiveRacer(pl);
        return FALSE;
    }
    pl.race_afk_waiting = 0;
    Race_UpdateQueuePositions();
    sprint(pl, PRINT_HIGH, sprintf("^4[RACE]^7 Only 1 racer on Blue team at a time. You are #%d in the queue!\n", pl.race_queue_pos));
    return FALSE;
};

float (entity pl, float newclass) Race_HandleClassChange = {
    if (newclass < 1 || newclass > 10) {
        sprint(pl, PRINT_HIGH, "Invalid class choice. Please use values 1-10.\n");
        return TRUE;
    }

    pl.race_saved_pc = newclass;
    pl.nextpc = newclass;

    if (pl != race_active_racer) {
        if (race_active_racer == world) {
            pl.race_afk_waiting = 0;
            Race_AssignActiveRacer(pl);
            return TRUE;
        }
        sprint(pl, PRINT_HIGH, sprintf("^4[RACE]^7 Saved class ^2%s^7 for your upcoming turn (Queue #%d).\n",
            TeamFortress_GetClassName(newclass), pl.race_queue_pos));
        UpdateClientMenu_Close(pl);
        return TRUE;
    }

    if (pl.race_state == RACE_STATE_RUNNING || pl.race_state == RACE_STATE_COUNTDOWN) {
        sprint(pl, PRINT_HIGH, sprintf("^4[RACE]^7 Class ^2%s^7 saved for your next run! (Type '^3unrace^7' to abort current run)\n",
            TeamFortress_GetClassName(newclass)));
        UpdateClientMenu_Close(pl);
        return TRUE;
    }

    // In RACE_STATE_PRERUN: switch class immediately at the fixed Blue spawn
    pl.playerclass = newclass;
    pl.nextpc = newclass;
    entity oldself = self;
    self = pl;
    PutClientInServer();
    self = oldself;

    UpdateClientMenu_Close(pl);
    float rem = max(0, ceil(pl.race_ready_deadline - time));
    sprint(pl, PRINT_HIGH, sprintf("^4[RACE]^7 Class set to ^2%s^7. Type '^2race^7' within %ds to start the 3s countdown!\n",
        TeamFortress_GetClassName(pl.playerclass), rem));
    return TRUE;
};

void (entity pl) Race_Cmd_Race = {
    if (intermission_running)
        return;

    if (pl.classname == "observer") {
        clientcommand(pl, "join");
        return;
    }

    pl.race_afk_waiting = 0;

    if (race_active_racer == world) {
        Race_AssignActiveRacer(pl);
    }

    if (pl != race_active_racer) {
        Race_UpdateQueuePositions();
        sprint(pl, PRINT_HIGH, sprintf("^4[RACE]^7 %s is currently racing. You are #%d in the queue!\n",
            race_active_racer.netname, pl.race_queue_pos));
        return;
    }

    if (pl.race_state == RACE_STATE_COUNTDOWN) {
        sprint(pl, PRINT_HIGH, "^4[RACE]^7 Countdown is already in progress!\n");
        return;
    }

    if (pl.race_state == RACE_STATE_RUNNING) {
        if (Race_CountWaitingPlayers(pl) > 0) {
            sprint(pl, PRINT_HIGH, "^4[RACE]^7 Run already in progress! Type '^3unrace^7' to abandon your run.\n");
            return;
        }
        sprint(pl, PRINT_HIGH, "^4[RACE]^7 Restarting run...\n");
    }

    if (pl.playerclass < 1 || pl.playerclass > 10) {
        pl.playerclass = (pl.race_saved_pc >= 1 && pl.race_saved_pc <= 10) ? pl.race_saved_pc : PC_SOLDIER;
    }
    pl.race_saved_pc = pl.playerclass;
    pl.nextpc = pl.playerclass;
    pl.last_playerclass = PC_UNDEFINED;
    forceinfokey(pl, "playerclass", ftos(pl.playerclass));

    // Reset map and respawn racer cleanly at the fixed Blue spawn for the 3-second countdown
    Race_ResetMapState();

    pl.race_state = RACE_STATE_COUNTDOWN;
    pl.race_start_time = time + 3.0;
    pl.race_last_tick = 4;
    pl.race_flag_split_time = 0;

    race_state_global = RACE_STATE_COUNTDOWN;
    race_timer_start = pl.race_start_time;
    race_split_time = 0;

    entity oldself = self;
    self = pl;
    pl.tfstate &= ~(TFSTATE_NO_WEAPON | TFSTATE_RELOADING);
    PutClientInServer();
    FO_InstantReloadAllWeapons(pl);
    pl.tfstate &= ~(TFSTATE_NO_WEAPON | TFSTATE_RELOADING);
    if (IsSlotNull(pl.current_slot) || IsSlotMelee(pl.current_slot) || pl.weapon == 0) {
        pl.current_slot = W_BestWeaponSlot();
        pl.queue_slot = SlotNull;
    }
    W_UpdateCurrentWeapon(pl);
    W_UpdateWeaponModel(pl);
    pl.velocity = '0 0 0';
    pl.tfstate |= (TFSTATE_CANT_MOVE | TFSTATE_NO_WEAPON);
    pl.attack_finished = time + 3.05;
    TeamFortress_SetSpeed(pl);
    Menu_Close(pl);
    UpdateClientMenu_Close(pl);
    self = oldself;

    bprint(PRINT_HIGH, sprintf("^4[RACE]^7 %s (%s) started a 3-second race countdown!\n",
        pl.netname, TeamFortress_GetClassName(pl.playerclass)));
    localcmd(strcat("serverinfo status \"Countdown: ", pl.netname, "\"\n"));
};

static void (entity pl, string reason, float allow_solo_repeat) Race_EndTurn = {
    Race_ResetMapState();

    pl.race_state = RACE_STATE_NONE;
    pl.race_start_time = 0;
    pl.race_flag_split_time = 0;
    pl.race_queue_time = time;

    race_active_racer = world;
    race_state_global = RACE_STATE_NONE;
    race_timer_start = 0;
    race_split_time = 0;

    if (Race_CountWaitingPlayers(pl) > 0 || !allow_solo_repeat) {
        if (!allow_solo_repeat && Race_CountWaitingPlayers(pl) == 0) {
            pl.race_afk_waiting = 1;
            Race_MakeQueuedSpectator(pl, TRUE);
            sprint(pl, PRINT_HIGH, "^4[RACE]^7 Moved to spectator. Type '^2race^7' whenever you are ready to race again!\n");
        } else {
            Race_MakeQueuedSpectator(pl, TRUE);
        }
        Race_PromoteNextRacer();
    } else {
        // Solo racer on server: immediately start a fresh 15s pre-run turn on Blue team
        Race_AssignActiveRacer(pl);
    }
};

void (entity pl) Race_Cmd_Unrace = {
    if (pl != race_active_racer) {
        if (!pl.race_afk_waiting) {
            pl.race_afk_waiting = 1;
            Race_UpdateQueuePositions();
            sprint(pl, PRINT_HIGH, "^4[RACE]^7 You stepped out of the race queue. Type '^2race^7' to rejoin the queue.\n");
        } else {
            sprint(pl, PRINT_HIGH, "^4[RACE]^7 You are not currently racing. Type '^2race^7' to join the queue.\n");
        }
        return;
    }

    if (pl.race_state == RACE_STATE_RUNNING || pl.race_state == RACE_STATE_COUNTDOWN) {
        bprint(PRINT_HIGH, sprintf("^4[RACE]^7 %s abandoned the run (unrace).\n", pl.netname));
        Race_EndTurn(pl, "abandoned run", TRUE);
    } else {
        bprint(PRINT_HIGH, sprintf("^4[RACE]^7 %s yielded their turn (unrace).\n", pl.netname));
        Race_EndTurn(pl, "yielded turn", FALSE);
    }
};

void (entity pl) Race_Cmd_Top10 = {
    sprint(pl, PRINT_HIGH, sprintf("\n^4=== TOP 10 RACE RECORDS: %s ===^7\n", mapname));
    if (num_map_records == 0) {
        sprint(pl, PRINT_HIGH, "No completions recorded on this map yet. Type '^2race^7' to set the #1 record!\n\n");
        return;
    }
    for (float i = 0; i < num_map_records; i++) {
        string split_str = (map_records[i].rec_split > 0) ? sprintf(" (flag: %s)", Race_FormatTime(map_records[i].rec_split)) : "";
        sprint(pl, PRINT_HIGH, sprintf("^3#%d^7  ^2%s^7  -  %s (%s)%s  [%s]\n",
            i + 1,
            Race_FormatTime(map_records[i].rec_time),
            map_records[i].racer,
            TeamFortress_GetClassName(map_records[i].playerclass),
            split_str,
            map_records[i].date));
    }
    sprint(pl, PRINT_HIGH, "\n");
};

void (entity pl) Race_Cmd_Queue = {
    sprint(pl, PRINT_HIGH, "\n^4=== RACE QUEUE ===^7\n");
    if (race_active_racer != world) {
        sprint(pl, PRINT_HIGH, sprintf("^2Active Racer (Blue):^7 %s (%s)\n",
            race_active_racer.netname, TeamFortress_GetClassName(race_active_racer.playerclass)));
    } else {
        sprint(pl, PRINT_HIGH, "No active racer. Type '^2race^7' to take Blue team!\n");
    }
    Race_UpdateQueuePositions();
    float total_q = 0;
    for (float pos = 1; pos <= 32; pos++) {
        entity e = find(world, classname, "player");
        while (e != world) {
            if (!e.has_disconnected && e != race_active_racer && e.race_queue_pos == pos) {
                sprint(pl, PRINT_HIGH, sprintf("  #%d: %s%s\n", pos, e.netname, e.race_afk_waiting ? " (AFK)" : ""));
                total_q++;
            }
            e = find(e, classname, "player");
        }
    }
    if (total_q == 0)
        sprint(pl, PRINT_HIGH, "  (Queue is empty)\n");
    sprint(pl, PRINT_HIGH, "\n");
};

void (entity pl) Race_OnFlagPickup = {
    if (!race_mode || pl != race_active_racer || pl.race_state != RACE_STATE_RUNNING)
        return;
    if (pl.race_flag_split_time > 0)
        return;

    pl.race_flag_split_time = max(0.001, time - pl.race_start_time);
    race_split_time = pl.race_flag_split_time;

    bprint(PRINT_HIGH, sprintf("^4[RACE]^7 %s grabbed the enemy flag at ^3%s^7!\n",
        pl.netname, Race_FormatTime(pl.race_flag_split_time)));
};

static void (entity pl, float elapsed, float split, float rank, float prev_best) Race_NotifyExternal = {
    string clean_name = clearString(strdecolorize(pl.netname));
    string cls_name = TeamFortress_GetClassName(pl.playerclass);
    string ts = ISOTimemillis();

    // 1. Emit structured JSON line to server console/log and race_events.jsonl for Discord bot & Web leaderboard
    // Split into <=5-parameter sprintf calls to stay well within QuakeC VM's 8-parameter limit
    string j1 = sprintf("{\"type\":\"race_capture\",\"map\":\"%s\",\"player\":\"%s\",\"class\":\"%s\",",
        mapname,
        clean_name,
        cls_name);
    string j2 = sprintf("\"class_id\":%d,\"time\":%0.4f,\"time_formatted\":\"%s\",\"flag_split\":%0.4f,",
        pl.playerclass,
        elapsed,
        Race_FormatTime(elapsed),
        split);
    string j3 = sprintf("\"rank\":%d,\"is_map_record\":%s,\"prev_map_record\":%0.4f,\"timestamp\":\"%s\"}",
        rank,
        (rank == 1) ? "true" : "false",
        prev_best,
        ts);
    string json_line = strcat(j1, j2, j3);

    dprint(strcat("[RACE_RECORD] ", json_line, "\n"));

    float lfd = fopen("race_events.jsonl", FILE_APPEND);
    if (lfd >= 0) {
        fputs(lfd, strcat(json_line, "\n"));
        fclose(lfd);
    }

    // 2. Optional direct Discord Webhook POST if localinfo discord_webhook is configured
    string webhook = infokey(world, "discord_webhook");
    if (webhook != string_null && webhook != "" && rank == 1) {
        string delta_msg = (prev_best > 0) ? sprintf(" (beat previous record of %s by -%0.3fs!)", Race_FormatTime(prev_best), prev_best - elapsed) : " (first record on map!)";
        string payload = sprintf("{\"content\": \"[NEW MAP RECORD on `%s`!] **%s** (%s) captured the flag in **%s**%s\"}",
            mapname, clean_name, cls_name, Race_FormatTime(elapsed), delta_msg);
        uri_post(webhook, TFL_RESULT, "application/json", payload);
    }
};

void (entity pl) Race_OnFlagCapture = {
    if (!race_mode || pl != race_active_racer || pl.race_state != RACE_STATE_RUNNING)
        return;

    float elapsed = max(0.001, time - pl.race_start_time);
    float split = pl.race_flag_split_time;
    float prev_map_best = race_best_time;
    float prev_pb = pl.race_best_personal;

    race_last_time = elapsed;

    if (prev_pb == 0 || elapsed < prev_pb)
        pl.race_best_personal = elapsed;

    float rank = Race_InsertRecord(pl, elapsed, split);

    string split_info = (split > 0) ? sprintf(" [Flag Split: %s | Return: %s]", Race_FormatTime(split), Race_FormatTime(max(0.001, elapsed - split))) : "";
    bprint(PRINT_HIGH, "\n^4================================================^7\n");
    if (rank == 1) {
        string diff_str = (prev_map_best > 0) ? sprintf(" ^2(-%0.3fs!)^7", prev_map_best - elapsed) : "";
        bprint(PRINT_HIGH, sprintf("^3*** NEW MAP RECORD ON %s! ***^7\n", strtoupper(mapname)));
        bprint(PRINT_HIGH, sprintf("^4[RACE]^7 %s (%s) captured in ^2%s^7%s%s\n",
            pl.netname, TeamFortress_GetClassName(pl.playerclass), Race_FormatTime(elapsed), diff_str, split_info));
        stuffcmd(pl, "play misc/power.wav\n");
    } else if (rank > 1 && rank <= 10) {
        bprint(PRINT_HIGH, sprintf("^4[RACE]^7 %s (%s) captured in ^2%s^7 -- ^3#%d Top 10 Time on %s!^7%s\n",
            pl.netname, TeamFortress_GetClassName(pl.playerclass), Race_FormatTime(elapsed), rank, mapname, split_info));
    } else {
        bprint(PRINT_HIGH, sprintf("^4[RACE]^7 %s (%s) captured in ^2%s^7!%s\n",
            pl.netname, TeamFortress_GetClassName(pl.playerclass), Race_FormatTime(elapsed), split_info));
    }
    bprint(PRINT_HIGH, "^4================================================^7\n\n");

    string rank_banner = (rank == 1) ? "\sNEW MAP RECORD (#1)!\s" : ((rank > 0) ? sprintf("Map Rank: #%d", rank) : "");
    CenterPrint(pl, strcat("\n\n\bCAPTURE TIME:\b ", Race_FormatTime(elapsed), "\n", rank_banner, "\n"));

    Race_NotifyExternal(pl, elapsed, split, rank, prev_map_best);

    // Complete turn and rotate queue (or start new 15s prerun if solo)
    Race_EndTurn(pl, "completed run", TRUE);
};

void (entity pl) Race_OnPlayerDie = {
    if (!race_mode || pl != race_active_racer)
        return;

    if (pl.race_state == RACE_STATE_RUNNING || pl.race_state == RACE_STATE_COUNTDOWN) {
        float run_dur = max(0, time - pl.race_start_time);
        bprint(PRINT_HIGH, sprintf("^4[RACE]^7 %s died -- run ended (%s).\n", pl.netname, Race_FormatTime(run_dur)));
    }
    Race_EndTurn(pl, "died", TRUE);
};

void (entity pl) Race_PreThink = {
    if (pl != race_active_racer) {
        // Queued spectator: ensure they cannot touch triggers/items or take damage
        if (pl.team_no != 0 || pl.solid != SOLID_NOT) {
            Race_MakeQueuedSpectator(pl, FALSE);
        }
        return;
    }

    // Active racer in PRERUN or COUNTDOWN: keep anchored at the fixed Blue spawn pad with 0 velocity
    if (pl.race_state == RACE_STATE_PRERUN || pl.race_state == RACE_STATE_COUNTDOWN) {
        entity spot = Race_GetBlueSpawn();
        if (spot != world) {
            if (vlen(pl.origin - (spot.origin + '0 0 1')) > 2) {
                setorigin(pl, spot.origin + '0 0 1');
            }
        }
        pl.velocity = '0 0 0';
        pl.tfstate |= (TFSTATE_CANT_MOVE | TFSTATE_NO_WEAPON);
        pl.attack_finished = time + 0.2;
        RemovePrimedGrenades(pl);
    }
};

void () Race_Controller_Think = {
    self.nextthink = time + 0.05;

    if (intermission_running)
        return;

    if (race_active_racer != world && (race_active_racer.has_disconnected || race_active_racer.classname != "player")) {
        race_active_racer = world;
        Race_ResetMapState();
    }

    if (race_active_racer == world) {
        Race_PromoteNextRacer();
        return;
    }

    entity r = race_active_racer;

    if (r.race_state == RACE_STATE_PRERUN) {
        float rem = ceil(r.race_ready_deadline - time);
        if (rem < r.race_last_tick && rem > 0) {
            r.race_last_tick = rem;
            if (rem == 10 || rem <= 5) {
                sprint(r, PRINT_HIGH, sprintf("^4[RACE]^7 %d second%s left to type '^2race^7' before moving to back of queue!\n",
                    rem, (rem == 1) ? "" : "s"));
                if (rem <= 3)
                    stuffcmd(r, "play buttons/switch04.wav\n");
            }
        }
        if (time >= r.race_ready_deadline) {
            bprint(PRINT_HIGH, sprintf("^4[RACE]^7 %s did not type 'race' within 15 seconds and was moved to the back of the queue.\n", r.netname));
            Race_EndTurn(r, "15s timeout", FALSE);
            return;
        }
    } else if (r.race_state == RACE_STATE_COUNTDOWN) {
        float cd_rem = ceil(r.race_start_time - time);
        if (cd_rem < r.race_last_tick && cd_rem >= 1) {
            r.race_last_tick = cd_rem;
            CenterPrint(r, strcat("\n\n\bRace starts in:\b ", ftos(cd_rem), "...\n\nClass: ", TeamFortress_GetClassName(r.playerclass), "\n"));
            entity te = find(world, classname, "player");
            while (te != world) {
                if (!te.has_disconnected)
                    stuffcmd(te, "play buttons/switch04.wav\n");
                te = find(te, classname, "player");
            }
        }
        if (time >= r.race_start_time) {
            // GO! Start timer in spawn and unfreeze racer
            r.race_state = RACE_STATE_RUNNING;
            r.race_start_time = time;
            r.race_last_tick = 91;
            r.race_flag_split_time = 0;

            race_state_global = RACE_STATE_RUNNING;
            race_timer_start = time;
            race_split_time = 0;

            entity spot = Race_GetBlueSpawn();
            if (spot != world) {
                setorigin(r, spot.origin + '0 0 1');
                r.angles = spot.angles;
            }
            r.velocity = '0 0 0';
            r.tfstate &= ~(TFSTATE_CANT_MOVE | TFSTATE_NO_WEAPON);
            r.attack_finished = 0;

            entity oldself = self;
            self = r;
            if (IsSlotNull(r.current_slot) || IsSlotMelee(r.current_slot) || r.weapon == 0) {
                r.current_slot = W_BestWeaponSlot();
                r.queue_slot = SlotNull;
            }
            W_UpdateCurrentWeapon(r);
            TeamFortress_SetSpeed(r);
            W_UpdateWeaponModel(r);
            self = oldself;

            CenterPrint(r, "\n\n\bGO!\b\n");
            entity p = find(world, classname, "player");
            while (p != world) {
                if (!p.has_disconnected)
                    stuffcmd(p, "play misc/talk.wav\n");
                p = find(p, classname, "player");
            }
            localcmd(strcat("serverinfo status \"Racing: ", r.netname, "\"\n"));
        }
    } else if (r.race_state == RACE_STATE_RUNNING) {
        float run_elapsed = time - r.race_start_time;
        float run_rem = ceil(RACE_MAX_RUN_TIME - run_elapsed);
        if (run_rem < r.race_last_tick && run_rem > 0) {
            r.race_last_tick = run_rem;
            if (run_rem == 10 || run_rem <= 5) {
                sprint(r, PRINT_HIGH, sprintf("^4[RACE]^7 %d second%s left before 90s run time limit!\n",
                    run_rem, (run_rem == 1) ? "" : "s"));
                if (run_rem <= 3)
                    stuffcmd(r, "play buttons/switch04.wav\n");
            }
        }
        if (run_elapsed >= RACE_MAX_RUN_TIME) {
            bprint(PRINT_HIGH, sprintf("^4[RACE]^7 %s's run FAILED -- exceeded the 90.0s maximum run time!\n", r.netname));
            CenterPrint(r, "\n\n\bRUN FAILED!\b\n90-second time limit reached\n");
            stuffcmd(r, "play misc/medkey.wav\n");
            Race_EndTurn(r, "90s time limit", TRUE);
            return;
        }
    }
};

void () Race_Init = {
    race_mode = 1;
    clanbattle = 0;
    quadmode = 0;
    duelmode = 0;
    cb_prematch = 0;
    org_game = 1;
    login_required = 0;

    race_active_racer = world;
    race_blue_spawn = world;
    race_state_global = RACE_STATE_NONE;
    race_timer_start = 0;
    race_last_time = 0;
    race_split_time = 0;

    Race_GetBlueSpawn();
    Race_LoadRecords();

    if (race_controller_ent == world) {
        race_controller_ent = spawn();
        race_controller_ent.classname = "race_controller";
        race_controller_ent.think = Race_Controller_Think;
        race_controller_ent.nextthink = time + 0.1;
    }
    bprint(PRINT_HIGH, strcat("^4[RACE]^7 QWTF Live Standalone Race Mode initialized on ", mapname, "\n"));
};
