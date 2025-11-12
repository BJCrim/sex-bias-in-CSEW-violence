* Encoding: UTF-8.
cd "C:\Users\meshuser\Dropbox\Changing violence\data and syntax\01-02".

GET FILE='bcs_apr01mar02_nvf.sav'.
DATASET NAME DataSetnvf.
SORT CASES BY ROWLABEL.

COMPUTE SAMPYEAR=2001.
*  get the number of cases by sex.

GET FILE = 'csew_apr01mar02_nvf.sav' 
    /KEEP ROWLABEL C11IndivWgt.
DATASET NAME DataSetnvfaddon.
SORT CASES BY ROWLABEL.

MATCH FILES 
 /FILE='Datasetnvf'
 /TABLE='DataSetnvfaddon'
 /BY ROWLABEL.
DATASET NAME DATASETnvfall.

DATASET CLOSE DataSetnvf.
DATASET CLOSE DataSetnvfaddon.


MEANS TABLES=rowlabel BY sex 
  /CELLS=COUNT.
WEIGHT BY C11IndivWgt.
* get the weighted number of cases by sex -this will be the population values of those in households aged 16 or more. 

MEANS TABLES=rowlabel BY sex 
  /CELLS=COUNT.
WEIGHT OFF.
SORT CASES BY rowlabel.


* now open the victim form dataset.
*==================================================================================================

GET  FILE='bcs_apr01mar02_vf.sav' .
    
DATASET NAME DataSetvf.
SORT CASES BY match.
* and merget them together, keeping only useful values.

GET FILE 'csew_apr01mar02_vf.sav'.
DATASET NAME DataSetvfaddon.
SORT CASES BY match.

MATCH FILES /FILE='Datasetvf'
 /TABLE='DataSetvfaddon'
 /BY MATCH.
DATASET NAME DataSetvfall.

DATASET CLOSE DataSetvf.
DATASET CLOSE DataSetvfaddon.

MATCH FILES /FILE='DataSetvfall'
  /TABLE='DataSetnvfall'
  /BY ROWLABEL
  /KEEP= ROWLABEL SEX AGE SAMPYEAR PINCID BEFOR99 SUSPEND SAMPTYPE YRINCIB WHERHAPP  VINTRO OFFENCE NSERIES NUMINC  
             OFFREL1 OFFRELA to OFFRELm KNEWOFF1 SEENOFF1 
             KNEWOFF SEENOFF NUMOFF INDIVWGT   C11IndivWgt . 
EXECUTE.
DATASET NAME DataSetviol.
DATASET ACTIVATE DataSetviol.


FILTER OFF.
USE ALL.
COMPUTE VIOLGRP=$SYSMIS.
IF (OFFREL1 le 7)violgrp=1.
IF(OFFREL1 GT 7 AND OFFREL1 LT 14) VIOLGRP=2. 
IF(MISSING (OFFREL1) AND (OFFRELA =1 OR OFFRELB=1 OR OFFRELC=1 OR OFFRELD=1 or OFFRELE=1 OR OFFRELF=1
    OR OFFRELG=1)) VIOLGRP=1.
EXECUTE.
IF (MISSING(VIOLGRP)AND (OFFRELA =0 AND  OFFRELB=0 AND OFFRELC=0 AND OFFRELD=0 AND OFFRELE=0 AND OFFRELF=0
    AND OFFRELG=0) AND (OFFRELH=1 OR    OFFRELI=1    OR OFFRELJ=1   OR OFFRELK=1   OR OFFRELL=1  OR OFFRELM=1 
    )) VIOLGRP=2. 
EXECUTE.
IF (missing(VIOLGRP) AND KNEWOFF LE 2) VIOLGRP=2.
IF(MISSING(VIOLGRP) AND SEENOFF =1) VIOLGRP=2.
IF(MISSING(VIOLGRP) AND SEENOFF=2 AND KNEWOFF=3) VIOLGRP=3.
EXECUTE.
IF(MISSING(VIOLGRP) AND (KNEWOFF1 EQ 1 OR SEENOFF1 =1)) VIOLGRP=2.
IF(KNEWOFF1 eq 2 AND SEENOFF1 =2) VIOLGRP=3. 

SELECT IF (offence =11 or offence =12 or offence =13 or offence =21 or offence =32 or offence =33).
RECODE OFFENCE (11,32=1)(12,33=2)(13=3)(21=4) INTO VIOLTYPE.
VARIABLE LABELS VIOLTYPE 'Seriousness of violence'.
VALUE LABELS VIOLTYPE 1 'Serious Wounding' 2 'Other Wounding' 3 'Common Assault' 4 'Attempted Assault'
                          / VIOLGRP 1 'Domestic' 2 'Acquaintance' 3 'Stranger'.  
*===================================================================================
* NUMINC is capped at 5.
* First create NUMBER_UNCAPPED from NSERIES.
COMPUTE NUMBER_UNCAPPED =NSERIES.
IF(NSERIES=0) NUMBER_UNCAPPED= 1.
IF(NSERIES =998) NUMBER_UNCAPPED=2.
*
 *get appropriate 98th percentile cap from excel table. 
*
* For 2001/2 this is  10

COMPUTE CAP=10.
COMPUTE NUMBER = NUMBER_UNCAPPED.
IF (NUMBER> CAP) NUMBER =CAP. 
* NUMBER is number of incidents with new cap.
*.
COMPUTE VICT=NUMBER GT 0.
VARIABLE LABELS VICT 'Victims' NUMBER 'Incidents capped at new cap' NUMBER_UNCAPPED ' number of uncapped incidents'. 

FORMATS VICT VIOLTYPE NUMBER NUMINC  NUMBER_UNCAPPED(F5.0).
EXECUTE.
SAVE OUTFILE='CSEW_01_02_VIOL.sav'/COMPRESSED.


* total number of crime events by sex
    
MEANS TABLES=rowlabel BY sex 
  /CELLS=COUNT.

* weighted number of incidents by sex  below (victims, capped at 5, capped at 98th percentile, uncapped)

WEIGHT BY C11IndivWgt.
MEANS TABLES=vict numinc number number_uncapped BY sex
  /CELLS=SUM.
* weighted number of incidents by relationship (capped at 5, capped at 98th percentile, uncapped).

MEANS TABLES=vict numinc number number_uncapped BY violgrp
  /CELLS=SUM.
* weighted number of incidents by sex and relationship (capped at 5, capped at 98th percentile, uncapped).

MEANS TABLES=vict numinc number number_uncapped BY sex BY violgrp
  /CELLS=SUM.

MEANS TABLES=vict numinc number number_uncapped BY sex  BY VIOLTYPE
  /CELLS=SUM.
 
 WEIGHT OFF.
 MEANS TABLES=vict numinc number number_uncapped BY sex BY VIOLTYPE
  /CELLS=SUM. 

WEIGHT BY C11IndivWgt.
MEANS TABLES=vict numinc number number_uncapped BY sex BY violgrp BY VIOLTYPE
  /CELLS=SUM.

 WEIGHT OFF.
  MEANS TABLES=vict numinc number number_uncapped BY sex BY violgrp BY VIOLTYPE
  /CELLS=SUM. 

FREQUENCIES NUMBER_UNCAPPED.
CROSSTABS NUMBER_UNCAPPED  NUMBER BY SEX.

