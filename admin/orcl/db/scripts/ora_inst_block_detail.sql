--
-- ora_inst_block_detail.sql v1.0
--
-- Formatted by SQLFormat.org (https://sqlformat.org)
--
-- Frequency: XX min
--    Result: n>0 - Warning
--   Message: Detailed information about blocking session(s)
--   History:
-- * v1.0 - Created by D.Nepochitoj

SELECT s.ksuudlna username,
       s.ksuseunm osuser,
       s.ksusemnm machine,
       s.ksusepnm program,
       to_char(s.ksuseltm, 'MM/DD/YYYY HH24:MI:SS') logon_time,
       floor(s.ksusewtm/3600)||':'||floor(mod(s.ksusewtm, 3600)/60)||':'||mod(mod(s.ksusewtm, 3600), 60) seconds_in_wait,
       s.ksuseact action,
       s.ksuseapp MODULE,
                  decode(bitand(s.ksuseidl, 11), 1, 'ACTIVE', 0, decode(bitand(s.ksuseflg, 4096), 0, 'INACTIVE', 'CACHED'), 2, 'SNIPED', 3, 'SNIPED', 'KILLED') status,
                  s.indx sid,
                  s.ksuseser serial#,
                  e.kslednam event,
                  l.block
FROM x$ksuse s ,
     x$ksled e ,
     v$_lock l
WHERE bitand(s.ksspaflg, 1) != 0
  AND bitand(s.ksuseflg, 1) != 0
  AND s.ksuseopc = e.indx
  AND l.saddr=s.addr 
--AND S.INDX IN  1350         -- TEST SESSION
  -- check if query exceeds time limit (default 600 sec)
  AND s.ksusewtm > nvl (
                          (SELECT max(v1)
                           FROM jetdba.mon_thresholds
                           WHERE (inst_id=0
                                  OR inst_id=
                                    (SELECT instance_number
                                     FROM v$instance))
                             AND statname='INST_BLOCK' ) , 600) 
  -- check if wait event is in exclude list
  AND e.kslednam NOT IN -- AND EVENT NOT IN
    (SELECT name
     FROM jetdba.mon_exclude
     WHERE statname='INST_BLOCK' )
  -- check if the lock is blocking another lock
  AND l.block = 1; 

-- Sample output:
--     USERNAME  OSUSER  MACHINE     PROGRAM                         LOGON_TIME          SECONDS_IN_WAIT ACTION  MODULE                          STATUS    SID   SERIAL# EVENT                       BLOCK
-- 1   SYS       oracle  p780-2-lp05 sqlplus@p780-2-lp05 (TNS V1-V3) 10/14/2019 20:53:52 0:0:4                   sqlplus@p780-2-lp05 (TNS V1-V3) INACTIVE  1350  55755   SQL*Net message from client 0
