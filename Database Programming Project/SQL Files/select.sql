--Select statements to show the data in all 4 tables
SELECT * FROM loginTable
ORDER BY player_id ASC;

SELECT * FROM playerTable
ORDER BY player_id ASC;

SELECT * FROM loginHistory
ORDER BY player_id ASC;

SELECT * FROM gameSessions
ORDER BY player_id ASC;