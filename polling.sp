
/*=============================================
=            polling - CS:GO surf Timer 	*
*					By alerad 			    =
=============================================*/


#include <sourcemod>
#include <sdkhooks>
#include <adminmenu>
#include <cstrike>
#include <smlib>
#include <sdktools>
#include <basecomm>
#include <colors>
#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <dhooks>


// Require new syntax and semicolons
#pragma semicolon 1

// Plugin info
#define VERSION "0.1"

// Database definitions
#define MYSQL 0
#define SQLITE 1

/*===================================
=            Plugin Info            =
===================================*/

public Plugin myinfo = {
	name = "Polling", 
	author = "Hamster", 
	description = "Polling system for the data-driven people out there", 
	version = VERSION, 
	url = ""
};



ConVar g_pollQuestion = null;
ConVar g_confirmVote = null;
/*----------  SQL Variables  ----------*/
Handle g_hDb = null; 											// SQL driver
int g_DbType; 													// Database type
bool g_clientVoted[MAXPLAYERS + 1];

#include "polling/sql.sp"

public void OnPluginStart() {

	RegAdminCmd("sm_deletepolloption", Admin_DeletePollOption, ADMFLAG_ROOT, "Delete an option from the poll");
	RegAdminCmd("sm_createpolloption", Admin_InsertPollOption, ADMFLAG_ROOT, "Add an option to the poll");
	RegAdminCmd("sm_addoption", Admin_InsertPollOption, ADMFLAG_ROOT, "Add an option to the poll");
	RegAdminCmd("sm_deleteoption", Admin_DeletePollOption, ADMFLAG_ROOT, "Delete an option from the poll");

	RegConsoleCmd("sm_poll", ShowPollResults, "Vote an option for the poll");
	RegConsoleCmd("sm_pollresults", ShowPollResults, "Show poll results");
	RegConsoleCmd("sm_results", ShowPollResults, "Show poll results");

	g_pollQuestion = CreateConVar("poll_question", "Vote for the future of our server", "Question to be asked when the players are voting.");
	g_confirmVote = CreateConVar("poll_confirmvote", "Thank-you for voting", "Display message when the user votes for a option.");
	db_setupDatabase();
}

public Action Admin_InsertPollOption(int client, int args) {
	if (args == 0)
	{
		ReplyToCommand(client, "[CK] Usage: sm_createpolloption text");
		return Plugin_Handled;
	}
	if (args > 0)
	{
		char message[512];
		GetCmdArgString(message, sizeof(message));
		db_insertPollOption(message);
	}
	PrintToConsole(client, "Option succesfuly inserted");
	return Plugin_Handled;

}


public Action Admin_DeletePollOption(int client, int args) {
	db_deletePollOptionMenu();
	PrintToConsole(client, "Option succesfuly deleted");
	return Plugin_Handled;

}

public Action ShowPoll(int client, int args) {
	db_showPollOptionsToClient(client);
	return Plugin_Handled;
}

public Action ShowPollResults(int client, int args) {
	db_showPollResults(client);
	return Plugin_Handled;
}

public OnClientConnected(int client) {
	CreateTimer(10.0, AskVote, client);
}

public Action AskVote(Handle timer, any client)
{
	db_checkClientVoted(client);
}