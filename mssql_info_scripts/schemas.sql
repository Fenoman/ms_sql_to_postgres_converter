SELECT S.name
FROM sys.schemas AS S 
WHERE S.name NOT IN 
('sys', 
'INFORMATION_SCHEMA', 
'db_denydatawriter', 
'db_denydatareader',
'db_datawriter',
'db_datareader',
'db_backupoperator',
'db_ddladmin',
'db_securityadmin',
'db_accessadmin',
'db_owner')