* Encoding: UTF-8.
cd "C:\Users\meshuser\Dropbox\Changing violence\data and syntax\03-04".

GET FILE='bcsnvf20034toesrc.sav'.
DATASET NAME DataSetnvf.
SORT CASES BY ROWLABEL.

COMPUTE SAMPYEAR=2003.
*  get the number of cases by sex.

GET FILE = 'csew_apr03mar04_nvf.sav' 
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

GET  FILE='bcsvictimform20034toesrc.sav' .
    
DATASET NAME DataSetvf.
SORT CASES BY match.
* and merget them together, keeping only useful values.

GET FILE 'csew_apr03mar04_vf.sav'.
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
             OFFREL2 OFFREL2A to OFFREL2p KNEWOFF1 SEENOFF1 
             KNEWOFF SEENOFF NUMOFF INDIVWGT   C11IndivWgt . 
EXECUTE.
DATASET NAME DataSetviol.
DATASET ACTIVATE DataSetviol.


FILTER OFF.
USE ALL.
COMPUTE VIOLGRP=$SYSMIS.
IF (OFFREL2 le 7)violgrp=1.
IF(OFFREL2 GT 7 AND OFFREL2 LT 15) VIOLGRP=2. 
IF(MISSING (OFFREL2) AND (OFFREL2A =1 OR OFFREL2B=1 OR OFFREL2C=1 OR OFFREL2D=1 or OFFREL2E=1 OR OFFREL2F=1
    OR OFFREL2G=1)) VIOLGRP=1.
EXECUTE.
IF (MISSING(VIOLGRP)AND (OFFREL2A =0 AND  OFFREL2B=0 AND OFFREL2C=0 AND OFFREL2D=0 AND OFFREL2E=0 AND OFFREL2F=0
    AND OFFREL2G=0) AND (OFFREL2H=1 OR    OFFREL2I=1    OR OFFREL2J=1   OR OFFREL2K=1   OR OFFREL2L=1  OR OFFREL2M=1 
    OR OFFREL2N=1)) VIOLGRP=2. 
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
* For 2003/4 this is  9.
COMPUTE CAP= 9.
COMPUTE NUMBER = NUMBER_UNCAPPED.
IF (NUMBER> CAP) NUMBER =CAP. 
* NUMBER is number of incidents with new cap.
*.
COMPUTE VICT=NUMBER GT 0.
VARIABLE LABELS VICT 'Victims' NUMBER 'Incidents capped at new cap' NUMBER_UNCAPPED ' number of uncapped incidents'. 

FORMATS VICT VIOLTYPE NUMBER NUMINC  NUMBER_UNCAPPED(F5.0).
EXECUTE.
SAVE OUTFILE='CSEW_03_04_VIOL.sav'/COMPRESSED.


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

