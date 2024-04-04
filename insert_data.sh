#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# First test that the file games.csv exists...if not we can't do anything.
if [[ -a ./games.csv ]]
then
  # If the file exists proceed to load the data.
  echo "Loading games.csv file into database 'worldcup'; tables 'games' and 'teams'..." 

  # The first thing I want to do here is remove existing data s owe can replace it.
  echo $($PSQL "TRUNCATE teams, games")

  # Read the file...
  cat games.csv | while IFS="," read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
  do
    # Skip the first line (headers)...or rather, DO the following code for any case EXCEPT $YEAR == 'year'
    if [[ $YEAR != "year" ]]
    then

      # The rest of the code to load the data.
      # First insert the teams into the table if they don't exist.  we need to check $WINNER and $OPPONENT
      # Get the winner_id
      WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name = '$WINNER'")

      # If the WINNER is not found...
      if [[ -z $WINNER_ID ]]
      then

        # Insert the WINNER team into teams table.
        INSERT_WINNER_RESULT=$($PSQL "INSERT INTO teams(name) VALUES('$WINNER')")
        # Test the success of the insert.
        if [[ $INSERT_WINNER_RESULT == "INSERT 0 1" ]]
        then
          # Upon successful INSERT, get the new WINNER_ID and print a confirmation to the user.
          # I don't test the success of the SELECT because I just INSERTed it...unless the DB
          # server or network just crashed we can *assume* it will work.
          WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name = '$WINNER'")
          echo "Inserted team, $WINNER, into teams table."

        fi # INSERT of WINNER successful
      fi # Does WINNER exist in teams table?

      # Next do the same for the opponent.  Does the OPPONENT exist in the table?
      OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name = '$OPPONENT'")
      if [[ -z $OPPONENT_ID ]]
      then

        # Insert the OPPONENT team into teams table.
        INSERT_OPPONENT_RESULT=$($PSQL "INSERT INTO teams(name) VALUES('$OPPONENT')")
        # Test the success of the insert.
        if [[ $INSERT_OPPONENT_RESULT == "INSERT 0 1" ]]
        then
          # Upon successful INSERT, get the new OPPONENT_ID and print a confirmation to the user.
          # I don't test the success of the SELECT because I just INSERTed it...unless the DB
          # server or network just crashed we can *assume* it will work.
          OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name = '$OPPONENT'")
          echo "Inserted team, $OPPONENT, into teams table."
        fi # INSERT of OPPONENT successful
      fi # Does OPPONENT exist in the teams table?

      # We have inserted necessary rows into the teams table, now insert the game...
      # We have game_id but what really makes a game unique? It's YEAR, ROUND, WINNER and OPPONENT.
      # Those four values have to define the score (winner_goals, opponent_goals) or there is 
      # something very wrong with reality...
      # Do the INSERT
      GAMES_INSERT_RESULT=$($PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES($YEAR, '$ROUND', $WINNER_ID, $OPPONENT_ID, $WINNER_GOALS, $OPPONENT_GOALS)")

      # Test the success of the insert
      if [[ $GAMES_INSERT_RESULT == "INSERT 0 1" ]]
      then

        #  Print a confirmation to the user.
        echo "Inserted into games table: $YEAR, $ROUND, $WINNER, $OPPONENT"
      fi # Test the INSERT into games
    fi # If we are NOT on the header row...

  done # Do while we are reading lines of the file.

else
  # If the files does not exist then exit.
  echo -e "\n~~ FILE ERROR ~~"
  echo -e "\nThe file 'games.csv' does not exist in the present directory.  Please make sure this file is present and re-run the script"
fi