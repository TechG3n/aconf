CREATE TABLE IF NOT EXISTS `ATVsummary` (
  `timestamp` datetime NOT NULL,
  `deviceName` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `arch` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `productmodel` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `atlasSh` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `55atlas` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `42atlas` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `aegisSh` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `55aegis` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `42aegis` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `monitor` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `whversion` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pogo` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `atlas` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `aegis` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `temperature` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `magisk` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `magisk_modules` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `MACw` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `MACe` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ip` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ext_ip` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hostname` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `playstore` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `proxyinfo` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `diskSysPct` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `diskDataPct` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `numPogo` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reboot` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `authBearer` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `token` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `rdmUrl` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `onBoot` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
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
  `memAegis` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
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

CREATE TABLE IF NOT EXISTS `ATVlogs` (
  `timestamp` datetime NOT NULL,
  `deviceName` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reboot` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `a_pogoStarted` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `a_injection` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `a_ptcLogin` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `a_atlasCrash` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `a_aegisCrash` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `a_rdmError` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `m_noInternet` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `m_noConfig` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `m_noLicense` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `m_atlasDied` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `m_aegisDied` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `m_pogoDied` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `m_deviceOffline` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `m_noRDM` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `m_noFocus` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `m_unknown` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
PRIMARY KEY (`deviceName`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ATVMonitor` (
  `timestamp` datetime NOT NULL,
  `deviceName` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `issue` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `action` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `script` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `version` (
  `key` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `version` smallint(6) NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Update 1
ALTER TABLE ATVsummary
ADD COLUMN IF NOT EXISTS `42atlas` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `55atlas`,
ADD COLUMN IF NOT EXISTS `reboot` int(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `authBearer` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `token` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `email` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `rdmUrl` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `onBoot` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `playstore` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `proxyinfo` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL
;

-- Update 2 (aegis)
ALTER TABLE ATVsummary
ADD COLUMN IF NOT EXISTS `MITM` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL
;


-- update version
INSERT IGNORE INTO version values ('atlas_atvdetails',1);
UPDATE version set version = 6 where version.key = 'atlas_atvdetails';
