* Encoding: UTF-8.
cd "D:\...\Changing violence\data and syntax\08-09".

GET FILE='bcs_apr08mar09_nvf.sav'.
DATASET NAME DataSetnvf.
SORT CASES BY ROWLABEL.

COMPUTE SAMPYEAR=2008.
*  get the number of cases by sex.

GET FILE = 'csew_apr08mar09_nvf.sav' 
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

GET  FILE='bcs_apr08mar09_vf.sav' .
    
DATASET NAME DataSetvf.
SORT CASES BY match.
* and merget them together, keeping only useful values.

GET FILE 'csew_apr08mar09_vf.sav'.
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
                VIOLGRP   OFFREL3 OFFREL3A to OFFREL3Q KNEWOFF1 SEENOFF1 
             KNEWOFF SEENOFF NUMOFF INDIVWGT   C11IndivWgt . 
EXECUTE.
DATASET NAME DataSetviol.
DATASET ACTIVATE DataSetviol.


FILTER OFF.
USE ALL.
SELECT IF (offence =11 or offence =12 or offence =13 or offence =21 or offence =32 or offence =33).
RECODE OFFENCE (11,32=1)(12,33=2)(13=3)(21=4) INTO VIOLTYPE.
VARIABLE LABELS VIOLTYPE 'Seriousness of violence'.
VALUE LABELS VIOLTYPE 1 'Serious Wounding' 2 'Other Wounding' 3 'Common Assault' 4 'Attempted Assault'.
*===================================================================================
* NUMINC is capped at 5.
* First create NUMBER_UNCAPPED from NSERIES.
COMPUTE NUMBER_UNCAPPED =NSERIES.
IF(NSERIES=0) NUMBER_UNCAPPED= 1.
IF(NSERIES =998) NUMBER_UNCAPPED=2.
*
 *get appropriate 98th percentile cap from excel table. 
*
* For 2008/9 this is  8.
COMPUTE CAP= 8.
COMPUTE NUMBER = NUMBER_UNCAPPED.
IF (NUMBER> CAP) NUMBER =CAP. 
* NUMBER is number of incidents with new cap.
*.
COMPUTE VICT=NUMBER GT 0.
VARIABLE LABELS NUMBER 'Incidents capped at new cap' NUMBER_UNCAPPED ' number of uncapped incidents'. 

FORMATS VICT VIOLTYPE NUMBER NUMINC  NUMBER_UNCAPPED(F5.0).
EXECUTE.
SAVE OUTFILE='CSEW_08_09_VIOL.sav'/COMPRESSED.


* total number of crime events by sex
    
MEANS TABLES=rowlabel BY sex 
  /CELLS=COUNT.

* weighted number of incidents by sex  below (victims, capped at 5, capped at 98th percentile, uncapped)

WEIGHT BY C11IndivWgt.
MEANS TABLES=numinc number number_uncapped BY sex
  /CELLS=SUM.
* weighted number of incidents by relationship (capped at 5, capped at 98th percentile, uncapped).

MEANS TABLES=numinc number number_uncapped BY violgrp
  /CELLS=SUM.
* weighted number of incidents by sex and relationship (capped at 5, capped at 98th percentile, uncapped).

MEANS TABLES=numinc number number_uncapped BY sex BY violgrp
  /CELLS=SUM.

MEANS TABLES=numinc number number_uncapped BY sex  BY VIOLTYPE
  /CELLS=SUM.
 
MEANS TABLES=numinc number number_uncapped BY sex BY violgrp BY VIOLTYPE
  /CELLS=SUM.

DATASET NAME datasetcombined.

    SORT CASES BY rowlabel sex violgrp.
    DATASET DECLARE datasetagg1.
      AGGREGATE
      /OUTFILE='datasetagg1'
      /PRESORTED
      /BREAK=rowlabel sex violgrp
        /VICT_max=MAX(VICT) / C11IndivWgtAGG1=MAX (C11IndivWgt)/.
    EXECUTE.
    DATASET ACTIVATE datasetagg1.
    WEIGHT BY C11IndivWgtAGG1.
    MEANS TABLES=VICT_max  BY sex  BY violgrp
      /CELLS=SUM.
    DATASET CLOSE datasetagg1.
    
    DATASET activate datasetcombined.
     DATASET DECLARE datasetagg2.
    SORT CASES BY rowlabel  sex violtype.
    AGGREGATE
      /OUTFILE='datasetagg2'
      /PRESORTED
      /BREAK=rowlabel sex violtype
        /VICT_max = MAX(VICT) / C11IndivWgtAGG2=MAX (C11IndivWgt)/.
   EXECUTE.
     DATASET ACTIVATE datasetagg2.
    WEIGHT BY C11IndivWgtAGG2.
    MEANS TABLES=VICT_max    BY SEX BY violtype
      /CELLS=SUM.
    DATASET CLOSE datasetagg2.
    
     DATASET DECLARE datasetagg3.
     DATASET activate datasetcombined.
    SORT CASES BY rowlabel  sex.
    AGGREGATE
      /OUTFILE='datasetagg3'
      /PRESORTED
      /BREAK=rowlabel sex
        /VICT_max = MAX(VICT) / C11IndivWgtAGG3=MAX (C11IndivWgt)/.
    DATASET ACTIVATE datasetagg3.
    WEIGHT BY C11IndivWgtAGG3.
    MEANS TABLES=VICT_max    BY sex
      /CELLS=SUM.
    DATASET CLOSE datasetagg3.





