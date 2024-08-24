--Creating a new player when a person signs up for the game
CREATE OR REPLACE PROCEDURE newPlayer
(
    v_fname      IN VARCHAR2,
    v_lname     IN VARCHAR2,
    v_email     IN VARCHAR2,
    v_passwrd   IN VARCHAR2,
    v_gamertag  IN VARCHAR2,
    v_player_id  OUT VARCHAR2
)
IS 
    login_timestamp TIMESTAMP;
    v_login_time TIMESTAMP;
    unique_count INTEGER;

BEGIN
    -- Generate a player_id
    v_player_id := idRandomizer();
     
    --Insert values into playerTable
    INSERT INTO playerTable(player_id,gamertag,first_name,last_name)
    VALUES (v_player_id,v_gamertag,v_fname,v_lname);
    
    --Insert values into loginTable
    INSERT INTO loginTable(player_id,email,passwrd)
    VALUES(v_player_id,v_email,v_passwrd);
    
    INSERT INTO loginHistory(player_id,login_timestamp)
    VALUES (v_player_id,SYSTIMESTAMP);
    
    INSERT INTO gameSessions(player_id)
    VALUES(v_player_id);
    
    IF login_timestamp != NULL THEN
        UPDATE loginHistory
        SET login_timestamp = SYSTIMESTAMP
        WHERE player_id = v_player_id;
    END IF;
END newPlayer;
/
-----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE start_or_update_session
(v_player_id IN VARCHAR2,
 v_action IN VARCHAR2) -- 'login' or 'logout'
IS
    v_session_start TIMESTAMP;
    v_session_end TIMESTAMP;
    v_session_playtime NUMBER;
BEGIN
    -- If the action is 'logout', update the session_end
    IF v_action = 'logout' THEN
        BEGIN
            -- Find the active session for the player
            SELECT session_start
            INTO v_session_start
            FROM gameSessions
            WHERE player_id = v_player_id
              AND session_end IS NULL 
              --AND end_session IS NULL
              AND ROWNUM = 1;

            -- Update the session_end
            UPDATE gameSessions
            SET session_end = SYSTIMESTAMP
            WHERE player_id = v_player_id
              AND session_end IS NULL;

            -- Calculate playtime (in minutes)
            v_session_playtime := (EXTRACT(DAY FROM (SYSTIMESTAMP - v_session_start)) * 24 * 60) +
                                  (EXTRACT(HOUR FROM (SYSTIMESTAMP - v_session_start)) * 60) +
                                  EXTRACT(MINUTE FROM (SYSTIMESTAMP - v_session_start));

            -- Update total_playtime for the player
            UPDATE gameSessions
            SET total_playtime = NVL(total_playtime, 0) + v_session_playtime
            WHERE player_id = v_player_id
              AND session_end = (SELECT MAX(session_end) 
                                 FROM gameSessions 
                                 WHERE player_id = v_player_id);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- No active session to end
                RAISE_APPLICATION_ERROR(-20001, 'No active session found to end.');
        END;

    -- If the action is 'login', create or update session_start
    ELSIF v_action = 'login' THEN
        BEGIN
            -- Check if there's an active session
            SELECT session_start, session_end
            INTO v_session_start, v_session_end
            FROM gameSessions
            WHERE player_id = v_player_id
              AND session_end IS NULL
              AND ROWNUM = 1;

            -- If session_end is NULL, there is an active session, so no new session is started
            IF v_session_start IS NOT NULL AND v_session_end IS NULL THEN
                -- Do nothing; session is already active
                NULL;
            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- No active session found, so create a new session
                INSERT INTO gameSessions (player_id, session_start)
                VALUES (v_player_id, SYSTIMESTAMP);
        END;
    END IF;

    -- Update login history regardless of the action
    BEGIN
        INSERT INTO loginHistory (player_id, login_timestamp)
        VALUES (v_player_id, SYSTIMESTAMP);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            -- Handle duplicate entries if you want to update the latest login
            UPDATE loginHistory
            SET login_timestamp = SYSTIMESTAMP
            WHERE player_id = v_player_id;
    END;

    -- Commit changes
    COMMIT;
END;
/

------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE authenticate_user (
    v_email IN VARCHAR2,
    v_password IN VARCHAR2,
    v_player_id OUT VARCHAR2
) AS
BEGIN
    -- Check if the user credentials match an existing record
    SELECT player_id
    INTO v_player_id
    FROM loginTable
    WHERE email = v_email AND passwrd = v_password;

    -- Handle exception if no matching user is found
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_player_id := NULL;
END;
/
-------------------------------------------------------------------------------
--Nested Table for achievement table
DECLARE
    TYPE achievement_t IS TABLE OF VARCHAR(100);
    achievement_list achievement_t := achievement_t(NULL,NULL,NULL,NULL);
BEGIN 
    achievement_list(1):='First Kill';
    achievement_list(2):='Big Spender';
    achievement_list(3):='I Could Walk 500 Miles';
    achievement_list(4):='Whoopsie';
    FOR i IN 1..achievement_list.COUNT LOOP
        INSERT INTO achievements(achievement)
        VALUES(achievement_list(i));
    END LOOP;
END;
/

-------------------------------------------------------------------------------------
--Varray for stats table
CREATE OR REPLACE TYPE class_array IS VARRAY(5) OF VARCHAR2(20);
/

CREATE OR REPLACE PROCEDURE classProcedure
(
    v_player_id IN VARCHAR2
)
IS
    game_class class_array := class_array();
BEGIN
    -- Populate the VARRAY
    game_class := class_array('Mage', 'Healer', 'Warrior', 'Magician', 'Ninja');
    
    -- Loop through the elements of the VARRAY
    FOR i IN 1..game_class.COUNT LOOP
        INSERT INTO gameStatsTable(player_id, playerClass)
        VALUES(v_player_id, game_class(i));
    END LOOP;
    
    -- Commit the transaction (optional based on your use case)
    COMMIT;
END;
/
