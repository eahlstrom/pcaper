PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
INSERT INTO "carve" VALUES(1,431182551,1401910599,NULL,'__PCAPER_HOME__/test/fixtures/tmp/webcarve/431182551.pcap','{"start_time":"2013-12-01 11:15:26 +0100","src":"192.168.0.1","sport":"35594","dst":"192.168.0.2","dport":"22","proto":"tcp"}','done',NULL);
DELETE FROM sqlite_sequence;
INSERT INTO "sqlite_sequence" VALUES('carve',1);
COMMIT;
