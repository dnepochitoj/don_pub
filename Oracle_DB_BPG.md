# Best Practice Guide (BPG): Oracle DB Checklist

**Mandatory:**

* Name convention for mountpoints:
  * /orcl/bin  (from datastore)
  * /orcl/data (if <2TB - from datastore, if >2TB - from RDM)
  * /orcl/arch (from datastore)
* Filesystems block size:
  * data - 8/16KB (depends on db_block_size)
  * redo/arch - 512B
* Memory settings:
  * SGA:
    * SGA_TARGET | (DB_CACHE_SIZE, SHARED_POOL_SIZE, LARGE_POOL_SIZE, JAVA_POOL_SIZE)
     * Shared Pool Advisor
     * Buffer Cache Advisor 
    * DB_KEEP_CACHE_SIZE, DB_RECYCLE_CACHE_SIZE
    * DB_nK_CACHE_SIZE (n = 2, 4, 8, 16, 32)
    * LOG_BUFFER
    * STREAMS_POOL_SIZE
  * PGA:
    * v$pga_target_advice
      * pga_aggregate_target
      * (if >12.1) pga_aggregate_limit
* implement Huge pages for SGA
  * set vm.nr_hugepages in /etc/sysctl.conf
  * set memlock in /etc/security/limits.conf
  * (if Linux) use_large_pages = ONLY
  * (if AIX) lock_sga = TRUE
  * ALERT: Disable Transparent HugePages on SLES11, RHEL6, RHEL7, OL6, OL7 and UEK2 Kernels (Doc ID 1557478.1)
     * grep AnonHugePages /proc/meminfo
* set FILESYSTEMIO_OPTIONS=SETALL (async io + directIO)
* implement RMAN incremental backups 
   * enable Block Change tracking file (before first Level 0 backup)
* enable Spfile
* decrease Swapiness to 1
* update /etc/oratab
* create Global Oracle inventory
* check opatch lsinventory
* Clean up huge traces, alertlog (adrci)
  * adrci
  * set homepath  .... 
  * show control
  * set control ### for a month

**Optional:**

* (before Standby's creation) enable force logging on primary
* (if Test/Dev) disable archivelog mode
* setup Oracle-Managed Files (OMF)
* Flash Recovery Area (FRA)
