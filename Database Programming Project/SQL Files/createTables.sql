DROP TABLE playerTable CASCADE CONSTRAINTS;
DROP TABLE loginTable CASCADE CONSTRAINTS;
DROP TABLE loginHistory CASCADE CONSTRAINTS;
DROP TABLE gameSessions CASCADE CONSTRAINTS;
DROP TABLE achievements CASCADE CONSTRAINTS;
DROP TABLE gameStatsTable CASCADE CONSTRAINTS;
--Create table playerTable
CREATE TABLE playerTable
(
    player_id   CHAR(10)    PRIMARY KEY,
    gamertag    VARCHAR(20) UNIQUE NOT NULL,
    first_name  VARCHAR(20) NOT NULL,
    last_name   VARCHAR(30) NOT NULL
);

--Create table loginTable
CREATE TABLE loginTable
(
    player_id   CHAR(10)    UNIQUE NOT NULL, 
    email       VARCHAR(100) UNIQUE NOT NULL,
    passwrd      VARCHAR(255)UNIQUE NOT NULL,
    FOREIGN KEY (player_id) REFERENCES playerTable(player_id)
);

--Create table loginHistory
CREATE TABLE loginHistory
(
    player_id       CHAR(10) NOT NULL,
    login_timestamp TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES playerTable(player_id)
);

--Create table gameSessions
CREATE TABLE gameSessions (
    player_id           CHAR(10)  NOT NULL,
    session_start       TIMESTAMP,
    session_end         TIMESTAMP,
    total_playtime      NUMBER,
    FOREIGN KEY (player_id) REFERENCES playerTable(player_id)
);

--Create table achievements
CREATE TABLE achievements 
(
    player_id           CHAR(10),
    achievement         VARCHAR(100),
    achievement_date    DATE,
    FOREIGN KEY(player_id) REFERENCES playerTable(player_id)
);

--Create table gameStatsTable
CREATE TABLE gameStatsTable (
    player_id   CHAR(10),
    playerClass VARCHAR(20),
    FOREIGN KEY (player_id) REFERENCES playerTable(player_id)
);

    
    
    