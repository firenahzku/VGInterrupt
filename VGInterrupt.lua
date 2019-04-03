VGI_EnemyCastBar = {
	frame = nil,
	inProgress = false,
	isUnlocked = false,
	isMoving = false,
	castStart = 0,
	castEnd = 0,
	caster = nil,
	spellName = nil,
	targetIconIndex = 0,
	spellIcon = {
		frame = nil,
		texture = nil,
	},
	targetIcon = {
		frame = nil,
		texture = nil,
	},
	castBar = {
		frame = nil,
		text = nil,
		timeLeft = nil,
	},
	onmousemove = function()
		Print( 1 )
	end,
};

VGI_HasteApplied = 0;

VGI_MobsCasting = {};

VGI_LossOfControlEffects = {
	[ "Kidney Shot" ] = 1,
	[ "Cheap Shot" ] = 1,
	[ "Hammer of Justice" ] = 1,
	[ "Seal of Justice" ] = 1,
	[ "Tidal Charm" ] = 1,
	[ "Charge Stun" ] = 1,
	[ "Intercept Stun" ] = 1,
	[ "Concussion Blow" ] = 1,
	[ "Thorium Grenade" ] = 1,
	[ "Iron Grenade" ] = 1,
	[ "Bash" ] = 1,
	[ "Impact" ] = 1,
	[ "Polymorph" ] = 1,
	[ "Pyroclasm" ] = 1,
	[ "Fear" ] = 1,
	[ "Death Coil" ] = 1,
	[ "Howl of Terror" ] = 1,
	[ "Stun" ] = 1,
};

VGI_RaidIconNames = {
	[ 1 ] = "STAR",
	[ 2 ] = "CIRCLE",
	[ 3 ] = "DIAMOND",
	[ 4 ] = "TRIANGLE",
	[ 5 ] = "MOON",
	[ 6 ] = "SQUARE",
	[ 7 ] = "CROSS",
	[ 8 ] = "SKULL",
};

VGI_PATTERN_SHIELDBASH = "(.*)Shield Bash(.*)";
VGI_PATTERN_SHIELDBASH_SUCCESS = "Your Shield Bash [hcr]+its";
VGI_PATTERN_PUMMEL = "(.*)Pummel(.*)";
VGI_PATTERN_PUMMEL_SUCCESS = "Your Pummel [hcr]+its";
VGI_PATTERN_KICK = "(.*)Kick(.*)";
VGI_PATTERN_KICK_SUCCESS = "Your Kick [hcr]+its";
VGI_PATTERN_COUNTERSPELL_SUCCESS = "You interrupt";
VGI_PATTERN_EARTHSHOCK = "(.*)Earth Shock(.*)";
VGI_PATTERN_EARTHSHOCK_SUCCESS = "Your Earth Shock [hcr]+its";

VGI_PATTERN_INCOMING_MELEE_HIT = "(.*) [hcr]+its you for (.*)";
VGI_PATTERN_INCOMING_MELEE_MISS = "(.*) misses you.";
VGI_PATTERN_INCOMING_MELEE_AVOID = "(.*) attacks. You (.*)";

VGI_PATTERN_INCOMING_SPECIALATTACK_HIT = "(.*)'s (.*) [hcr]+its you for (.*)";
VGI_PATTERN_INCOMING_SPECIALATTACK_MISS = "(.*)'s (.*) misses you.";
VGI_PATTERN_INCOMING_SPECIALATTACK_AVOID = "(.*)'s (.*) was (.*)";

function VGI_OnLoad()
	this:RegisterEvent("PLAYER_ENTERING_WORLD");
	this:RegisterEvent("VARIABLES_LOADED");
	this:RegisterEvent("PLAYER_REGEN_ENABLED");
	this:RegisterEvent("PLAYER_REGEN_DISABLED");
	this:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE");
	this:RegisterEvent("CHAT_MSG_ADDON");
	this:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF");
	this:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE");
	this:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS");	-- melee hits
	this:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES");	-- melee misses/parries etc.
	-- this:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE");	-- both special attack misses and hits
	this:RegisterEvent("UNIT_AURA");
	this:RegisterEvent("PLAYER_AURAS_CHANGED");
	this:RegisterEvent("CHAT_MSG_MONSTER_EMOTE");

	SLASH_VGI1 = "/VGI";
	SlashCmdList["VGI"] = function( msg )
		VGI_SlashCommand( msg );
	end
end

function VGI_castAdd( mobName, spellName )
	if ( VGI_MobsCasting[ mobName ] == nil ) then VGI_MobsCasting[ mobName ] = {} end
	if ( VGI_MobsCasting[ mobName ][ spellName ] == nil ) then VGI_MobsCasting[ mobName ][ spellName ] = 0 end
	VGI_MobsCasting[ mobName ][ spellName ] = VGI_MobsCasting[ mobName ][ spellName ] + 1;
	-- Print( mobName.." is casting "..spellName )
end

function VGI_castSubtract( mobName )
	if ( VGI_MobsCasting[ mobName ] == nil ) then return end
	for spellName, casterCount in VGI_MobsCasting[ mobName ] do
		if ( casterCount > 0 ) then
			VGI_MobsCasting[ mobName ][ spellName ] = VGI_MobsCasting[ mobName ][ spellName ] - 1;
		end
	end
end

function VGI_Interrupt()
	local _, playerClass = UnitClass( "player" );
	if ( playerClass == "WARRIOR" ) then
		local hasShield = false;
		VGI_Tooltip:ClearLines();
		VGI_Tooltip:SetInventoryItem( "player", 17 );
		if ( VGI_TooltipTextRight3:IsVisible() and VGI_TooltipTextRight3:GetText() == "Shield" or VGI_TooltipTextRight4:IsVisible() and VGI_TooltipTextRight4:GetText() == "Shield" ) then
			hasShield = true;
		end
		_, _, isBattleStance = GetShapeshiftFormInfo(1);
		_, _, isDefStance = GetShapeshiftFormInfo(2);
		_, _, isZerkerStance = GetShapeshiftFormInfo(3);
		if ( isBattleStance and hasShield ) then
			CastSpellByName( "Shield Bash" );
		elseif ( isDefStance and hasShield ) then
			CastSpellByName( "Shield Bash" );
		elseif ( isZerkerStance ) then
			CastSpellByName( "Pummel" );
		else
			CastSpellByName( "Berserker Stance" );
		end
	elseif ( playerClass == "ROGUE" ) then
		CastSpellByName( "Kick" );
	elseif ( playerClass == "MAGE" ) then
		CastSpellByName( "Counterspell" );
	elseif ( playerClass == "SHAMAN" ) then
		CastSpellByName( "Earth Shock" );
	end
end

function VGI_InterruptIfValid()
	if ( UnitExists( "target" ) ) then
		local targetRaidIconIndex = GetRaidTargetIndex( "target" ) or "0";
		local targetName = UnitName( "target" ) or "";
		if ( not UnitIsPlayer( "target" ) and VGI_Spells[ targetName ] ~= nil )  then
			if ( VGI_EnemyCastBar.inProgress and VGI_EnemyCastBar.caster == targetName and VGI_EnemyCastBar.targetIconIndex == targetRaidIconIndex ) then
				-- If it is a channeled spell, interrupt immediately
				if ( VGI_Spells[ targetName ][ VGI_EnemyCastBar.spellName ].isChanneled == true ) then
					VGI_Interrupt();
				else -- else, delay it
					local alpha = VGI_EnemyCastBar.frame:GetAlpha();
					if ( alpha == 1 ) then VGI_Interrupt(); end
				end
			end
		else
			VGI_Interrupt();
		end
	end
end

function VGI_OnEvent()
	if event == "PLAYER_ENTERING_WORLD" then
		--
	elseif ( event == "PLAYER_REGEN_ENABLED" ) then
		VGI_MobsCasting = {};
		VGI_EnemyCastBar.inProgress = false;
		VGI_EnemyCastBar.targetIconIndex = nil;
		VGI_EnemyCastBar.caster = nil;
		VGI_EnemyCastBar.spellName = nil;
		VGI_EnemyCastBar.frame:SetAlpha(1);
		VGI_EnemyCastBar.frame:Hide();

	elseif ( event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS" or event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES" ) then
		-- A melee attack was attempted against you.
		local mob = nil;
		for mobName, damage in string.gfind( arg1, VGI_PATTERN_INCOMING_MELEE_HIT ) do
			mob = mobName;
			-- handleTheAttack( mobName );
		end
		for mobName, avoidType in string.gfind( arg1, VGI_PATTERN_INCOMING_MELEE_MISS ) do
			mob = mobName;
			-- handleTheAttack( mobName );
		end
		for mobName, avoidType in string.gfind( arg1, VGI_PATTERN_INCOMING_MELEE_AVOID ) do
			mob = mobName;
			-- handleTheAttack( mobName );
		end
		if ( mob ~= nil ) then
			if ( VGI_Spells[ mob ] ~= nil and VGI_MobsCasting[ mob ] ~= nil and UnitExists( "target" ) ) then
				local targetName = UnitName( "target" ) or "";
				local targetRaidIconIndex = GetRaidTargetIndex( "target" ) or "0";
				if ( mob == targetName ) then -- target has the same name
					if ( not UnitIsUnit( "player", "targettarget" ) ) then return end -- target is targeting you
					-- We assume that you are tanking only one of those mobs. So your target is the one that (tried to) hit you.
					SendAddonMessage( "VGI_notCasting", targetRaidIconIndex.."!"..mob.."!"..UnitName( "player" ), "RAID" );
				end
			end
		end
		
	-- elseif ( event == "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE" ) then
	-- 	-- A damaging spell has been cast on you.
	-- 	for mobName, spellName, damage in string.gfind( arg1, VGI_PATTERN_INCOMING_SPECIALATTACK_HIT ) do -- special physical attack or spell landed
	-- 		handleTheAttack( mobName );
	-- 	end
	-- 	for mobName, spellName, avoidType in string.gfind( arg1, VGI_PATTERN_INCOMING_SPECIALATTACK_MISS ) do -- special physical attack missed
	-- 		handleTheAttack( mobName );
	-- 	end
	-- 	for mobName, spellName, avoidType in string.gfind( arg1, VGI_PATTERN_INCOMING_SPECIALATTACK_AVOID ) do -- spell got resisted or special physical attack got avoided
	-- 		handleTheAttack( mobName );
	-- 	end

	elseif ( event == "CHAT_MSG_SPELL_SELF_DAMAGE" ) then
		-- You have used a spell on target.
		if UnitExists( "target" ) and VGI_EnemyCastBar.inProgress then
			local targetRaidIconIndex = GetRaidTargetIndex( "target" ) or "0";
			local targetName = UnitName( "target" ) or "";
			local requiresLossOfControl = VGI_Spells[ VGI_EnemyCastBar.caster ][ VGI_EnemyCastBar.spellName ].requiresLossOfControl;
			
			if ( not requiresLossOfControl ) then
				if ( string.find( arg1, VGI_PATTERN_KICK ) ) then
					if ( string.find( arg1, VGI_PATTERN_KICK_SUCCESS ) ) then
						-- Kick was successful.
						if ( GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 ) then handleSpellEnd( targetRaidIconIndex, targetName );
						else SendAddonMessage( "VGI_Interrupted", targetRaidIconIndex.."!"..targetName, "RAID" ); end
						-- SendChatMessage( "Kick worked.", "SAY" );
					else 
						-- Kick failed.
						SendChatMessage( "Kick FAILED! Someone else interrupt!", "SAY" );
					end
				elseif ( string.find( arg1, VGI_PATTERN_PUMMEL ) ) then
					if ( string.find( arg1, VGI_PATTERN_PUMMEL_SUCCESS ) ) then
						-- Pummel was successful.
						if ( GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 ) then handleSpellEnd( targetRaidIconIndex, targetName );
						else SendAddonMessage( "VGI_Interrupted", targetRaidIconIndex.."!"..targetName, "RAID" ); end
						-- SendChatMessage( "Pummel worked.", "SAY" );
					else 
						-- Pummel failed.
						SendChatMessage( "Pummel FAILED! Someone else interrupt!", "SAY" );
					end
				elseif ( string.find( arg1, VGI_PATTERN_SHIELDBASH ) ) then
					if ( string.find( arg1, VGI_PATTERN_SHIELDBASH_SUCCESS ) ) then
						-- Shield Bash was successful.
						if ( GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 ) then handleSpellEnd( targetRaidIconIndex, targetName );
						else SendAddonMessage( "VGI_Interrupted", targetRaidIconIndex.."!"..targetName, "RAID" ); end
						-- SendChatMessage( "Shield Bash worked.", "SAY" );
					else 
						-- Shield Bash failed.
						SendChatMessage( "Shield Bash FAILED! Someone else interrupt!", "SAY" );
					end
				elseif ( string.find( arg1, VGI_PATTERN_COUNTERSPELL_SUCCESS ) ) then
						-- Counterspell was successful.
						if ( GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 ) then handleSpellEnd( targetRaidIconIndex, targetName );
						else SendAddonMessage( "VGI_Interrupted", targetrgetRaidIconIndex.."!"..targetName, "RAID" ); end
						-- SendChatMessage( "Counterspell worked.", "SAY" );
				elseif ( string.find( arg1, VGI_PATTERN_EARTHSHOCK ) ) then
					if ( string.find( arg1, VGI_PATTERN_EARTHSHOCK_SUCCESS ) ) then
						-- Shield Bash was successful.
						if ( GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 ) then handleSpellEnd( targetRaidIconIndex, targetName );
						else SendAddonMessage( "VGI_Interrupted", targetRaidIconIndex.."!"..targetName, "RAID" ); end
						-- SendChatMessage( "Earth Shock worked.", "SAY" );
					else 
						-- Shield Bash failed.
						SendChatMessage( "Earth Shock FAILED! Someone else interrupt!", "SAY" );
					end
				end
			end
		end

	elseif ( event == "UNIT_AURA" and arg1 == "target" ) then
		-- Target's auras have changed.
		if ( VGI_EnemyCastBar.inProgress ) then 
			local debuffsFound = {};
			local idx = 1;
			local lostControl = false;
			while ( UnitDebuff( "target", idx ) ~= nil ) do
				VGI_Tooltip:ClearLines();
				VGI_Tooltip:SetUnitDebuff( "target", idx );
				if ( VGI_TooltipTextLeft1:IsShown() ) then
					local debuffName = VGI_TooltipTextLeft1:GetText();
					if ( VGI_LossOfControlEffects[ debuffName ] == 1 ) then
						lostControl = true;
						break;
					end
				end
				idx = idx + 1;
			end
			if ( lostControl ) then
				local targetRaidIconIndex = GetRaidTargetIndex( "target" ) or "0";
				local targetName = UnitName( "target" ) or "";
				if ( GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 ) then handleSpellEnd( targetRaidIconIndex, targetName );
				else SendAddonMessage( "VGI_Interrupted", targetRaidIconIndex.."!"..targetName, "RAID" ); end
			end
		end

	-- elseif ( event == "PLAYER_AURAS_CHANGED" ) then
	-- 	local idx = 0;
	-- 	while ( GetPlayerBuff( idx, "HELPFUL" ) ~= -1 ) do
	-- 		local buffIndex, untilCancelled = GetPlayerBuff( idx, "HELPFUL" );
	-- 		VGI_Tooltip:ClearLines();
	-- 		VGI_Tooltip:SetPlayerBuff( buffIndex );
	-- 		if ( VGI_TooltipTextLeft1:IsShown() ) then
	-- 			local buffName = VGI_TooltipTextLeft1:GetText();
	-- 			if ( buffName == "Haste" ) then
	-- 				VGI_HasteApplied = VGI_HasteApplied + 1;
	-- 				CancelPlayerBuff( idx );
	-- 				-- Print( idx );
	-- 				break;
	-- 			end
	-- 		end
	-- 		idx = idx + 1;
	-- 	end

	elseif ( event == "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF" or event == "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE" ) then
		-- A mob has started casting an ability that needs to be interrupted.
		for mobName, spellName in string.gfind( arg1, "(.+) begins to cast (.+)." ) do
			if ( VGI_Spells[ mobName ] ~= nil and VGI_Spells[ mobName ][ spellName ] ~= nil ) then
				VGI_castAdd( mobName, spellName );
				-- The following mobs spawn and start casting spells immediately, so we can't wait for them to be targets before catching their casts
				if ( mobName == "Giant Eye Tentacle" or mobName == "Eye Tentacle" or mobName == "The Prophet Skeram" ) then
					handleSpellCast( 0, mobName, spellName );
				elseif UnitExists( "target" ) then
					-- It may be your target casting the spell.
					local targetRaidIconIndex = GetRaidTargetIndex( "target" ) or "0";
					local targetName = UnitName( "target" ) or "";
					if ( mobName == targetName ) then
						handleSpellCast( targetRaidIconIndex, targetName, spellName );
					end
				end
			end
		end

	elseif ( event == "CHAT_MSG_ADDON" and arg1 == "VGI_Interrupted" ) then
		-- Someone has interrupted a valid mob target.
		-- Print( "Interrupted!" );
		for mobRaidIconIndex, mobName in string.gfind( arg2, "(.+)!(.+)" ) do
			VGI_castSubtract( mobName );
			handleSpellEnd( mobRaidIconIndex, mobName );
			-- Print(1337)
		end
		if ( VGI_EnemyCastBar.caster ~= nil and VGI_MobsCasting[ VGI_EnemyCastBar.caster ][ VGI_EnemyCastBar.spellName ] == 0 ) then
			-- Your target was not casting at all.
			handleSpellEnd( VGI_EnemyCastBar.targetIconIndex, VGI_EnemyCastBar.caster );
		end

	elseif ( event == "CHAT_MSG_ADDON" and arg1 == "VGI_notCasting" ) then
		-- Mob was noticed not to be casting.
		for mobRaidIconIndex, mobName, attackedPlayer in string.gfind( arg2, "(.+)!(.+)!(.+)" ) do
			if ( VGI_EnemyCastBar.inProgress and mobRaidIconIndex == VGI_EnemyCastBar.targetIconIndex and mobName == VGI_EnemyCastBar.caster ) then
				handleSpellEnd( mobRaidIconIndex, mobName );
			elseif ( VGI_EnemyCastBar.inProgress and UnitExists( "target" ) and UnitName( "target" ) == mobName and UnitExists( "targettarget" ) and UnitName( "targettarget" ) == attackedPlayer ) then
				handleSpellEnd( mobRaidIconIndex, mobName );
			end
		end

	elseif ( event == "VARIABLES_LOADED" ) then
		if ( VGI_EnemyCastBar_position == nil ) then VGI_EnemyCastBar_position = { x = nil, y = nil, } end

		VGI_EnemyCastBar.frame = CreateFrame( "Frame", nil, UIParent );
		VGI_EnemyCastBar.frame:SetParent( "UIParent" );
		if ( VGI_EnemyCastBar_position.x == nil ) then 
			VGI_EnemyCastBar.frame:SetPoint( "CENTER", 0, 0 );
			VGI_EnemyCastBar_position.x = 0;
			VGI_EnemyCastBar_position.y = 0;
		else
			VGI_EnemyCastBar.frame:SetPoint( "BOTTOMLEFT", VGI_EnemyCastBar_position.x, VGI_EnemyCastBar_position.y );
		end
		VGI_EnemyCastBar.frame:SetWidth(300);
		VGI_EnemyCastBar.frame:SetHeight(50);
		VGI_EnemyCastBar.frame:SetBackdrop({
			bgFile = "Interface/RaidFrame/UI-RaidFrame-GroupBg",
			tile = true,
			tileSize = 50,
		});
		VGI_EnemyCastBar.frame:SetMovable( true );
		VGI_EnemyCastBar.frame:EnableMouse( true );
		VGI_EnemyCastBar.frame:RegisterForDrag("LeftButton");
		VGI_EnemyCastBar.frame:SetScript( "OnDragStart", function() if ( VGI_EnemyCastBar.isUnlocked ) then VGI_EnemyCastBar.frame:StartMoving() end end );
		VGI_EnemyCastBar.frame:SetScript( "OnDragStop", function() VGI_EnemyCastBar.frame:StopMovingOrSizing(); VGI_EnemyCastBar_position.x = VGI_EnemyCastBar.frame:GetLeft(); VGI_EnemyCastBar_position.y = VGI_EnemyCastBar.frame:GetBottom(); end );
		VGI_EnemyCastBar.frame:Hide();

		VGI_EnemyCastBar.spellIcon.frame = CreateFrame( "Frame", nil, VGI_EnemyCastBar.frame );
		VGI_EnemyCastBar.spellIcon.frame:SetPoint( "TOPLEFT", 0, 0 );
		VGI_EnemyCastBar.spellIcon.frame:SetWidth(50);
		VGI_EnemyCastBar.spellIcon.frame:SetHeight(50);
		-- VGI_EnemyCastBar.spellIcon.frame:SetBackdrop({
		-- 	edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		-- 	edgeSize = "10",
		-- 	tile = true,
		-- });
		VGI_EnemyCastBar.spellIcon.texture = VGI_EnemyCastBar.spellIcon.frame:CreateTexture( nil, "BACKGROUND" );
		VGI_EnemyCastBar.spellIcon.texture:SetAllPoints( VGI_EnemyCastBar.spellIcon.frame )
		-- VGI_EnemyCastBar.spellIcon.texture:Hide();

		VGI_EnemyCastBar.targetIcon.frame = CreateFrame( "Frame", nil, VGI_EnemyCastBar.frame );
		VGI_EnemyCastBar.targetIcon.frame:SetPoint( "TOPRIGHT", 0, 0 );
		VGI_EnemyCastBar.targetIcon.frame:SetWidth(50);
		VGI_EnemyCastBar.targetIcon.frame:SetHeight(50);
		VGI_EnemyCastBar.targetIcon.frame:SetBackdrop({
			edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
			edgeSize = "10",
			tile = true,
		});
		VGI_EnemyCastBar.targetIcon.texture = VGI_EnemyCastBar.targetIcon.frame:CreateTexture( nil, "BACKGROUND" );
		VGI_EnemyCastBar.targetIcon.texture:SetAllPoints( VGI_EnemyCastBar.targetIcon.frame )
		VGI_EnemyCastBar.targetIcon.texture:SetTexture( "Interface/TargetingFrame/UI-RaidTargetingIcons" )
		-- VGI_EnemyCastBar.targetIcon.texture:Hide();

		VGI_EnemyCastBar.castBar.frame = CreateFrame( "StatusBar", nil, VGI_EnemyCastBar.frame );
		VGI_EnemyCastBar.castBar.frame:SetPoint( "TOPLEFT", 50, 0 );
		VGI_EnemyCastBar.castBar.frame:SetWidth(200);
		VGI_EnemyCastBar.castBar.frame:SetHeight(50);
		VGI_EnemyCastBar.castBar.frame:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
		VGI_EnemyCastBar.castBar.frame:SetStatusBarColor( 0, 115/255, 153/255 )
		VGI_EnemyCastBar.castBar.frame:SetBackdrop({
			edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
			edgeSize = "10",
			tile = true,
			insets = { left = 5, right = 5, top = 5, bottom = 5 },
		});
		VGI_EnemyCastBar.castBar.text = VGI_EnemyCastBar.castBar.frame:CreateFontString( nil, "ARTWORK" );
		VGI_EnemyCastBar.castBar.text:SetAllPoints( VGI_EnemyCastBar.castBar.frame );
		VGI_EnemyCastBar.castBar.text:SetShadowColor(0, 0, 0, 1.0)
		VGI_EnemyCastBar.castBar.text:SetShadowOffset(0.80, -0.80)
		VGI_EnemyCastBar.castBar.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE, MONOCHROME");
	end	
end

function handleSpellCast( targetRaidIconIndex, targetName, spellName )
	SetRaidTargetIconTexture( VGI_EnemyCastBar.targetIcon.texture, targetRaidIconIndex );
	VGI_EnemyCastBar.targetIcon.texture:Show();
	VGI_EnemyCastBar.caster = targetName;
	VGI_EnemyCastBar.spellName = spellName;
	VGI_EnemyCastBar.targetIconIndex = targetRaidIconIndex;
	VGI_EnemyCastBar.spellIcon.texture:SetTexture( "Interface/Icons/"..VGI_Spells[ targetName ][ spellName ].icon );
	VGI_EnemyCastBar.spellIcon.texture:Show();
	VGI_EnemyCastBar.inProgress = true;
	VGI_EnemyCastBar.castStart = GetTime();
	VGI_EnemyCastBar.castEnd = VGI_EnemyCastBar.castStart + VGI_Spells[ targetName ][ spellName ].duration;
	VGI_EnemyCastBar.castBar.frame:SetMinMaxValues( VGI_EnemyCastBar.castStart, VGI_EnemyCastBar.castEnd );
	VGI_EnemyCastBar.castBar.frame:SetValue( VGI_EnemyCastBar.castStart );
	VGI_EnemyCastBar.castBar.frame:SetAlpha( 1 );

	VGI_EnemyCastBar.frame:Show();
end

function handleSpellEnd( targetRaidIconIndex, targetName )
	if ( VGI_EnemyCastBar.caster == targetName and ( ( VGI_EnemyCastBar.targetIconIndex ~= 0 and VGI_EnemyCastBar.targetIconIndex == targetRaidIconIndex ) or VGI_MobsCasting[ VGI_EnemyCastBar.caster ][ VGI_EnemyCastBar.spellName ] == 0 ) ) then
		VGI_EnemyCastBar.inProgress = false;
		VGI_EnemyCastBar.targetIconIndex = nil;
		VGI_EnemyCastBar.caster = nil;
		VGI_EnemyCastBar.spellName = nil;
		VGI_EnemyCastBar.frame:SetAlpha(1);
		VGI_EnemyCastBar.frame:Hide();
	end
end

function VGI_OnUpdate()
	if ( VGI_EnemyCastBar.inProgress ) then
		local currentProgress = GetTime();
		if ( currentProgress > VGI_EnemyCastBar.castEnd ) then
			currentProgress = VGI_EnemyCastBar.castEnd;
			VGI_EnemyCastBar.inProgress = false;
		end
		VGI_EnemyCastBar.castBar.frame:SetValue( currentProgress );
		local rounded = math.floor( ( VGI_EnemyCastBar.castEnd - currentProgress ) * 10 ) / 10;
		VGI_EnemyCastBar.castBar.text:SetText( rounded );
		local alpha = 2 * ( currentProgress - VGI_EnemyCastBar.castStart ) / ( VGI_EnemyCastBar.castEnd - VGI_EnemyCastBar.castStart );
		if ( alpha > 1 ) then alpha = 1 end
		VGI_EnemyCastBar.frame:SetAlpha( alpha );
	elseif ( not VGI_EnemyCastBar.isUnlocked ) then
		handleSpellEnd( VGI_EnemyCastBar.targetIconIndex, VGI_EnemyCastBar.caster );
	end
end

function VGI_SlashCommand( msg )
	if ( msg == "" ) then
		DEFAULT_CHAT_FRAME:AddMessage( "Vanguard Interrupt (VGI), by Erminn <Vanguard> of Kronos, Twinstar" );
		DEFAULT_CHAT_FRAME:AddMessage( "/vgi move" );
		DEFAULT_CHAT_FRAME:AddMessage( "/vgi reset" );
	elseif ( msg == "move" ) then
		if ( not VGI_EnemyCastBar.isUnlocked ) then
			VGI_EnemyCastBar.isUnlocked = true;
			VGI_EnemyCastBar.castBar.text:SetText( "Move this bar" );
			VGI_EnemyCastBar.frame:Show();
		else
			VGI_EnemyCastBar.isUnlocked = false;
			VGI_EnemyCastBar_position.x = VGI_EnemyCastBar.frame:GetLeft();
			VGI_EnemyCastBar_position.y = VGI_EnemyCastBar.frame:GetBottom();
			VGI_EnemyCastBar.frame:Hide();
		end
	elseif ( msg == "reset" ) then
		VGI_EnemyCastBar.frame:SetPoint( "CENTER", 0, 0 );
	end
end