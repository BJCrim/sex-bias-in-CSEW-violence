Set the working directory, which will contain the data files for 2019/20
```
cd "C:\Users\meshuser\Dropbox\Changing violence\data and syntax\19-20".
```
Open the non-victim form dataset. This file has one line of data for each respondent. SPSS refers to this file as DataSet2.
```
GET FILE='csew_apr19mar20_nvf.sav'.
DATASET NAME DataSet2.
DATASET ACTIVATE DataSet2.
COMPUTE SAMPYEAR=2019.
```
Get the number of cases by sex.
```
MEANS TABLES=rowlabel BY sex 
  /CELLS=COUNT.
WEIGHT BY C11IndivWgt.
```
Get the weighted number of cases by sex -this will be the population values of those in households aged 16 or more.

```
MEANS TABLES=rowlabel BY sex 
  /CELLS=COUNT.
WEIGHT OFF.
```

|Sex|N|
|---|---|
|Male|15505|
|Female|18229|
|Total|33734|

Now make sure the data set is in the correct order.
```
SORT CASES BY rowlabel.
```
Now open the victim form dataset. This file has multiple lines of data for each respondent - one for each crime report. 
If the repondent is a non-victim, then then there are no records.
```
GET  FILE='csew_apr19mar20_vf.sav'.
DATASET NAME DataSet1.
DATASET ACTIVATE DataSet1.
```
And make sure that this file is also sorted in the same order as Dataset2.
```
SORT CASES BY rowlabel.
```
Now merge them together, keeping only useful variables.
```
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
```
The active file is now Dataset1.

We now want to make a new variable **VIOLTYPE** specifyting the type and severity  of the violent crime event. We also renove from the active file records where there is no violent act. 
```
SELECT IF (offence =11 or offence =12 or offence =13 or offence =21 or offence =32 or offence =33).
RECODE OFFENCE (11,32=1)(12,33=2)(13=3)(21=4) INTO VIOLTYPE.
VALUE LABELS VIOLTYPE 1 'Serious Wounding' 2 'Other Wounding' 3 'Common Assault' 4 'Attempted Assault'.
```
Now we construct some new variables.  **NUMBER_UNCAPPED** is the uncapped crime counts per crime event. **NUMBER** is the ONS variable for violent crime counts capped at the 98th percentile, and **NUMINC** is the variable for crime counts capped at 5.  We save this data file for future use.
```
COMPUTE NUMINC=NUMBER.
IF(NUMBER>5) NUMINC=5. 
FORMATS  VIOLTYPE (F5.0).
EXECUTE.
SAVE OUTFILE='CSEW_19_20_VIOL.sav'/COMPRESSED.
```
We now produce the estimated number of violent crimes  in the population, by sex for uncapped uncapped and capped at the 98th percentile and at 5. weighted number of incidents by sex  below (capped at 5, capped at 98th percentile, uncapped).
```
WEIGHT BY C11IndivWgt.
MEANS TABLES= numinc number number_uncapped BY sex
  /CELLS=SUM.
``` 
Now the  weighted number of incidents by relationship (capped at 5, capped at 98th percentile, uncapped). Relationship is stored in an ONS variable called **VIOLGRPNR**. 
```
MEANS TABLES= numinc number number_uncapped BY violgrpnr
  /CELLS=SUM.
```
Finally the weighted number of incidents by sex and relationship (capped at 5, capped at 98th percentile, uncapped).
```
MEANS TABLES= numinc number number_uncapped BY sex BY violgrpnr
  /CELLS=SUM.
```
And the weighted number of incidents by sex and relationship (capped at 5, capped at 98th percentile, uncapped).
```
MEANS TABLES= numinc number number_uncapped BY sex  BY VIOLTYPE
  /CELLS=SUM.

MEANS TABLES= numinc number number_uncapped BY sex BY violgrpnr BY VIOLTYPE
  /CELLS=SUM.
```








