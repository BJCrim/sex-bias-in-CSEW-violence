* Encoding: UTF-8.
cd "D:\...\Changing violence\data and syntax\19-20".
* open the non-victim form dataset.

GET FILE='csew_apr19mar20_nvf.sav'.
DATASET NAME DataSet2.
DATASET ACTIVATE DataSet2.
COMPUTE SAMPYEAR=2019.
*  get the number of cases by sex.

MEANS TABLES=rowlabel BY sex 
  /CELLS=COUNT.
WEIGHT BY C11IndivWgt.
* get the weighted number of cases by sex -this will be the population values of those in households aged 16 or more. 

MEANS TABLES=rowlabel BY sex 
  /CELLS=COUNT.
WEIGHT OFF.
SORT CASES BY rowlabel.
* now open the victim form dataset.

GET  FILE='csew_apr19mar20_vf.sav'.
DATASET NAME DataSet1.
DATASET ACTIVATE DataSet1.
SORT CASES BY rowlabel.
* and merget them together, keeping only useful values.

MATCH FILES /FILE=*
  /TABLE='DataSet2'
  /BY ROWLABEL
  /KEEP= ROWLABEL SEX AGE SAMPYEAR PINCID BEFOR99 SUSPEND SAMPTYPE YRINCIB WHERHAPP tocrfc_vf  VINTRO OFFENCE NSERIES NUMINC NUMBER NUMBER_UNCAPPED
             VIOLNR_VFNOCAP ALLASSAU_VF  VIOLNR_VF VIOLGRP  VIOLGRPNR  tocrfc_vf  tocrfc_vfnocap OFFREL4 OFFREL4A to OFFREL4R KNEWOFF1 SEENOFF1 
             KNEWOFF SEENOFF NUMOFF C11INDIVWGT C11WEIGHTI  WEIGHTI_UNCAP mthinc2 monthid.
EXECUTE.
DATASET CLOSE Dataset2.
FILTER OFF.
USE ALL.
SELECT IF (offence =11 or offence =12 or offence =13 or offence =21 or offence =32 or offence =33).
RECODE OFFENCE (11,32=1)(12,33=2)(13=3)(21=4) INTO VIOLTYPE.
VALUE LABELS VIOLTYPE 1 'Serious Wounding' 2 'Other Wounding' 3 'Common Assault' 4 'Attempted Assault'.

Compute VICT=NUMBER GT 0.
COMPUTE NUMINC=NUMBER.
IF(NUMBER>5) NUMINC=5. 
FORMATS VICT VIOLTYPE (F5.0).
EXECUTE.
SAVE OUTFILE='CSEW_19_20_VIOL.sav'/COMPRESSED.
* this is still DataSet1

* total number of crime events by sex
    
MEANS TABLES=rowlabel BY sex 
  /CELLS=COUNT.

* weighted number of incidents by sex  below (victims, capped at 5, capped at 98th percentile, uncapped)

WEIGHT BY C11IndivWgt.
MEANS TABLES numinc number number_uncapped BY sex
  /CELLS=SUM.
* weighted number of incidents by relationship (capped at 5, capped at 98th percentile, uncapped).

MEANS TABLES= numinc number number_uncapped BY violgrpnr
  /CELLS=SUM.
* weighted number of incidents by sex and relationship (capped at 5, capped at 98th percentile, uncapped).

MEANS TABLES=numinc number number_uncapped BY sex BY violgrpnr
  /CELLS=SUM.

MEANS TABLES=numinc number number_uncapped BY sex  BY VIOLTYPE
  /CELLS=SUM.

MEANS TABLES=numinc number number_uncapped BY sex BY violgrpnr BY VIOLTYPE
  /CELLS=SUM.
 
DATASET DECLARE datasetagg1.
SORT CASES BY rowlabel sex violgrpnr.
AGGREGATE
  /OUTFILE='datasetagg1'
  /PRESORTED
  /BREAK=rowlabel sex violgrpnr
    /VICT_max=MAX(VICT) / C11IndivWgtAGG1=MAX (C11IndivWgt)/.
DATASET ACTIVATE datasetagg1.
WEIGHT BY C11IndivWgtAGG1.
MEANS TABLES=VICT_max  BY sex  BY violgrpnr
  /CELLS=SUM.
DATASET CLOSE datasetagg1.

DATASET activate dataset1.
DATASET DECLARE datasetagg2.
SORT CASES BY rowlabel  sex violtype.
AGGREGATE
  /OUTFILE='datasetagg2'
  /PRESORTED
  /BREAK=rowlabel sex violtype
    /VICT_max = MAX(VICT) / C11IndivWgtAGG2=MAX (C11IndivWgt)/.
DATASET ACTIVATE datasetagg2.
WEIGHT BY C11IndivWgtAGG2.
MEANS TABLES=VICT_max    BY SEX BY violtype
  /CELLS=SUM.
DATASET CLOSE datasetagg2.

DATASET activate dataset1.
DATASET DECLARE datasetagg3.
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

