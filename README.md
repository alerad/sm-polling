# sm-polling
Admin Commands
sm_addoption/sm_createpolloption 
sm_deleteoption/sm_deletepolloption

User commands
sm_poll
sm_results

Both commands do the same, it displays the options and you can vote for them

A polling system for the data-driven people out there

Works only with SQLite, feel free to modify and pull request.

You need to add this to your database.cfg

"polling"
	{

    	"driver" "sqlite"
    	"host" "localhost"
    	"database" "polling-sqlite"
    	"user" "root"
    	"pass" ""

	}
  
