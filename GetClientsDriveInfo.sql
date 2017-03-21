
SELECT
  clients.name AS 'Client'
  , COUNT(DISTINCT computers.computerid) AS 'Total Servers'
  ,  ROUND(((SUM(drives.size))/1024),0) AS 'Total Drive Size GB'
  ,  ROUND(((SUM(drives.free))/1024),0) AS 'Total Drive free GB'
  ,  ROUND(((SUM(drives.size-drives.free))/1024),0) AS 'Total Drive usage GB'
FROM
     computers
LEFT OUTER JOIN
     clients ON computers.clientid = clients.clientid
LEFT OUTER JOIN
     drives ON computers.ComputerID = drives.computerid
WHERE
     computers.os LIKE '%server%'
     AND drives.filesystem REGEXP 'ntfs|refs'
 GROUP BY
     computers.clientID;
     
     
