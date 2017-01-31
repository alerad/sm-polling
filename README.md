# sm-polling
Admin Commands
sm_addoption/sm_createpolloption 
sm_deleteoption/sm_deletepolloption

User commands
sm_poll
sm_results

Both commands do the same, it displays the options and you can vote for them

A polling system for the data-driven people out there

Works with SQLite and MySql. You need to add this to your databases.cfg

"polling"
	{

    	"driver" "sqlite"
    	"host" "localhost"
    	"database" "polling-sqlite"
    	"user" "root"
    	"pass" ""

	}
  
  or for mysql
  
  "polling"
	{

    	"driver" "mysql"
    	"host" "localhost"
    	"database" "polling-sqlite"
    	"user" "root"
    	"pass" ""

	}
