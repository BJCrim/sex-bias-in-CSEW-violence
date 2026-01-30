* Encoding: UTF-8.
cd "C:\Users\meshuser\Dropbox\Changing violence\data and syntax\12-13".

GET FILE='csew_apr12mar13_nvf.sav'.
DATASET NAME DataSet2.
DATASET ACTIVATE DataSet2.
COMPUTE SAMPYEAR=2012.
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

GET  FILE='csew_apr12mar13_vf.sav'.
DATASET NAME DataSet1.
DATASET ACTIVATE DataSet1.
SORT CASES BY rowlabel.
* and merget them together, keeping only useful values.

MATCH FILES /FILE=*
  /TABLE='DataSet2'
  /BY ROWLABEL
  /KEEP= ROWLABEL SEX AGE SAMPYEAR PINCID BEFOR99 SUSPEND SAMPTYPE YRINCIB WHERHAPP  VINTRO OFFENCE NSERIES NUMINC NUMBER NUMBER_UNCAPPED
             VIOLNR_VFNOCAP ALLASSAU_VF  VIOLNR_VF VIOLGRP  VIOLGRPNR  OFFREL3 OFFREL3A to OFFREL3Q KNEWOFF1 SEENOFF1 
             KNEWOFF SEENOFF NUMOFF C11INDIVWGT C11WEIGHTI . 
EXECUTE.

DATASET CLOSE Dataset2.
FILTER OFF.
USE ALL.
SELECT IF (offence =11 or offence =12 or offence =13 or offence =21 or offence =32 or offence =33).
RECODE OFFENCE (11,32=1)(12,33=2)(13=3)(21=4) INTO VIOLTYPE.
VARIABLE LABELS VIOLTYPE 'Seriousness of violence'.
VALUE LABELS VIOLTYPE 1 'Serious Wounding' 2 'Other Wounding' 3 'Common Assault' 4 'Attempted Assault'.

Compute VICT=NUMBER GT 0.
VARIABLE LABELS VICT 'Victims'.
COMPUTE NUMINC=NUMBER.
IF(NUMBER>5) NUMINC=5. 
FORMATS VICT VIOLTYPE (F5.0).
EXECUTE.
SAVE OUTFILE='CSEW_12_13_VIOL.sav'/COMPRESSED.
* this is still DataSet1

* total number of crime events by sex
    
MEANS TABLES=rowlabel BY sex 
  /CELLS=COUNT.

* weighted number of incidents by sex  below (victims, capped at 5, capped at 98th percentile, uncapped)

WEIGHT BY C11IndivWgt.
MEANS TABLES=vict numinc number number_uncapped BY sex
  /CELLS=SUM.
* weighted number of incidents by relationship (capped at 5, capped at 98th percentile, uncapped).

MEANS TABLES=vict numinc number number_uncapped BY violgrpnr
  /CELLS=SUM.
* weighted number of incidents by sex and relationship (capped at 5, capped at 98th percentile, uncapped).

MEANS TABLES=vict numinc number number_uncapped BY sex BY violgrpnr
  /CELLS=SUM.

MEANS TABLES=vict numinc number number_uncapped BY sex  BY VIOLTYPE
  /CELLS=SUM.    
 
 WEIGHT OFF.
 MEANS TABLES=vict numinc number number_uncapped BY sex BY VIOLTYPE
  /CELLS=SUM. 

WEIGHT BY C11IndivWgt.
MEANS TABLES=vict numinc number number_uncapped BY sex BY violgrpnr BY VIOLTYPE
  /CELLS=SUM.

 WEIGHT OFF.
  MEANS TABLES=vict numinc number number_uncapped BY sex BY violgrpnr BY VIOLTYPE
  /CELLS=SUM. 

FREQUENCIES NUMBER_UNCAPPED.
CROSSTABS NUMBER NUMBER_UNCAPPED BY SEX.
