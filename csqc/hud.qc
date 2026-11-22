void Hud_WriteCfg(string path)
{
    // this overwrites
    float filehandle;
    filehandle = fopen(path, FILE_WRITE);
    string line = "";

    for(float i = HUDP_FIRST; i <= HUDP_LAST; i++)
        line = GetPanelString(line, getHudPanel(i));

    fputs(filehandle, line);
    fclose(filehandle);
}

void FO_Hud_Editor_LoadDefaultSettings()
{
    getHudPanel(HUDP_OPTIONS)->drawPanel = Hud_DrawHudOptionsPanel;
    vector vsize = (vector)getproperty(VF_SCREENVSIZE);
    float width = vsize_x;
    float height = vsize_y;

    // check struct, put defaults in
    float yoffset = height - 64;

    //Default menus, id, ready and MOTD to centre of the screen
    getHudPanel(HUDP_GAME_MODE)->Position = [width - getHudPanel(HUDP_GAME_MODE)->FillSize.x, 30];
    getHudPanel(HUDP_GAME_MODE)->Orientation = FO_HUD_INSERT_AFTER;
    getHudPanel(HUDP_MOTD)->Position = [(width / 2) - (getHudPanel(HUDP_MOTD)->FillSize.x / 2), 30];
    getHudPanel(HUDP_READY)->Position = [(width / 2) - (getHudPanel(HUDP_READY)->FillSize.x / 2), 30];
    getHudPanel(HUDP_MENU_HINT)->Position = [(width / 2) - (getHudPanel(HUDP_MENU)->FillSize.x / 2), 80];
    getHudPanel(HUDP_MENU_HINT)->Orientation = FO_HUD_INSERT_MIDDLE;
    getHudPanel(HUDP_MENU)->Position = [(width / 2) - (getHudPanel(HUDP_MENU)->FillSize.x / 2), 120];
    getHudPanel(HUDP_IDENTIFY)->Position = [(width / 2) - (getHudPanel(HUDP_IDENTIFY)->FillSize.x / 2), height - 100];
    getHudPanel(HUDP_CLIPSIZE)->Position = [(width / 2) + 16, height - 50];
    getHudPanel(HUDP_CLIPSIZE)->Scale = 0.75;
    getHudPanel(HUDP_GREN1)->Position = [(width / 2) - 16 - (getHudPanel(HUDP_GREN1)->FillSize.x * 3), height - 50];
    getHudPanel(HUDP_GREN1)->Scale = 0.75;
    getHudPanel(HUDP_GREN2)->Position = [(width / 2) - 16 - getHudPanel(HUDP_GREN2)->FillSize.x * 0.75, height - 50];
    getHudPanel(HUDP_GREN2)->Scale = 0.75;
    getHudPanel(HUDP_GRENTIMER)->Position = [(width / 2) + 16, (height / 2) + 32];
    getHudPanel(HUDP_GRENTIMER)->Scale = 0.75;
    getHudPanel(HUDP_FLAGINFO)->Orientation = FO_HUD_INSERT_AFTER;
    getHudPanel(HUDP_FLAGINFO)->Position = [width - 24, (height / 2) - 8];
    getHudPanel(HUDP_FRAGSTREAK)->Display = 0;
    getHudPanel(HUDP_CAPS)->Display = 0;
    getHudPanel(HUDP_SPECIAL)->Position = [0, 180];
    getHudPanel(HUDP_SHOWSCORES)->Position = [(width / 2) - (getHudPanel(HUDP_SHOWSCORES)->FillSize.x / 2), 30];
    getHudPanel(HUDP_SHOWSCORES)->Scale = 1.00;
    getHudPanel(HUDP_TEAMSCORE)->Position = [(width - getHudPanel(HUDP_TEAMSCORE)->FillSize.x), 0];
    getHudPanel(HUDP_MAP_MENU)->Position = [(width / 2) - (getHudPanel(HUDP_MAP_MENU)->FillSize.x / 2), 30];
    getHudPanel(HUDP_MAP_MENU)->Scale = 1.00;
    getHudPanel(HUDP_MAP_MENU)->Display = 0;

    getHudPanel(HUDP_SPEEDBAR)->Display = 0;
    getHudPanel(HUDP_SPEEDBAR)->Scale = 1.00;
    getHudPanel(HUDP_SPEEDBAR)->Snap = HUD_SNAP_CENTER;
    getHudPanel(HUDP_SPEEDBAR)->Position = [0, 30];

    getHudPanel(HUDP_RELOADPROGRESS)->Display = 1;
    getHudPanel(HUDP_RELOADPROGRESS)->Snap = HUD_SNAP_CENTER;
    getHudPanel(HUDP_RELOADPROGRESS)->Position = [0, yoffset - 30];
}

void FO_Hud_Editor_List_Panels() = {
    print("^1Available HUD Elements:^7\n");
    for (float i = HUDP_FIRST; i <= HUDP_LAST; i++)
        print(getHudPanel(i)->SaveName, ": ", getHudPanel(i)->Name, "\n");
//    for(float i = 0; i < Hud_ExtraPanels.length; i++) {
//        print(Hud_ExtraPanels[i].id, ": ", Hud_ExtraPanels[i].Name, "\n");
//    }
}

string FO_Hud_Editor_Get_Panel_Setting(string panel_name, string setting) = {
/*
    float id = getHudPanel(panelid);
    if(id < 0) {
        print("^1HUD Element^7 '", panelid, "' does not exist!\n");
        return "";
    }
*/    
    FO_Hud_Panel* panel = getHudPanelBySaveName(panel_name);
    if(!panel || &panel == &NullPanel) {
        print("^1HUD Element^7 '", panel_name, "' does not exist!\n");
        return "";
    }
    
    switch (setting) {
        case "_id":
            return ftos(panel.id);
        case "saveName":
            return panel.SaveName;
        case "name":
            return panel.Name;
        case "position":
            return vtos(panel.Position);
        case "size":
            return vtos(panel.FillSize);
        case "scale":
            return ftos(panel.Scale);
        case "textscale":
            return ftos(panel.TextScale);
        case "show":
            return ftos(panel.Display);
        case "orientation":
            return ftos(panel.Orientation);
        case "snap":
            return ftos(panel.Snap);
        case "style":
            return ftos(panel.Style);
        default:
            print("^1Setting^7 '", setting, "' does not exist!\n");
            break;
    }
    return "";
}

void FO_Hud_Editor_Show_Panel(string panel_name) = {
    /*
    float id = getHudPanel(panelid);
    if(id < 0) {
        print("^1HUD Element^7 '", panelid, "' does not exist!\n");
        return;
    }
    */
    FO_Hud_Panel* panel = getHudPanelBySaveName(panel_name);
    if(!panel || &panel == &NullPanel) {
        print("^1HUD Element^7 '", panel_name, "' does not exist!\n");
        return;
    }
    print("^1id^7: ", panel.id, "\n");
    print("\tname: ", panel.Name, "\n");
    print("\tposition: ", vtos(panel.Position), "\n");
    print("\tsize: ", vtos(panel.FillSize), "\n");
    print("\tscale: ", ftos(panel.Scale), "\n");
    print("\ttextscale: ", ftos(panel.TextScale), "\n");
    print("\tshow: ", ftos(panel.Display), "\n");
    print("\torientation: ", ftos(panel.Orientation), "\n");
    print("\tsnap: ", ftos(panel.Snap), "\n");
    print("\tstyle: ", ftos(panel.Style), "\n");
}

void FO_Hud_Editor_Print_Panel_Setting(string panel_name, string setting) = {
    if(panel_name == "help" || panel_name == "?") {
        print("^1orientation^7: Extends from base to the... 0 = Left, 1 = Right, 2 = Middle (where applicable)\n");
        print("^1snap^7: 0 = None, Horzontal: 1/2/4 = Left/Centre/Right, Vertical: 8/16/32 = Top/Middle/Bottom)\n");
        return;
    }
    if(setting == "") {
        FO_Hud_Editor_Show_Panel(panel_name);
    } else {
        print(FO_Hud_Editor_Get_Panel_Setting(panel_name, setting), "\n");
    }
}

void FO_Hud_Editor_Set_Panel_Setting(string panel_name, string setting, string value) = {
/*    
    float id = getHudPanel(panelid);
    if(id < 0) {
        print("^1HUD Element^7 '", panelid, "' does not exist!\n");
        return;
    }
*/  
    float val = 0;
    
    FO_Hud_Panel* panel = getHudPanelBySaveName(panel_name);
    if(!panel || &panel == &NullPanel) {
        print("^1HUD Element^7 '", panel_name, "' does not exist!\n");
        return;
    }
    switch (setting) {
        case "id":
            print("^5id ^1can't be changed^7!\n");
            break;
        case "name":
            print("^5name ^1can't be changed^7!\n");
            break;
        case "position":
            panel.Position = stov(value);
            break;
        case "size":
            panel.FillSize = stov(value);
            break;
        case "scale":
            panel.Scale = stof(value);
            break;
        case "textscale":
            panel.TextScale = stof(value);
            break;
        case "show":
            FO_Hud_SetDisplay(panel->id, stof(value));
            break;
        case "orientation":
            panel.Orientation = stof(value);
            break;
        case "snap":
            val = stof(value);
            if(val) {
                if(val & 1 || val & 2 || val & 4) {
                    panel.Position.x = 0;
                }
                if(val & 8 || val & 16 || val & 32) {
                    panel.Position.y = 0;
                }
            } else {
                panel.Position = getPanelPosition(panel);
            }
            panel.Snap = val;
            break;
        case "style":
            panel.Style = stof(value);
            break;
        default:
            print("^1Setting^7 '", setting, "' does not exist!\n");
            break;
    }
}

/*
 * pos = x coord of the UI box
 * width = x width of the UI box
 * iconsize = x width of the icon (text will start before/after it); offset
 * text = actual text to display
 * textsize = fontsize
 * align = alignment
 */
float GetTextAlignOffset(float pos, float width, float iconsize, string text, float textsize, float align)  {
    if(align == FO_HUD_INSERT_AFTER) {
        return pos - strlen(text) * textsize + width - iconsize;
    } else if(align == FO_HUD_INSERT_MIDDLE) {
        return pos + (width / 2) - ((strlen(text) * textsize) / 2);
    }
    return pos + iconsize;
}
//MEHT this is a sui example thing
void(PanelID id, vector pos, vector size, string name, string command) bind_button =
{
	sui_push_frame(pos, size);
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	string key = "A"; //sui_binder(id, [0, 0], size, name, command);
	if (sui_is_hovered(id)) sui_fill([0, 0], size, MENU_HIGHLIGHT, 0.1, 0);
	sui_text([6, 0], MENU_TEXT_SMALL, name, MENU_TEXT_1, 1, 0);
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_CENTER]);
	sui_text([-6, 0], MENU_TEXT_SMALL, key, MENU_TEXT_1, 1, 0);
	
	sui_pop_frame();
};

void (float dx, float dy) Hud_MapMenuPanel_Move = {
    FO_Hud_Panel* panel = getHudPanel(HUDP_MAP_MENU);
    if (Mouse.x > panel.Position.x &&
        Mouse.y > panel.Position.y &&
        Mouse.x < (panel.Position.x + panel.FillSize.x * panel.Scale) &&
        Mouse.y < (panel.Position.y + panel.FillSize.y * panel.Scale)
    ) {
        panel.Position.x += dx;
        panel.Position.y += dy;
    }
};

string (float idx) Race_GetGridMapName = {
    switch (idx) {
        case 0: return "1on1forts";
        case 1: return "2farms";
        case 2: return "2fort5r";
        case 3: return "5speed5";
        case 4: return "8-1";
        case 5: return "alchemy";
        case 6: return "desperat";
        case 7: return "disorder";
        case 8: return "dragongod2";
        case 9: return "egypt3";
        case 10: return "etf_xpress";
        case 11: return "excel3";
        case 12: return "ff-phantomr";
        case 13: return "ff-shoop";
        case 14: return "ff-swoop";
        case 15: return "genders2r";
        case 16: return "japanc";
        case 17: return "openfirer";
        case 18: return "optics6";
        case 19: return "poop";
        case 20: return "preskool";
        case 21: return "r123";
        case 22: return "sunnyramps";
        case 23: return "wc3";
        case 24: return "zelda";
    }
    return "";
};

void() Hud_DrawMapMenuPanel = {
    FO_Hud_Panel* panel = getHudPanel(HUDP_MAP_MENU);
    panel.FillSize = [520, 200];
    local vector fillsize = panel.FillSize * panel.Scale;
    local float alpha = fo_hud_editor ? 0.2 : 0.92;
    local vector position = getPanelPosition(panel);
    if (!fo_hud_editor && (position.x < 0 || position.x + fillsize.x > ScreenSize.x)) {
        position.x = max(0, (ScreenSize.x - fillsize.x) / 2);
        panel.Position.x = position.x;
    }
    if (panel.Display)
        setcursormode(TRUE);
    if (hud_panel(panel->id, position, fillsize, alpha, panel.Display)) {
        // click event
    }

    if (fo_hud_editor)
        return;

    local float textscale = panel.TextScale ? panel.TextScale : panel.Scale;
    local float padding = 6 * panel.Scale;
    local vector text_sz = [8 * textscale, 8 * textscale, 0];
    local vector label_sz = [10 * textscale, 10 * textscale, 0];

    sui_border_box(position, fillsize, 1, MENU_BORDER, 0.6, 0);

    // 1. Top line: "Type map name" with a blank field to type the name
    float top_row_h = 20 * panel.Scale;
    float label_w = 140 * panel.Scale;
    sui_push_frame(position + [padding * 2, padding], [label_w, top_row_h]);
    sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
    sui_text([0, 0], label_sz, "Type map name", MENU_TEXT_4, 1, 0);
    sui_pop_frame();

    vector field_pos = position + [padding * 2 + label_w + padding, padding];
    vector field_sz = [fillsize.x - (padding * 4 + label_w), top_row_h];
    if (hud_colour_button(HUDB_MAP_INPUT, field_pos, field_sz, vote_list_filter, MENU_BG_DARK, label_sz, MENU_TEXT_2, SUI_ALIGN_START, 6, 0.85, 1, 0)) {
        race_selected_grid_idx = -1;
    }

    // 2. 5x5 grid of pre-filled maps
    float grid_top = padding * 2 + top_row_h + 2 * panel.Scale;
    float gap_x = 4 * panel.Scale;
    float gap_y = 4 * panel.Scale;
    float grid_w = fillsize.x - padding * 4;
    float cell_w = (grid_w - gap_x * 4) / 5;
    float cell_h = 20 * panel.Scale;

    for (float row = 0; row < 5; row++) {
        for (float col = 0; col < 5; col++) {
            float idx = row * 5 + col;
            string mname = Race_GetGridMapName(idx);
            vector cell_pos = position + [padding * 2 + col * (cell_w + gap_x), grid_top + row * (cell_h + gap_y)];

            float is_sel = (vote_list_filter == "" && race_selected_grid_idx == idx) ||
                           (vote_list_filter != "" && vote_list_filter == mname);
            vector btn_bg = is_sel ? MENU_BG_WARNING : MENU_BG_DARK;
            float btn_alpha = is_sel ? 1.0 : 0.75;
            vector btn_txt_col = MENU_TEXT_1;
            if (current_vote && current_vote.name == mname)
                btn_txt_col = MENU_TEXT_GREEN;
            else if (is_sel)
                btn_txt_col = MENU_TEXT_3;

            if (hud_colour_button(HUDL_MAP_BASE + idx, cell_pos, [cell_w, cell_h], mname, btn_bg, text_sz, btn_txt_col, SUI_ALIGN_CENTER, 0, btn_alpha, 1, 0)) {
                race_selected_grid_idx = idx;
                race_selected_map = mname;
                vote_list_filter = "";
            }
        }
    }

    // 3. Bottom row: 'Change Now' and 'Vote' options
    string target_map = (vote_list_filter != "") ? vote_list_filter : race_selected_map;
    float current_vote_selected = (target_map != "" && current_vote && current_vote.name == target_map);

    float bot_h = 20 * panel.Scale;
    float bot_y = position.y + fillsize.y - padding - bot_h;
    float act_btn_w = 110 * panel.Scale;

    vector change_pos = [position.x + fillsize.x - padding * 2 - act_btn_w * 2 - gap_x, bot_y];
    vector vote_pos = [position.x + fillsize.x - padding * 2 - act_btn_w, bot_y];

    if (hud_colour_button(HUDB_MAP_CHANGE, change_pos, [act_btn_w, bot_h], "Change Now", MENU_BUTTON, label_sz, MENU_TEXT_WARNING, SUI_ALIGN_CENTER, 0, 1, 1, 0)) {
        if (target_map != "") {
            if (is_admin) {
                localcmd("cmd map ", target_map, "\n");
            } else {
                localcmd("rcon map ", target_map, "\n");
            }
        }
    }

    if (current_vote_selected) {
        if (hud_colour_button(HUDB_MAP_VOTE, vote_pos, [act_btn_w, bot_h], "Unvote", MENU_BUTTON, label_sz, MENU_TEXT_1, SUI_ALIGN_CENTER, 0, 1, 1, 0)) {
            localcmd("cmd break\n");
        }
    } else {
        if (hud_colour_button(HUDB_MAP_VOTE, vote_pos, [act_btn_w, bot_h], "Vote", MENU_BUTTON, label_sz, MENU_TEXT_1, SUI_ALIGN_CENTER, 0, 1, 1, 0)) {
            if (target_map != "") {
                localcmd("cmd votemap ", target_map, "\n");
            }
        }
    }
};

void() Hud_DrawTeamScorePanel = {
    float alpha = 0;
    FO_Hud_Panel* panel = getHudPanel(HUDP_TEAMSCORE);

    float textScale = panel.Scale; //panel.TextScale; //panel.TextScale?panel.TextScale:panel.Scale;
    //float sizex, sizey;
    //sizex = size_x;
    //sizey = size_y;
    //vector mediumtext = MENU_TEXT_SMALL * textScale;
    local float padding = 0.5; // * textScale;

    local vector fillsize = [12,12]; // * textScale; //mediumtext;
    fillsize_x = fillsize_x * 3;
    fillsize_y = fillsize_y + padding * 2;
    panel.FillSize = fillsize;
    fillsize = fillsize * textScale;
    vector position = getPanelPosition(panel);

    if (hud_panel(panel->id, position, fillsize, alpha, getHudPanel(HUDP_TEAMSCORE)->Display)) {
        if (fo_hud_editor) {
            // click event
        }
    }

    local float offset;
    local vector score_position = position;
    local string message = "";
    if(panel.Orientation == FO_HUD_INSERT_AFTER) {
        position_x = position_x - ((number_of_teams - 1) * fillsize_x);
    } else if(panel.Orientation == FO_HUD_INSERT_MIDDLE) {
        position_x = position_x - (((number_of_teams - 1) * fillsize_x) / 2);
    }
    float len;
    float textOffset;
    string val;

    for(float i = 0; i < number_of_teams; i++) {
        score_position = position;
        offset = (fillsize_x) * i;
        score_position_x = score_position_x + offset;
        //message = strcat(message, strpad(-3, ftos(TS.team1score)));
        HRC_drawfill(score_position, fillsize, TEXT_TEAM_COLOUR[i], 0.5, 0);
        val = ftos(TeamScore[i]);
        len = strlen(val);
        textOffset = (12 * textScale * (3 - len));
        Hud_DrawStringLMP(score_position + [textOffset,padding], val, 12 * textScale);
    }
};

void Hud_DrawFlagStatusBar()
{
    vector pos;
    float sizey, sizex;
    FO_Hud_Panel* panel = getHudPanel(HUDP_FLAGINFO);
    sizey = FO_Hud_Icon_Size_y * panel->Scale;
    sizex = FO_Hud_Icon_Size_x * panel->Scale;

    float flagInfoCount = 0;
    for (float k = 0; k < 9; k++) {
        if (FlagInfoLines[k].id)
            flagInfoCount++;
    }
    //Show one for reference even on maps without
    if(fo_hud_editor && !flagInfoCount) {
        flagInfoCount = 1;
    }
    vector fillsize = [sizex * 4, sizey * flagInfoCount];
    panel->FillSize = fillsize;
    pos = getScaledPanelPosition(panel, 1);
    float alpha = 0;
    if (hud_panel(panel->id, pos, fillsize, alpha, panel->Display)) {
        // click event
        if (fo_hud_editor)
        {
            // TODO: Delete?  Anything?
        }
    }

    if (flagInfoCount <= 0)
        return;

    float count = 0;
    float org_game = getstatf(STAT_ORG_GAME);
    for (float m = 0; m < 9; m++) {
        if (!FlagInfoLines[m].id)
            continue;

        if (org_game && FlagInfoLines[m].team_no == team_no_attack)
            continue;

        alpha = FlagInfoLines[m].state == FLAGINFO_HOME ? CVARF(fo_hud_idle_alpha) : 1;
        string icon = FlagInfoLines[m].icon.filename;
        vector iconcolour = FlagInfoLines[m].icon.colour;
        float bigfont = 8 * (panel->TextScale ? panel->TextScale : panel->Scale);
        float bigfontvoffset = sizey / 2 - bigfont / 2; //Center text against the icon
        if (FlagInfoLines[m].state == FLAGINFO_CARRIED) {
            HRC_drawstring([GetTextAlignOffset(pos_x,sizex,sizex,FlagInfoLines[m].carrier,bigfont,panel->Orientation), pos_y + bigfontvoffset + sizey * count, 0], FlagInfoLines[m].carrier, [bigfont,bigfont], '1 0 0', 1, 0);
        } else if (FlagInfoLines[m].state == FLAGINFO_DROPPED && FlagInfoLines[m].locname) {
            HRC_drawstring([
                    GetTextAlignOffset(pos_x, sizex, sizex, FlagInfoLines[m].locname,
                        bigfont, panel->Orientation), 
                    pos_y + sizey * count + 2, 0],
                    FlagInfoLines[m].locname, [bigfont,bigfont], '1 1 1', 1, 0);
        }

        HRC_drawpic([pos_x, pos_y + sizey * count, 0], icon, [sizex, sizey, 0], iconcolour, alpha, 0);

        if (FlagInfoLines[m].time_return >= 0) {
            float ret = max(FlagInfoLines[m].time_return - time, 0);
            string stime = sprintf("%0.1f", ret);
            float smallfont = 6 * panel->Scale;
            HRC_drawstring(
                    [
                    GetTextAlignOffset(pos_x, sizex, sizex, stime,
                        smallfont, panel->Orientation),
                    pos_y + sizey * (count + 1) - smallfont - 2, 0],
                    stime, [smallfont, smallfont], '1 1 1', 1, 0);
        }

        count++;
    }
}

void Hud_ScrollPanelSelector(float num, float numlines) { // XXX
    float newpos = getHudPanel(HUDP_OPTIONS)->Status + num;
    if(newpos < 1) {
        getHudPanel(HUDP_OPTIONS)->Status = 1;
    } else if(newpos > (Hud_Panels.length - numlines)) {
        getHudPanel(HUDP_OPTIONS)->Status = Hud_Panels.length - (numlines - 1);
    } else {
        getHudPanel(HUDP_OPTIONS)->Status = newpos;
    }
}

//Draw the list of all panels
void Hud_DrawHudOptionsPanelSelector() {
    if(!fo_hud_editor)
        return;

    vector pos = getPanelPosition(getHudPanel(HUDP_OPTIONS));
    vector size = getHudPanel(HUDP_OPTIONS)->FillSize * getHudPanel(HUDP_OPTIONS)->Scale; //for simplicity, use the same size as options panel
    float textsize = 8 * (getHudPanel(HUDP_OPTIONS)->TextScale ? getHudPanel(HUDP_OPTIONS)->TextScale : getHudPanel(HUDP_OPTIONS)->Scale);
    if((pos.x + (size.x * 2)) < ScreenSize.x) {
        //If there's room on the screen, draw to the right of options panel
        pos.x = pos.x + size.x;
    } else {
        pos.x = pos.x - size.x;
    }
    
    if (hud_panel(HUDP_OPTION_LIST, pos, size, 0, 1))
    {
        // click event
    }

    float numlines = rint(size.y / (textsize + 2));
    // Need to draw scrollbar?
    if((Hud_Panels.length * (textsize + 2)) > size.y) {
        //Scrollbar buttons
        if(hud_button(HUDB_OPTION_SCROLLUP, pos + [size.x - textsize - 2,2], [textsize, textsize], "^")) {
            Hud_ScrollPanelSelector(-1, numlines);
        }
        if(hud_button(HUDB_OPTION_SCROLLDOWN, pos + [size.x - textsize - 2, size.y - textsize - 2], [textsize, textsize], "v")) {
            Hud_ScrollPanelSelector(1, numlines);
        }
    }

    for(float i = 0,j = 0; i < min(numlines, Hud_Panels.length); i++) {
        j = i + getHudPanel(HUDP_OPTIONS)->Status - 1;
        if(hud_button(HUDL_OPTION_BASE + i, pos + [2, (textsize + 2) * i], [size.x - textsize - 4, textsize + 2], getHudPanel(j + HUDP_FIRST)->Name)) {
            Editor_SelectedPanel_Index = j + HUDP_FIRST;
        }
    }
//    for(float i = 0,j = 0; i < min(numlines, Hud_ExtraPanels.length); i++) {
//        j = i + getHudPanel(HUDP_OPTIONS)->Status - 1;
//        if(hud_button(strcat("hud_option_panel_list_item", ftos(i)), pos + [2, (textsize + 2) * i], [size.x - textsize - 4, textsize + 2], Hud_ExtraPanels[j].Name)) {
//            Editor_SelectedPanel_Index = j;
//        }
//    }
}

void Hud_DrawHudOptionsPanel(float display, string text) {
    if(!fo_hud_editor)
        return;
    
    FO_Hud_Panel* panel = getHudPanel(HUDP_OPTIONS);
    vector pos = getPanelPosition(getHudPanel(HUDP_OPTIONS));
    vector size = panel->FillSize * panel->Scale;
    if (hud_panel(panel->id, pos, size, 0, panel->Display))
        panel->Status = 0;  // click event0

    if (Editor_SelectedPanel_Index < HUDP_FIRST || Editor_SelectedPanel_Index > HUDP_LAST)
        Editor_SelectedPanel_Index = HUDP_FIRST;

    FO_Hud_Panel* selectedPanel = getHudPanel(Editor_SelectedPanel_Index);

    //drawstring(pos + [4,4], selectedPanel.Name, [8,8], MENU_SELECTED, 1, 0);
    if(hud_button(HUDB_OPTION_LIST, pos + [4,2], [140, 10], strcat(selectedPanel.Name, " >"))) {
        getHudPanel(HUDP_OPTIONS)->Status = !getHudPanel(HUDP_OPTIONS)->Status;
    }

    if (selectedPanel != panel /* Don't allow editing the options panel itself */) {
        float fscale = selectedPanel->Scale;
        HRC_drawstring(pos + [4,12], strcat("Scale: ",ftos(rint(fscale * 100)), "%"), [8,8], MENU_SELECTED, 1, 0);
        hud_slider(HUDE_OPTION_SCALE_SLIDER, pos + [8,24], [136,8], [0.2,5.0,24], fscale);
        if(fscale != selectedPanel->Scale)
            selectedPanel->Scale = fscale;

        float ftscale = selectedPanel->TextScale;
        string scales = ftscale ? strcat(ftos(rint(ftscale * 100)), "%") : "Auto";
        HRC_drawstring(pos + [4,34], strcat("Text Scale: ",scales), [8,8], MENU_SELECTED, 1, 0);
        hud_slider(HUDE_OPTION_TEXTSCALE_SLIDER, pos + [8,44], [136,8], [0,5.0,25], ftscale);
        if(ftscale != selectedPanel->TextScale)
            getHudPanel(Editor_SelectedPanel_Index)->TextScale = ftscale;
        float ftextalign = selectedPanel->Orientation;
        //drawstring(pos + [4,54], strcat("Text Pos: ", selectedPanel->Orientation ? "Left" : "Right"), [8,8], MENU_SELECTED, 1, 0);
        HRC_drawstring(pos + [4,60], "Text Pos: ", [8,8], MENU_SELECTED, 1, 0);
        if(hud_button(HUDE_OPTION_TEXTALIGN_TOGGLE, pos + [size.x - 6 - 56,56], [56, 16], HUD_ALIGN[selectedPanel->Orientation])) {
            selectedPanel->Orientation = (selectedPanel->Orientation + 1) % 3;
        }
        //hud_slider("hud_option_textalign_scroll", pos + [8,64], [32,8], [0,1,1], ftextalign);
        //if(ftextalign != selectedPanel->Orientation) {
        //    getHudPanel(Editor_SelectedPanel_Index)->Orientation = ftextalign;
        //}    
        if(!selectedPanel->System && hud_button(HUDE_OPTION_SHOWHIDE_TOGGLE, pos + [4,74], [140, 16], selectedPanel->Display ? "Hide Panel" : "Show Panel")) {
            FO_Hud_SetDisplay(selectedPanel->id, !selectedPanel->Display);
        }
    }
    HRC_drawstring(pos + [4,96],"Position: ", [8,8], MENU_SELECTED, 1, 0);
    HRC_drawstring(pos + [10,106], strcat("x: ",ftos(selectedPanel.Position.x)), [8,8], MENU_SELECTED, 1, 0);
    HRC_drawstring(pos + [10,116], strcat("y: ",ftos(selectedPanel.Position.y)), [8,8], MENU_SELECTED, 1, 0);

    local float snap = 0;
    local string ssnap;
    if(selectedPanel->Snap & 2) {
        snap = 1;
    } else if(selectedPanel->Snap & 4) {
        snap = 2;
    } else {
        snap = 0;
    }
    HRC_drawstring(pos + [4,130], "Hor. Snap: ", [8,8], MENU_SELECTED, 1, 0);
    if(hud_button(HUDE_OPTION_HSNAP_TOGGLE, pos + [size.x - 6 - 56,126], [56, 16], HUD_HORIZONTAL_ALIGN[snap])) {
        snap = (snap + 1) % 3;
        getHudPanel(Editor_SelectedPanel_Index)->Position.x = 0;
        getHudPanel(Editor_SelectedPanel_Index)->Snap -= (getHudPanel(Editor_SelectedPanel_Index)->Snap & 7);
        getHudPanel(Editor_SelectedPanel_Index)->Snap += pow(2,snap);
    }
    if(getHudPanel(Editor_SelectedPanel_Index)->Snap & 16) {
        snap = 1;
    } else if(getHudPanel(Editor_SelectedPanel_Index)->Snap & 32) {
        snap = 2;
    } else {
        snap = 0;
    }
    HRC_drawstring(pos + [4,148], "Ver. Snap: ", [8,8], MENU_SELECTED, 1, 0);
    if(hud_button(HUDE_OPTION_VSNAP_TOGGLE, pos + [size.x - 6 - 56,144], [56, 16], HUD_VERTICAL_ALIGN[snap])) {
        snap = (snap + 1) % 3;
        getHudPanel(Editor_SelectedPanel_Index)->Position.y = 0;
        getHudPanel(Editor_SelectedPanel_Index)->Snap -= (getHudPanel(Editor_SelectedPanel_Index)->Snap & 56);
        getHudPanel(Editor_SelectedPanel_Index)->Snap += pow(2,(snap + 3));
    }
    
    if(hud_button(HUDE_OPTION_SHOWALL_TOGGLE, pos + [4,162], [140, 16], getHudPanel(HUDP_OPTIONS)->Style ? "Show All" : "Show HUD Only")) {
        getHudPanel(HUDP_OPTIONS)->Style = !getHudPanel(HUDP_OPTIONS)->Style;
    }
    FO_Hud_ShowPanel(HUDP_OPTIONS);

    if(getHudPanel(HUDP_OPTIONS)->Status) {
        Hud_DrawHudOptionsPanelSelector();
    }
}

void Hud_DrawClassInfoPanel(float playerclass)
{
    const float id = HUDP_SPECIAL;
    FO_Hud_Panel* panel = getHudPanel(id);
    vector pos = getPanelPosition(panel);

    if(fo_hud_editor) {
        hud_panel(id, pos, panel->FillSize * panel->Scale, 0, panel->Display);
        HRC_drawpic(pos, "textures/wad/face1", FO_Hud_Icon_Size * panel->Scale, '1 1 1', 1, 0);
        return;
    }
    
    if (!fo_hud_editor && !panel->Display)
        return;

    switch (WP_PlayerClass()) {
        case PC_SOLDIER:
            return;
    }

    if (!WP_PlayerClass() || WP_PlayerClass() == PC_SOLDIER)
        return;

    if (hud_panel(id, pos, panel->FillSize * panel->Scale, 0, panel->Display)) {
        // click event
    }

    float val;
    vector size = FO_Hud_Icon_Size * panel->Scale;
    vector fontSize = FO_Hud_Icon_Font_Size * (panel->TextScale ? panel->TextScale : panel->Scale);
    pos = [pos_x + 2, pos_y + 2, 0];
    vector basepos = pos;
    vector colour = '1 1 1';
    string icon = "";
    string msg = "";

    //icon = HudIcons[playerclass-1].icon;
    /* icon = HudIcons[playerclass+6].icon; */
    /* HRC_drawpic(pos, icon, size, '1 1 1', 1, 0); */

    float len = 0, offset = 0;

    switch (playerclass)
    {
        case PC_SCOUT:
            icon = ICON_SCOUT; //HudIcons[playerclass+6].icon;
            HRC_drawpic(pos, icon, size, '1 1 1', 1, 0);

            msg = SBAR.ScannerOn ? "Scanning" : "Offline";
            pos = HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, FALSE, colour);
            if (SBAR.ScannerOn)
            {
                msg = SBAR.ScannerRange ? strcat("Dist: ", ftos(SBAR.ScannerRange)) : "No targets";
                pos = HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, TRUE, colour);
                if (SBAR.ScannerRange)
                {
                    msg = (SBAR.ScannerTeamNo == team_no) ? "Friendly" : "Enemy";
                    msg = strcat(msg, " ", ClassToString(SBAR.ScannerPlayerClass));
                    HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, TRUE, colour);
                }
            }
            break;
        case PC_SNIPER:
            float sniper_dam = WP_SniperCharge();
            if (sniper_dam)
            {
                icon = ICON_SNIPER; //HudIcons[playerclass+6].icon;
                HRC_drawpic(pos, icon, size, '1 1 1', 1, 0);

                msg = strcat("Dam: ", ftos(sniper_dam));
                pos = HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, FALSE, colour);

                if (sniper_dam == PC_SNIPER_MAXDAM) {
                    msg = "(100%)";
                    colour = '1 0 0';
                    HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, TRUE, colour);
                }
            }
            break;
        case PC_DEMOMAN:
            if (SBAR.IsDetpacking)
            {
                icon = ICON_DEMOMAN; //HudIcons[playerclass+6].icon;
                HRC_drawpic(pos, icon, size, '1 1 1', 1, 0);

                msg = "Setting";
                pos = HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, FALSE, colour);

                msg = strcat(ftos(SBAR.DetpackLeft), " (", ftos(SBAR.IsDetpacking), ") secs left");
                HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, TRUE, colour);
            }
            else if (SBAR.DetpackLeft)
            {
                icon = ICON_DEMOMAN; //HudIcons[playerclass+6].icon;
                HRC_drawpic(pos, icon, size, '1 1 1', 1, 0);

                msg = strcat(ftos(SBAR.DetpackLeft), " secs left");
                HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, FALSE, colour);
            }
            break;
        case PC_MEDIC:
            icon = ICON_MEDIC; //HudIcons[playerclass+6].icon;
            HRC_drawpic(pos, icon, size, '1 1 1', 1, 0);

            msg = SBAR.AuraActive ? "On" : "Off";
            pos = HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, FALSE, colour);
            if (SBAR.AuraActive)
            {
                if (SBAR.HealCount)
                {
                    msg = strcat(ftos(SBAR.HealCount), " players healed");
                    pos = HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, TRUE, colour);

                    msg = strcat("for ", ftos(SBAR.HealAmount), " hp");
                    HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, TRUE, colour);
                }
                else
                {
                    if (SBAR.AuraStatus == PC_MEDIC_AURA_OUTOFPOWER)
                    {
                        msg = "Out of power";
                        HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, TRUE, colour);
                    }
                    else if (SBAR.AuraStatus == PC_MEDIC_AURA_RECHARGING)
                    {
                        msg = "Recharging";
                        HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, TRUE, colour);
                    }
                }
            }
            break;
        case PC_HVYWEAP:
            if (WP_LockedCannon())
            {
                icon = ICON_HWGUY; //HudIcons[playerclass+6].icon;
                HRC_drawpic(pos, icon, size, '1 1 1', 1, 0);

                msg = "Assault Cannon Locked";
                HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, FALSE, colour);    
            }
            break;
        case PC_PYRO:
            if (pstate_pred.server_time < pstate_pred.special_next) {
                icon = ICON_PYRO; //HudIcons[playerclass+6].icon;
                HRC_drawpic(pos, icon, size, '1 1 1', 1, 0);

                msg = "Airblast Cooling Down";
                HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, FALSE, colour);
            } else {
                icon = ICON_PYRO; //HudIcons[playerclass+6].icon;
                HRC_drawpic(pos, icon, size, '1 1 1', 1, 0);

                msg = "Airblast Ready";
                HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, FALSE, colour);
            }
            break;
        case PC_SPY:
            if (SBAR.IsUndercover == SPY_DISGUISED) {
                icon = ICON_SPY; //HudIcons[playerclass+6].icon;
                HRC_drawpic(pos, icon, size, '1 1 1', 1, 0);

                msg = "Undercover";
                pos = HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, FALSE, colour);
                msg = strcat(TeamToString(SBAR.UndercoverTeam), " ", ClassToString(SBAR.UndercoverSkin));
                HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, TRUE, colour);
            } else if (SBAR.IsUndercover == SPY_DISGUISING) {
                icon = ICON_SPY; //HudIcons[playerclass+6].icon;
                HRC_drawpic(pos, icon, size, '1 1 1', 1, 0);

                msg = "Disguising";
                pos = HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, FALSE, colour);
                if (SBAR.DisguiseTeam)
                {
                    msg = strcat("(", TeamToString(SBAR.DisguiseTeam), SBAR.QueueSkin ? "" : ") ");
                }
                else if (SBAR.QueueTeam)
                {
                    msg = strcat("(", TeamToString(SBAR.QueueTeam), " ");
                }
                else if (SBAR.UndercoverTeam)
                {
                    msg = strcat(TeamToString(SBAR.UndercoverTeam), " ");
                }
                string msg2 = "";
                if (SBAR.DisguiseSkin)
                {
                    msg2 = strcat(SBAR.QueueTeam ? "" : "(", ClassToString(SBAR.DisguiseSkin), ")");
                }
                else if (SBAR.QueueSkin)
                {
                    msg2 = strcat(" ", ClassToString(SBAR.QueueSkin), ")");
                }
                else if (SBAR.UndercoverSkin)
                {
                    msg2 = strcat(ClassToString(SBAR.UndercoverSkin));
                }
                msg = strcat(msg, msg2);
                HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, TRUE, colour);
            }
            break;
        case PC_ENGINEER:
            basepos = pos;
            msg = pstate_pred.server_time >= pstate_pred.special_next ?
                "Impeller charged" : "Impeller recharging";

            msg = strcat(msg, "\n\rCells: ", itos(WP_GetAmmo(AMMO_CELLS)));

            HRC_drawOffsetString(panel->Orientation, msg, size, fontSize,
                    pos, basepos, FALSE, colour);

            pos = [pos_x, pos_y + size_y + 8];

            if (SBAR.IsBuilding) {
                icon = SBAR.IsBuilding == Eng_BuildingDisp ?
                    ICON_ENGINEER_DISP : ICON_ENGINEER_SG;
                HRC_drawpic(pos, icon, size, '1 1 1', 1, 0);

                float rem = max(SBAR.BuildFinish - pstate_pred.server_time, 0);
                msg = sprintf("%0.1f sec remaining", rem);
                HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, FALSE, colour);

                pos = [pos_x, pos_y + size_y + 2];
            }

            if (SBAR.HasSentry) {
                icon = ICON_ENGINEER_SG; //HudIcons[playerclass+6].icon;
                HRC_drawpic(pos, icon, size, '1 1 1', 1, 0);

                msg = strcat("L: ", ftos(SBAR.SentryLevel), " H: ", ftos(rint(SBAR.SentryHealth)), " S: ", ftos(rint(SBAR.SentryAmmoShells)), " R: ", ftos(rint(SBAR.SentryAmmoRockets)));
                HRC_drawOffsetString(panel->Orientation, msg, size, fontSize, pos, basepos, FALSE, colour);
            }

            pos = [pos_x, pos_y + size_y + 2];
            basepos = pos;
            if (SBAR.HasDispenser) {
                icon = ICON_ENGINEER_DISP; //HudIcons[playerclass + 7].icon;
                HRC_drawpic(pos, icon, size, '1 1 1', 1, 0);

                msg = strcat("H: ", ftos(rint(SBAR.DispenserHealth)));
                msg = strcat(msg, " Cells: ", itos(SBAR.DispenserCells));
                HRC_drawOffsetString(panel->Orientation, msg, size, fontSize,
                                     pos, basepos, FALSE, colour);
            }
            break;
    }
}

void Hud_DrawIdentifyPanel(string identify) {
    const float id = HUDP_IDENTIFY;
    FO_Hud_Panel* panel = getHudPanel(id);
    if (!panel->Display && !fo_hud_editor)
        return;

    if(fo_hud_editor && !identify)
        identify = "<Player Name>\n<Player Class>";

    vector pos;
    pos = getPanelPosition(panel);

    if (hud_panel(id, pos, panel->FillSize * panel->Scale, 0, panel->Display)) {
        // click event
    }

    if (time > id_state.id_time + 3 || is_demo ||
        game_state.spawn_gen != id_state.spawn_gen)
          return;

    vector fontSize = FO_Hud_Icon_Font_Size * panel->Scale;

    float count = tokenizebyseparator(identify, "\n");
    float msgcount = 0;
    string msg = "";
    for (float f = 0; f <= count; f++) {
        msg = argv(f);
        // tokenize doesn't handle newlines very well
        msg = strreplace("\n", "", msg);
        msg = strtrim(msg);
        if (strlen(msg) > 0) {
            pos = pos + [0, (fontSize_y * msgcount), 0];
            HRC_drawstring(pos, msg, fontSize, '1 1 1', 1, 0);
            msgcount++;
        }
    }
}

void Hud_DrawPanel(FO_Hud_Panel* panel) {
    float offset = 0;
    if(sui_is_last_clicked(panel.id)) {
        Editor_SelectedPanel_Index = panel->id;
    }
    if(!getHudPanel(HUDP_OPTIONS)->Style || panel.Display || (fo_hud_editor && panel->id == Editor_SelectedPanel_Index)) {
        if (panel.Display || fo_hud_editor)
            panel.drawPanel(panel.id,  panel.getValue());
        //Draw panel names when editing
        if(fo_hud_editor && panel->id != HUDP_OPTIONS) {
            switch (panel.Orientation) {
                case FO_HUD_INSERT_BEFORE:
                    offset = 2;
                    break;
                case FO_HUD_INSERT_AFTER:
                    offset = panel.FillSize.x - (strlen(panel.Name) * 6) - 2;
                    break;
                case FO_HUD_INSERT_MIDDLE:
                    offset = (panel.FillSize.x / 2) - (strlen(panel.Name) * 3); //because 3 = 6/2
                    break;
            }
            HRC_drawstring(getScaledPanelPosition(panel,1) + [offset,2], panel.Name, '6 6', '0 1 0', 1, 0);
        }
    }
}

void Hud_Draw(float width, float height)
{
    for(float i = HUDP_FIRST; i <= HUDP_LAST; i++) {
        FO_Hud_Panel* panel = getHudPanel(i);
        if (!panel->Display && !fo_hud_editor)
            continue;  // Fast-path skip.

        Hud_DrawPanel(panel);
    }
    HudSettings.MousePos = [Mouse.x, Mouse.y];
}

void Hud_Demo(float width, float height) {
    if (!TrackingPlayer())
        return;

    static vector pos;
    static float next_update;
    static string text;

    const vector size = '14 14 0';
    if (time > next_update) {
        text = "^9POV:^7";
        text = strcat(text, getplayerkeyvalue(player_localentnum - 1, INFOKEY_P_NAME));
        float tw = stringwidth(text, TRUE, size);
        pos = [(width - tw) / 2, height - size.y - 60, 0];
        next_update = time + 0.25;
    }

    drawstring(pos, text, size, '1 1 1', 1, 0);
}

static const float HUDP_COUNT = HUDP_LAST - HUDP_FIRST + 1;

static const vector CPRINT_SIZE = '12 12 0';

void Hud_CenterPrint(string msg) {
    center_message.message = msg;
    center_message.expiry = time + 1;

    center_message.x_offset = stringwidth(msg, 1, CPRINT_SIZE) / 2;
    center_message.gen = game_state.spawn_gen;
}

static void Hud_RenderCenterPrint(float width, float height) {
    vector pos = [width/2 - center_message.x_offset,
                  height/4 - CPRINT_SIZE[1]/2, 0];
    drawstring(pos, center_message.message, CPRINT_SIZE, '1 1 1', 1, 0);
};

struct {
    float last_draw[HUDP_COUNT];
    float idx;
} incremental_hud;

static string CSQC_FormatRaceTime(float sec) {
    if (sec <= 0)
        return "00.000s";
    float mins = floor(sec / 60);
    float rem = sec - (mins * 60);
    if (mins > 0)
        return sprintf("%d:%06.3f", mins, rem);
    return sprintf("%06.3fs", rem);
}

void Hud_DrawRaceOverlay(float width, float height) {
    if (showingscores || intermission)
        return;

    float rstate = getstatf(STAT_RACE_STATE);
    float rstart = getstatf(STAT_RACE_START_TIME);
    float rbest = getstatf(STAT_RACE_BEST_TIME);
    float rlast = getstatf(STAT_RACE_LAST_TIME);
    float rsplit = getstatf(STAT_RACE_SPLIT_TIME);
    float qpos = getstatf(STAT_RACE_QUEUE_POS);

    string main_line = "";
    vector main_col = '1 1 1';
    vector main_sz = '14 14 0';

    if (rstate == RACE_STATE_RUNNING && rstart > 0) {
        float elapsed = max(0, time - rstart);
        main_line = strcat("RACE TIME: ", CSQC_FormatRaceTime(elapsed));
        main_col = '0.2 1 0.2';
    } else if (rstate == RACE_STATE_COUNTDOWN && rstart > time) {
        float cd = max(0, rstart - time);
        main_line = sprintf("COUNTDOWN: %0.1fs", cd);
        main_col = '1 0.85 0.1';
    } else if (rstate == RACE_STATE_PRERUN && rstart > time) {
        float ready_rem = max(0, ceil(rstart - time));
        if (team_no == TEAM_BLUE) {
            main_line = sprintf("TYPE 'race' TO START (%ds left)", ready_rem);
            main_col = '0.3 0.8 1';
        } else {
            main_line = sprintf("Queue #%d - Racer readying (%ds)", qpos, ready_rem);
            main_col = '0.8 0.8 0.8';
        }
    } else if (qpos > 0) {
        main_line = sprintf("Queued Spectator (#%d in line) - Type 'race' when ready", qpos);
        main_col = '0.8 0.8 0.8';
    }

    float y = 28;
    if (main_line != "") {
        float tw = stringwidth(main_line, TRUE, main_sz);
        drawstring([(width - tw) / 2, y, 0], main_line, main_sz, main_col, 1, 0);
        y += 18;
    }

    static float c_split_val;
    static string c_split_str;
    static float c_sub_init;
    static float c_best_val;
    static float c_last_val;
    static float c_none_flag;
    static string c_sub_str;

    if (rsplit > 0 && rstate == RACE_STATE_RUNNING) {
        if (c_split_val != rsplit || c_split_str == "") {
            if (c_split_str != "")
                strunzone(c_split_str);
            c_split_str = strzone(strcat("Flag Split: ", CSQC_FormatRaceTime(rsplit)));
            c_split_val = rsplit;
        }
        vector split_sz = '10 10 0';
        float stw = stringwidth(c_split_str, TRUE, split_sz);
        drawstring([(width - stw) / 2, y, 0], c_split_str, split_sz, '1 0.9 0.3', 1, 0);
        y += 13;
    }

    if (rbest > 0 || rlast > 0 || rstate == RACE_STATE_PRERUN || rstate == RACE_STATE_NONE) {
        float show_none = (rstate == RACE_STATE_PRERUN || rstate == RACE_STATE_NONE) ? 1 : 0;
        if (!c_sub_init || c_best_val != rbest || c_last_val != rlast || c_none_flag != show_none || c_sub_str == "") {
            if (c_sub_str != "")
                strunzone(c_sub_str);
            string sub_tmp = "";
            if (rbest > 0)
                sub_tmp = strcat("Map Record: ", CSQC_FormatRaceTime(rbest));
            else if (show_none)
                sub_tmp = "Map Record: None";
            if (rlast > 0) {
                if (sub_tmp != "")
                    sub_tmp = strcat(sub_tmp, "   |   ");
                sub_tmp = strcat(sub_tmp, "Last Run: ", CSQC_FormatRaceTime(rlast));
            }
            c_sub_str = strzone(sub_tmp);
            c_best_val = rbest;
            c_last_val = rlast;
            c_none_flag = show_none;
            c_sub_init = TRUE;
        }
        vector sub_sz = '8 8 0';
        float sub_w = stringwidth(c_sub_str, TRUE, sub_sz);
        drawstring([(width - sub_w) / 2, y, 0], c_sub_str, sub_sz, '0.85 0.85 0.85', 0.9, 0);
        y += 12;
    }

    if (rstate == RACE_STATE_PRERUN || rstate == RACE_STATE_NONE) {
        string vote_hint = "Change map with cmd votemap mapname";
        vector hint_sz = '8 8 0';
        float hint_w = stringwidth(vote_hint, TRUE, hint_sz);
        drawstring([(width - hint_w) / 2, y, 0], vote_hint, hint_sz, '0.85 0.85 0.85', 0.9, 0);
    }
}

void Hud_UpdateView(float width, float height, float menushown) {
    ScreenSize = [width, height, menushown];

    if (is_demo)
        Hud_Demo(width, height);

    Hud_DrawRaceOverlay(width, height);

    if (time < center_message.expiry && game_state.spawn_gen == center_message.gen)
        Hud_RenderCenterPrint(width, height);

    if (HRC_NewFrame()) {
        sui_begin(width, height);
        Menu_Draw(width, height, menushown);
        Hud_Draw(width, height);
        sui_end();
        return;
    }

    if (!hud_render_cache.enabled)
        return;

    // Handle appearance/removal of scoreboard.  Invalidate if it's disappearing
    // and render it immediately for responsiveness if it's been brought up.
    static float last_showingscores;
    if (last_showingscores != showingscores) {
        if (last_showingscores) {
            HRC_Invalidate(getHudPanel(HUDP_SHOWSCORES));
        } else {
            incremental_hud.idx = HUDP_SHOWSCORES - HUDP_FIRST;
            incremental_hud.last_draw[incremental_hud.idx] = 0;
        }
        last_showingscores = showingscores;
    }

    // Skip any not-displayed elements.
    float i = 0, idx = incremental_hud.idx;
    while (!getHudPanel(HUDP_FIRST + idx)->Display &&
            i < HUDP_COUNT) { i++; idx = (idx + 1) % HUDP_COUNT;
    }
    incremental_hud.idx = idx;

    PanelID id = idx + HUDP_FIRST;
    // Time ordered and oldest.
    if (time >= incremental_hud.last_draw[idx] + HRC_fps_time()) {
        FO_Hud_Panel* p = getHudPanel(id);

        sui_begin(width, height);
        HRC_Invalidate(p);
        HRC_SetActive(p);
        Hud_DrawPanel(getHudPanel(id));
        sui_end();

        incremental_hud.last_draw[idx] = time;
        // We'll start searching from here for next incremental update.
        incremental_hud.idx = (incremental_hud.idx + 1) % HUDP_COUNT;
    }

    HRC_Render();
}
