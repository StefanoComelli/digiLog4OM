--
-- File generated with SQLiteStudio v3.1.1 on gio ago 10 22:54:24 2017
--
-- Text encoding used: System
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Table: tblAudioBand
DROP TABLE IF EXISTS tblAudioBand;

CREATE TABLE tblAudioBand (
    band      CHAR (5) PRIMARY KEY,
    startFreq INTEGER,
    endFreq   INTEGER,
    maxLevel  INTEGER,
    defLevel  INTEGER,
    defFreq   INTEGER
);

INSERT INTO tblAudioBand (
                             band,
                             startFreq,
                             endFreq,
                             maxLevel,
                             defLevel,
                             defFreq
                         )
                         VALUES (
                             '80m',
                             3500,
                             3800,
                             35,
                             15,
                             3580
                         );

INSERT INTO tblAudioBand (
                             band,
                             startFreq,
                             endFreq,
                             maxLevel,
                             defLevel,
                             defFreq
                         )
                         VALUES (
                             '160m',
                             1830,
                             1850,
                             35,
                             25,
                             1838
                         );

INSERT INTO tblAudioBand (
                             band,
                             startFreq,
                             endFreq,
                             maxLevel,
                             defLevel,
                             defFreq
                         )
                         VALUES (
                             '40m',
                             7000,
                             7200,
                             35,
                             15,
                             7040
                         );

INSERT INTO tblAudioBand (
                             band,
                             startFreq,
                             endFreq,
                             maxLevel,
                             defLevel,
                             defFreq
                         )
                         VALUES (
                             '30m',
                             10100,
                             10150,
                             35,
                             25,
                             10140
                         );

INSERT INTO tblAudioBand (
                             band,
                             startFreq,
                             endFreq,
                             maxLevel,
                             defLevel,
                             defFreq
                         )
                         VALUES (
                             '15m',
                             21000,
                             21450,
                             35,
                             15,
                             21070
                         );

INSERT INTO tblAudioBand (
                             band,
                             startFreq,
                             endFreq,
                             maxLevel,
                             defLevel,
                             defFreq
                         )
                         VALUES (
                             '12m',
                             24890,
                             24990,
                             35,
                             25,
                             24919
                         );

INSERT INTO tblAudioBand (
                             band,
                             startFreq,
                             endFreq,
                             maxLevel,
                             defLevel,
                             defFreq
                         )
                         VALUES (
                             '10m',
                             28000,
                             29700,
                             35,
                             25,
                             28120
                         );

INSERT INTO tblAudioBand (
                             band,
                             startFreq,
                             endFreq,
                             maxLevel,
                             defLevel,
                             defFreq
                         )
                         VALUES (
                             '6m',
                             50000,
                             52000,
                             20,
                             9,
                             50250
                         );

INSERT INTO tblAudioBand (
                             band,
                             startFreq,
                             endFreq,
                             maxLevel,
                             defLevel,
                             defFreq
                         )
                         VALUES (
                             '2m',
                             144000,
                             146000,
                             35,
                             25,
                             144000
                         );

INSERT INTO tblAudioBand (
                             band,
                             startFreq,
                             endFreq,
                             maxLevel,
                             defLevel,
                             defFreq
                         )
                         VALUES (
                             '70cm',
                             430000,
                             438000,
                             35,
                             25,
                             432000
                         );

INSERT INTO tblAudioBand (
                             band,
                             startFreq,
                             endFreq,
                             maxLevel,
                             defLevel,
                             defFreq
                         )
                         VALUES (
                             '17m',
                             18068,
                             18168,
                             35,
                             25,
                             18100
                         );

INSERT INTO tblAudioBand (
                             band,
                             startFreq,
                             endFreq,
                             maxLevel,
                             defLevel,
                             defFreq
                         )
                         VALUES (
                             '20m',
                             14000,
                             14350,
                             24,
                             14,
                             14070
                         );


-- Index: idxBand
DROP INDEX IF EXISTS idxBand;

CREATE UNIQUE INDEX idxBand ON tblAudioBand (
    band ASC
);


-- Index: idxEnd
DROP INDEX IF EXISTS idxEnd;

CREATE UNIQUE INDEX idxEnd ON tblAudioBand (
    endFreq ASC
);


-- Index: idxStart
DROP INDEX IF EXISTS idxStart;

CREATE UNIQUE INDEX idxStart ON tblAudioBand (
    startFreq ASC
);


COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
