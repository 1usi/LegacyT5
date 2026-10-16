// Black Ops Zombies Plutonium - Legacy (WaW homage mod, Plutonium T5)
//
//  1. Max 24 zombies a round (solo and co-op)
//  2. Zombies can't attack through barriers (whole lobby)
//  3. Backwards movement speed set to 1 (whole lobby)
//  4. Every player starts with 333 points
//  
//  
//
// Install: %localappdata%\Plutonium\storage\t5\scripts\sp\Legacy(with)Timer.gsc


init()
{
	// ---- settings ----
	level.legacy_zombie_cap = 24;
	level.legacy_start_points = 333;
	level.legacy_back_speed = 1;

	level thread legacy_zombie_cap();
	level thread legacy_tweaks();
	level thread legacy_on_connect();
}

// 1. Stock round total, clamped to the cap. Early rounds already
//    under 24 are left alone.
legacy_zombie_cap()
{
	level endon( "end_game" );

	for ( ;; )
	{
		wait( 0.05 );

		if ( !isDefined( level.zombie_total ) )
			continue;

		if ( level.zombie_total > level.legacy_zombie_cap )
			level.zombie_total = level.legacy_zombie_cap;
	}
}

// 2 + 3. Lobby-wide values the stock game reads. Re-applied every second
//        so the game's own init can't overwrite them after we start.
legacy_tweaks()
{
	level endon( "end_game" );

	for ( ;; )
	{
		// zombies at a barrier can't hit anyone standing behind it
		level.attack_player_thru_boards_range = 0;

		// backwards speed (server side)
		setDvar( "player_backSpeedScale", level.legacy_back_speed );

		wait( 1 );
	}
}

// Per-player setup (players already in the game, and anyone who joins).
legacy_on_connect()
{
	level endon( "end_game" );

	players = getEntArray( "player", "classname" );
	for ( i = 0; i < players.size; i++ )
		players[i] thread legacy_setup_player();

	for ( ;; )
	{
		level waittill( "connecting", player );
		player thread legacy_setup_player();
	}
}

legacy_setup_player()
{
	self thread legacy_start_points();
	self thread legacy_back_speed();
	self thread legacy_banner();
	self thread legacy_timer();
}

// 3. Same value on every client so movement prediction matches the server.
legacy_back_speed()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self setClientDvar( "player_backSpeedScale", level.legacy_back_speed );
		wait( 5 );
	}
}

// 4. Starting points, once per player on their first spawn.
legacy_start_points()
{
	self endon( "disconnect" );

	if ( isDefined( self.legacy_points_given ) )
		return;

	self.legacy_points_given = true;

	self waittill( "spawned_player" );

	// let the stock script set its own starting score first
	wait( 2 );

	self.score = level.legacy_start_points;
	self.score_total = level.legacy_start_points;
}

// 5. "legacy loaded" banner: hot pink, shown to every player at game start.
legacy_banner()
{
	self endon( "disconnect" );

	self waittill( "spawned_player" );

	// let the intro screen finish first
	wait( 5 );

	hud = newClientHudElem( self );
	hud.horzAlign = "center";
	hud.vertAlign = "middle";
	hud.alignX = "center";
	hud.alignY = "middle";
	hud.x = 120;   // pixels right of the screen centre (bigger = further right)
	hud.y = 0;
	hud.fontScale = 1.3;
	hud.font = "objective";
	hud.sort = 100;
	hud.foreground = true;
	hud.hidewheninmenu = true;
	hud.alpha = 1;
	hud.color = ( 1, 0.41, 0.71 );
	hud setText( "legacy loaded" );

	// stay for a few seconds, then fade out
	wait( 5 );

	hud fadeOverTime( 1 );
	hud.alpha = 0;
	wait( 1 );

	hud destroy();
}

// 6. Pink game timer, top left, counting up from the first player's spawn.
//    Everyone sees the same time, including players who join later.
legacy_timer()
{
	self endon( "disconnect" );

	self waittill( "spawned_player" );

	if ( !isDefined( level.legacy_game_start ) )
		level.legacy_game_start = getTime();

	hud = newClientHudElem( self );
	hud.horzAlign = "left";
	hud.vertAlign = "top";
	hud.alignX = "left";
	hud.alignY = "top";
	hud.x = 10;
	hud.y = 10;
	hud.fontScale = 1.6;
	hud.font = "objective";
	hud.sort = 100;
	hud.foreground = true;
	hud.hidewheninmenu = true;
	hud.alpha = 1;
	hud.color = ( 1, 0.41, 0.71 );

	// built-in count-up clock: no text updates needed
	hud setTimerUp( ( getTime() - level.legacy_game_start ) / 1000 );
}
