INSERT INTO students (
SELECT 	CAST(substring(infostr from 1 for 8) AS INTEGER) AS sid,
	CAST(substring(infostr from 10 for 1) AS CHAR(1)) AS level,
	CAST(substring(infostr from 12 for 1) AS CHAR(1)) AS code,
	CAST(lastname AS VARCHAR(30)),
	CAST(trim(substring(firstmidname from 1 for position(' ' in firstmidname))) AS VARCHAR(30)) AS firstname,
	CAST(trim(substring(firstmidname from position(' ' in firstmidname) + 1)) AS VARCHAR(30)) AS middlename,
	CAST(creditcode AS VARCHAR(5)),
	CAST(units AS VARCHAR(5))
FROM	students_in);

UPDATE students SET firstname=middlename, middlename=NULL WHERE firstname='';
