
//Poll options table
char sql_createPollOptions[] = "CREATE TABLE IF NOT EXISTS polloptions (id MEDIUMINT NOT NULL AUTO_INCREMENT, text VARCHAR(512) NOT NULL, PRIMARY KEY (id));";
char sql_createPollOptionsSqlite[] = "CREATE TABLE IF NOT EXISTS polloptions (id INTEGER PRIMARY KEY, text VARCHAR(512) NOT NULL);";
char sql_insertPollOption[] = "INSERT INTO polloptions (text) VALUES ('%s')";
char sql_getPollOptions[] = "SELECT text, id FROM polloptions;";
char sql_deletePollOption[] = "DELETE FROM polloptions WHERE id = '%i';";
//Vote table
char sql_createVotes[] = "CREATE TABLE IF NOT EXISTS votes (steamid VARCHAR(32) NOT NULL, polloptionid INT(12) NOT NULL, PRIMARY KEY (steamid) FOREIGN KEY (polloptionid) REFERENCES polloptions(id));";
char sql_countTotalVotes[] = "SELECT COUNT(*) FROM votes;";
char sql_countVotesForOption[] = "SELECT polloptions.*, count(votes.polloptionid) as number_of_votes from polloptions left join votes on (polloptions.id = votes.polloptionid) group by polloptions.id order by -number_of_votes";
char sql_insertVote[] = "INSERT OR REPLACE INTO votes (steamid, polloptionid) VALUES ('%s', '%i');";
char sql_findVoteBySteamId[] = "SELECT * FROM votes WHERE steamid = '%s'";

////////////////////////
//// DATABASE SETUP/////
////////////////////////

public void db_setupDatabase() {
	////////////////////////////////
	// INIT CONNECTION TO DATABASE//
	////////////////////////////////
	char szError[255];
	g_hDb = SQL_Connect("polling", false, szError, 255);
	
	if (g_hDb == null)
	{
		SetFailState("Unable to connect to database (%s)", szError);
		return;
	}
	
	char szIdent[8];
	SQL_ReadDriver(g_hDb, szIdent, 8);
	bool mysql = false;
	
	if (strcmp(szIdent, "mysql", false) == 0)
	{
		mysql = true;
		g_DbType = MYSQL;
	}
	else {
		if (strcmp(szIdent, "sqlite", false) == 0)
			g_DbType = SQLITE;
		else
		{
			LogError("Invalid Database-Type");
			return;
		}
	}
	
	// If updating from a previous version
	SQL_LockDatabase(g_hDb);

	db_createTables(mysql);

	
	SQL_UnlockDatabase(g_hDb);
	return;
}

public void db_createTables(bool isMySql) {
	Transaction createTableTnx = SQL_CreateTransaction();

	if (isMySql)
		SQL_AddQuery(createTableTnx, sql_createPollOptions);
	else
		SQL_AddQuery(createTableTnx, sql_createPollOptionsSqlite);

	SQL_AddQuery(createTableTnx, sql_createVotes);
	
	SQL_ExecuteTransaction(g_hDb, createTableTnx, SQLTxn_CreateDatabaseSuccess, SQLTxn_CreateDatabaseFailed);
	
}

public void SQLTxn_CreateDatabaseSuccess(Handle db, any data, int numQueries, Handle[] results, any[] queryData) {
	PrintToServer("[Polling system] Database tables succesfully created!");
}

public void SQLTxn_CreateDatabaseFailed(Handle db, any data, int numQueries, const char[] error, int failIndex, any[] queryData) {
	SetFailState("[Polling system] Database tables could not be created! Error: %s", error);
}

public void db_insertPollOption(char message[512]) {
	char szQuery[256];
	Format(szQuery, 256, sql_insertPollOption, message);
	SQL_TQuery(g_hDb, insertPollOptionCallback, szQuery, 1, DBPrio_Low);
}


public void insertPollOptionCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (hndl == null) {
		LogError("Error inserting poll option:  %s", error);
		return;
	}
	
}

public void db_deletePollOptionMenu() {
	char szQuery[256];
	Format(szQuery, 256, sql_getPollOptions);
	SQL_TQuery(g_hDb, deletePollOptionMenuCallback, szQuery, 1, DBPrio_Low);
}


public void deletePollOptionMenuCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (hndl == null) {
		LogError("Error getting poll options for delete option menu:  %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl))
	{
		Menu menu = new Menu(DeletePollHandler);

		menu.SetTitle("Select which option you want to delete");
		while (SQL_FetchRow(hndl))
		{
			char text[512];
			char option[4];
			SQL_FetchString(hndl, 0, text, 512);
			int optionid = SQL_FetchInt(hndl, 1);
			IntToString(optionid, option, 4);
			menu.AddItem(option, text, ITEMDRAW_DEFAULT);
		}
		menu.ExitButton = false;
		menu.Display(data, MENU_TIME_FOREVER);	 
	}
	return;
	
}

public int DeletePollHandler(Menu menu, MenuAction action,int param1, int param2) {
	if (action == MenuAction_Select)
	{

		char szOptionId[4];
		menu.GetItem(param2, szOptionId, 4);
		int optionid = StringToInt(szOptionId);

		db_deleteOption(optionid);
	}
}

public void deletePollOptionCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (hndl == null) {
		LogError("Error deleting poll option:  %s", error);
		return;
	}
	return;
}

public void db_deleteOption(int optionId) {
	char szQuery[256];
	Format(szQuery, 256, sql_deletePollOption, optionId);
	SQL_TQuery(g_hDb, deletePollOptionCallback, szQuery, 1, DBPrio_Low);
}


public void db_showPollOptionsToClient(int client) {
	char szQuery[512]; //Where servercount = serverId
	Format(szQuery, 512, sql_getPollOptions);

	SQL_TQuery(g_hDb, showPollOptionsToClientCallback, szQuery, client, DBPrio_Low);
}

//DAta = client
public void showPollOptionsToClientCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (hndl == null)
	{
		LogError("Error trying to get poll options %s ", error);
		return;
	}
	
	if (SQL_HasResultSet(hndl))
	{
		Menu menu = new Menu(PlayerVoteHandler);

		char buffer[255];
		GetConVarString(g_pollQuestion, buffer, 255);

		menu.SetTitle(buffer);
		while (SQL_FetchRow(hndl))
		{
			char text[512];
			char option[4];
			SQL_FetchString(hndl, 0, text, 512);
			int optionid = SQL_FetchInt(hndl, 1);
			IntToString(optionid, option, 4);
			menu.AddItem(option, text, ITEMDRAW_DEFAULT);
		}
		menu.ExitButton = false;
		menu.Display(data, MENU_TIME_FOREVER);	 
	}
	return;
}

public int PlayerVoteHandler(Menu menu, MenuAction action,int param1, int param2) {
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{

		char szOptionId[4];
		menu.GetItem(param2, szOptionId, 4);
		int optionid = StringToInt(szOptionId);


		char szSteamId[32];
		GetClientAuthId(param1, AuthId_Steam2, szSteamId, 32, true);
		db_insertVote(szSteamId, optionid, param1);
	}

}


public void db_insertVote(char steamId[32], int optionid, int client) {
	char szQuery[256];
	Format(szQuery, 256, sql_insertVote, steamId, optionid, steamId, steamId);
	SQL_TQuery(g_hDb, insertVoteCallback, szQuery, client, DBPrio_Low);
}

public void insertVoteCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (hndl == null) {
		LogError("Error inserting vote: %s", error);
		return;
	}
	char buffer[255];
	GetConVarString(g_confirmVote, buffer, 255);
	PrintToChat(data, buffer);
}


public void db_showPollResults(int client) {
	char szQuery[256];
	Format(szQuery, 256, sql_countTotalVotes);
	SQL_TQuery(g_hDb, showPollResultsCallback, szQuery, client, DBPrio_Low);
}


public void showPollResultsCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (hndl == null)
	{
		LogError("Error counting total votes %s", error);
		return;
	}
	
	int totalVotes = 0;
	int client = data;
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
			totalVotes = SQL_FetchInt(hndl, 0);

	if (totalVotes == 0){
		PrintToChat(client, "No one voted yet.");
		return;
	}

	Handle pack = CreateDataPack();
	WritePackCell(pack, totalVotes);
	WritePackCell(pack, client);

	char szQuery[512];
	Format(szQuery, 512, sql_countVotesForOption);
	SQL_TQuery(g_hDb, countVotesCallback, szQuery, pack, DBPrio_Low);
}

public void countVotesCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (hndl == null)
	{
		LogError("Error trying to get poll options %s ", error);
		return;
	}
	
	if (SQL_HasResultSet(hndl))
	{
		ResetPack(data);
		int totalVotes = ReadPackCell(data);
		int client = ReadPackCell(data);
		Menu menu = new Menu(PlayerVoteHandler);


		menu.SetTitle("Poll results");
		while (SQL_FetchRow(hndl))
		{
			char text[512];
			SQL_FetchString(hndl, 1, text, 512);
			int votes = SQL_FetchInt(hndl, 2);
			char option[4];
			int optionid = SQL_FetchInt(hndl, 0);
			IntToString(optionid, option, 4);
			char finalText[512];
			float percentage = (float(votes) * 100.0) / totalVotes;
			Format(finalText, 512, "%s (%.1f%s)", text, percentage, "%");
			menu.AddItem(option, finalText, ITEMDRAW_DEFAULT);
		}
		menu.ExitButton = false;
		menu.Display(client, 60);	 
	}
	return;
}

public void db_checkClientVoted(int client) {
	char szQuery[512];

	char szSteamId[32];
	GetClientAuthId(client, AuthId_Steam2, szSteamId, 32, true);
	Format(szQuery, 512, sql_findVoteBySteamId, szSteamId);

	SQL_TQuery(g_hDb, checkClientVotedCallback, szQuery, client, DBPrio_High);
}

public void checkClientVotedCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (hndl == null)
	{
		LogError("Error trying to get vote for client, error: %s ", error);
		return;
	}
	if (SQL_HasResultSet(hndl)){
		if (SQL_GetRowCount(hndl) == 0) {
			db_showPollOptionsToClient(data);
			g_clientVoted[data] = false;
		} else {
			g_clientVoted[data] = true;
		}
	}
	
}