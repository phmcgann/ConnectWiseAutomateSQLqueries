(SELECT cl.name AS `Client`, l.name AS `Location`, c.name AS `computer name`, c.computerid ,
    (CASE (IF(cc.cachedir='',0,1))+(IF(cc.Cacheusername='',0,1))+(IF(cc.cachepassword='',0,1))
        WHEN 0 THEN "None"
        WHEN 3 THEN "Has Cache"
        ELSE "**Incomplete**"
        END) AS "Cache Status",
        (CASE CachePatch
            WHEN 0 THEN "Disbled"
            WHEN 1 THEN "OK"
            END) AS "Cache Patch",
        (CASE CacheSoftware
            WHEN 0 THEN "Disbled"
            WHEN 1 THEN "OK"
            END) AS "Cache Software",
        (CASE CacheUpdate
            WHEN 0 THEN "Disbled"
            WHEN 1 THEN "OK"
            END) AS "Cache URL"
        FROM computerconfig cc JOIN computers c ON c.computerid=cc.computerid JOIN locations l ON l.locationid=c.locationid JOIN clients cl ON c.clientid = cl.clientid

);
