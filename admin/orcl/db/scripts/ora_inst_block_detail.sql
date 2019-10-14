--
-- ora_inst_block_detail.sql v1.0
--
-- Frequency: XX min
--    Result: n>0 - Warning
--   Message: Detailed information about blocking session(s)
--   History:
-- * v1.0 - Created by D.Nepochitoj

SELECT
  S.KSUUDLNA USERNAME
, S.KSUSEUNM OSUSER
, S.KSUSEMNM MACHINE
, S.KSUSEPNM PROGRAM
, TO_CHAR(S.KSUSELTM,'MM/DD/YYYY HH24:MI:SS') LOGON_TIME
, FLOOR(S.KSUSEWTM/3600)||':'||FLOOR(MOD(S.KSUSEWTM,3600)/60)||':'||MOD(MOD(S.KSUSEWTM,3600),60) SECONDS_IN_WAIT
, S.KSUSEACT ACTION
, S.KSUSEAPP MODULE
, DECODE(BITAND(S.KSUSEIDL, 11),
              1, 'ACTIVE',
              0, DECODE(BITAND(S.KSUSEFLG, 4096), 0, 'INACTIVE', 'CACHED'),
              2, 'SNIPED',
              3, 'SNIPED',
                 'KILLED') STATUS
, S.INDX SID
, S.KSUSESER SERIAL#
, E.KSLEDNAM EVENT
, L.BLOCK
  FROM X$KSUSE S
     , X$KSLED E
     , V$_LOCK L
 WHERE BITAND(S.KSSPAFLG, 1) != 0
  AND BITAND(S.KSUSEFLG, 1) != 0
  AND S.KSUSEOPC = E.INDX
  AND L.SADDR=S.ADDR
--AND S.INDX IN  1350         -- TEST SESSION
  -- check if query exceeds time limit (default 600 sec)
  AND S.KSUSEWTM >
    NVL
    (
      (
          SELECT MAX(V1) FROM JETDBA.MON_THRESHOLDS WHERE
          (
              INST_ID=0 OR INST_ID=(SELECT INSTANCE_NUMBER FROM V$INSTANCE)
          )
          AND STATNAME='INST_BLOCK'
      ) , 600
    )
  -- check if wait event is in exclude list
  AND E.KSLEDNAM NOT IN       -- AND EVENT NOT IN
  (
      SELECT NAME FROM JETDBA.MON_EXCLUDE WHERE STATNAME='INST_BLOCK'
  )
  -- check if the lock is blocking another lock
  AND L.BLOCK = 1
/

-- Sample output:
--     USERNAME  OSUSER  MACHINE     PROGRAM                         LOGON_TIME          SECONDS_IN_WAIT ACTION  MODULE                          STATUS    SID   SERIAL# EVENT                       BLOCK
-- 1   SYS       oracle  p780-2-lp05 sqlplus@p780-2-lp05 (TNS V1-V3) 10/14/2019 20:53:52 0:0:4                   sqlplus@p780-2-lp05 (TNS V1-V3) INACTIVE  1350  55755   SQL*Net message from client 0
