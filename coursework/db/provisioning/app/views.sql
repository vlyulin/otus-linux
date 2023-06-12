CREATE OR REPLACE VIEW totals AS (
	(SELECT 'NO GROUP' AS type, count(sid) as count FROM students WHERE gid IS NULL)
	UNION
	(SELECT 'GROUP' AS type, count(sid) as count FROM students WHERE gid IS NOT NULL)
);

CREATE OR REPLACE VIEW logsummary AS (
	(SELECT substring(data from 1 for 8) AS type, COUNT(id) FROM log GROUP BY type)
);

CREATE OR REPLACE VIEW grouplogins AS (
	SELECT S1.gid, to_char(G.registered, 'MON-DD-YY HH12:MI AM') AS date, S1.login AS l1, S2.login AS l2, S3.login AS l3
	FROM students S1, students S2, students S3, groups G
	WHERE S1.gid = S2.gid AND S2.gid = S3.gid AND S3.gid = G.gid AND S1.login < S2.login AND S2.login < S3.login
);

CREATE OR REPLACE VIEW alllogins AS (
	SELECT S1.login AS l1, S1.gid, to_char(G.registered, 'MON-DD-YY HH12:MI AM') AS date, S2.login AS l2, S3.login AS l3
	FROM students s1, students S2, students S3, groups G
	WHERE S1.gid = S2.gid AND S2.gid = S3.gid AND S3.gid = G.gid AND S1.login != S2.login AND S2.login < S3.login AND S1.login != S3.login
	ORDER BY l1
);
