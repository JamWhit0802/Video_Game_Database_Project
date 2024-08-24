--Function that creates a randomized 10 character player_id
CREATE OR REPLACE FUNCTION idRandomizer
RETURN VARCHAR2
IS
    l_characters VARCHAR(62) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    l_random_str VARCHAR(10) := '';

BEGIN
    FOR i IN 1..10 LOOP
        l_random_str := l_random_str || SUBSTR(l_characters, ROUND(DBMS_RANDOM.VALUE(1, LENGTH(l_characters))), 1);
    END LOOP;
    RETURN l_random_str;
END;
/
-------------------------------------------------------------------------------
--Trigger that checks for duplicate values before a new player is added
CREATE OR REPLACE TRIGGER checkDuplicates
BEFORE INSERT ON loginTable
FOR EACH ROW
DECLARE 
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM loginTable
    WHERE email = :NEW.email;
    
    -- If a duplicate is found, raise an exception
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20000, 'Email is already taken.');
    END IF;
    EXCEPTION
         WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001,'A duplicate value was entered. Try again.');
END;
/
