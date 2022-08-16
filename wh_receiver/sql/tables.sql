CREATE TABLE IF NOT EXISTS ATVsummary (
  `timestamp` datetime NOT NULL,
  `deviceName` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `arch` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `productmodel` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `atlasSh` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `55atlas` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `monitor` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `whversion` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pogo` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `atlas` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `temperature` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `magisk` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `magisk_modules` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `MACw` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `MACe` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ip` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ext_ip` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hostname` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `diskSysPct` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `diskDataPct` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `numPogo` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`deviceName`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `ATVstats` (
  `timestamp` timestamp NOT NULL,
  `RPL` smallint(6) NOT NULL,
  `deviceName` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `temperature` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `memTot` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `memFree` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `memAv` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `memPogo` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `memAtlas` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cpuSys` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cpuUser` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cpuL5` float COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cpuL10` float COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cpuL15` float COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cpuPogoPct` float COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cpuApct` float COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `diskSysPct` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `diskDataPct` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
PRIMARY KEY (`deviceName`,`timestamp`,`RPL`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `version` (
  `key` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `version` smallint(6) NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- update version
INSERT IGNORE INTO version values ('atlas_atvdetails',1);
UPDATE version set version = 1 where version.key = 'atlas_atvdetails';
