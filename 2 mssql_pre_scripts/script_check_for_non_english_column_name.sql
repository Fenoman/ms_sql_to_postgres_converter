SELECT 
	C.name, T.name, ASCII(c.name)
FROM sys.columns AS C
INNER JOIN sys.tables AS T
	ON T.object_id = C.object_id
WHERE T.is_ms_shipped = 0
	AND ASCII(c.Name) NOT BETWEEN 65/* A */ and 90/* Z */
	AND ASCII(c.Name) NOT BETWEEN 97 /* a */ AND 122 /* z */
	AND ASCII(c.Name) NOT BETWEEN 48 /* 0 */ AND 57 /* 9 */
