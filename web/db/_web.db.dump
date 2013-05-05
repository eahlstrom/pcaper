PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE `carve` (`id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,`chksum` unsigned integer,`submitted` integer,`finished` integer,`local_file` varchar(255),`params` varchar(255), `worker_state` varchar(255),`worker_msg` varchar(255));
DELETE FROM sqlite_sequence;
INSERT INTO "sqlite_sequence" VALUES('carve',0);
CREATE INDEX `carve_chksum` ON `carve` (`chksum`);
COMMIT;
