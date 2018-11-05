[*VERIFY.REPORT.KEYS                                                                              
** This program will be useful to run when the client improperly                
** deletes report files in aix under a /SYM/SYMXXX/REPORT directory on          
** their system.                                                                
**                                                                              
** This program will read thru the REPORT database KEYS and to see              
** what reports are listed and then it will attempt to actually open            
** each report listed in the KEYS.  If it is not able to successfully           
** open the report then a line will be output.                                  
**                                                                                
*]                                                                              
                                                                                
TARGET=ACCOUNT                                                                  
                                                                                
DEFINE                                                                          
 FLINE=CHARACTER                                                                
 FERROR=CHARACTER                                                               
 FILENAMEFROM=CHARACTER(6)                                                      
 FILEERROR=CHARACTER                                                            
 FILENUMBER=NUMBER                                                              
 BADCNT=NUMBER                                                                  
END                                                                             
                                                                                
SETUP                                                                           
 BADCNT=0                                                                       
 FLINE=""                                                                       
END                                                                             
                                                                                
SELECT                                                                          
 NONE                                                                           
END                                                                             
                                                                                
PRINT TITLE="Verify Report Keys"                                                
 HEADER=""                                                                      
 FILELISTOPEN("REPORT","+",FERROR)                                              
 FILELISTREAD(FLINE,FERROR)                                                     
 WHILE (FERROR="")                                                              
  DO                                                                            
   FILENAMEFROM=SEGMENT(FLINE,110,115)                                          
   FILELISTREAD(FLINE,FERROR)                                                   
   FILEOPEN("REPORT",FILENAMEFROM,"READ",FILENUMBER,FILEERROR)                  
   IF FILEERROR="" THEN                                                         
    FILECLOSE(FILENUMBER,FILEERROR)                                             
   ELSE                                                                         
    DO                                                                          
     COL=1 "Problem opening Report Seq:"+FILENAMEFROM                           
     PRINT "   Report Date: "+SEGMENT(FLINE,62,69)+"        Error:"+FILEERROR        
     NEWLINE                                                                    
     BADCNT=BADCNT+1                                                            
    END                                                                         
  END                                                                           
 FILELISTCLOSE(FERROR)                                                          
END                                                                             
                                                                                
TOTAL                                                                           
 NEWLINE                                                                        
 NEWLINE                                                                        
 COL=1 "========================================="                              
 PRINT "========================================="                              
 NEWLINE                                                                        
 IF BADCNT=0 THEN                                                               
  COL=1  "All Reports listed in the REPORT.KEYS file were found"                
 ELSE                                                                           
  DO                                                                            
   COL=1  "A total of "                                                         
   PRINT BADCNT                                                                 
   PRINT " Report(s) listed in the REPORT.KEYS file were NOT found!"            
   NEWLINE                                                                      
  END                                                                           
END                                                                             
