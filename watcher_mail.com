$ WATCHER_MAIL$VERSION = "1.00"
$ VERIFY = F$VERIFY("''DEBUG'")
$! WATCHER_MAIL.COM 
$!
$! ABSTRACT:        Notify users, via mail or a report, that they were 
$!                  terminated by WATCHER.
$!
$!    Read the file pointed to by WATCHER_LOG (or WATCHER_DIR:WATCHER.LOG if
$!    the logical isn't defined) and get all the entries since the date 
$!    passed as P1.  This program (WATHCER_MAIL.COM) works with WATCHER 
$!    versions V2.6-2 and V2.7.
$!
$!!!!!!
$!
$! Parameters:
$!     P1 - [optional] - users killed after this date/time will be mailed
$!                       a message.  If this is null, it defaults to 
$!                       yesterday (the implied operation of this job is
$!                       it being run after midnight every night as part of
$!                       other system management duties).
$!                       P1 should be in the format:
$!                       DD-MMM-YYYY HH:MM:SS.CC
$!     P2 - [optional] - PRINT, MAIL, or BOTH.
$!                       If specified, you will not be prompted for the
$!                       action to be taken.  Use this option when running
$!                       WATCHER_MAIL in batch to either print a report, or 
$!                       mail to all users.
$!     P3 - [optional] - Username to CC on all mail messages.  This can
$!                       be a list of usernames separated by commas, or a
$!                       distribution list.
$!     P4 - [optional] - Queue name for print reports.  If not specified,
$!                       SYS$PRINT is used.
$!
$!!!!!!
$!
$! AUTHOR:     Dan Wing
$!             University Hospital
$!             5250 Leetsdale Dr., #206
$!             Denver, CO  80222
$!             303-355-7040
$!             dwing@uh01.colorado.edu
$!
$!
$! CREATION DATE:  September 14, 1992
$!
$! MODIFICATION HISTORY:
$!   14-SEP-1992  V1.00   Wing        Created WATCHER_MAIL. (Dan Wing)
$!
$!
$!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
$
$  ON WARNING THEN GOTO _ERROR
$  ON CONTROL_Y THEN GOTO _ABORT
$
$  SET SYMBOL/SCOPE=noGLOBAL
$
$  WRITE SYS$OUTPUT ""
$  WRITE SYS$OUTPUT "WATCHER MAIL, version ", WATCHER_MAIL$VERSION
$  WRITE SYS$OUTPUT ""
$
$  UNIQUE = F$GETJPI(0,"PID") + "_" + F$CVTIME(,,"HOUR") + F$CVTIME(,,"MINUTE") + F$CVTIME(,,"SECOND")
$
$  TEMPFILE_LOG     = "SYS$SCRATCH:WATCHER_MAIL1_" + UNIQUE + ".TMP"
$  TEMPFILE_NOTICE  = "SYS$SCRATCH:WATCHER_MAIL2_" + UNIQUE + ".TMP"
$  TEMPFILE_PRINT   = "SYS$SCRATCH:WATCHER_MAIL3_" + UNIQUE + ".TMP"
$  TEMPFILE_MAIL    = "SYS$SCRATCH:WATCHER_MAIL4_" + UNIQUE + ".TMP"
$  REPORT_FILE      = "SYS$SCRATCH:WATCHER_MAIL.RPT"
$
$  IF P1 .EQS. "?" THEN GOTO _HELP
$
$  CC_USER = ""
$
$  IF P1 .EQS. "" 
$  THEN 
$    P1 = F$CVTIME("YESTERDAY","ABSOLUTE")
$  ELSE
$    P1 = F$CVTIME(P1,"ABSOLUTE")
$  ENDIF
$
$  IF P2 .NES. "" .AND. P2 .NES. "PRINT" .AND. P2 .NES. "MAIL" .AND. P2 .NES. "BOTH"
$  THEN
$    WRITE SYS$OUTPUT "%WATCHER_MAIL, Invalid parameter P2"
$    GOTO _EXIT
$  ENDIF
$
$  IF P2 .NES. ""
$  THEN
$    UNATTENDED = 1
$    WRITE SYS$OUTPUT "Unattended operation."
$  ELSE
$    UNATTENDED = 0
$  ENDIF
$
$  IF P4 .EQS. "" THEN P4 = "SYS$PRINT"
$  IF F$GETQUI("DISPLAY_QUEUE","QUEUE_NAME",P4,"SYMBIONT") .EQS. ""
$  THEN 
$    WRITE SYS$OUTPUT "No such printer queue ", P4
$    GOTO _EXIT
$  ENDIF
$
$! (there has to be a better way to do this)
$! If length of time string is too short, add a space to the beginning so the
$! compare will work correctly
$  IF F$LENGTH(P1) .EQ. 22 THEN P1 = " " + P1
$
$  P1_COMPARE = F$CVTIME(P1,"COMPARISON")
$
$
$  WATCHER_LOG_FILE = F$PARSE(F$TRNLNM("WATCHER_LOG"),"WATCHER_DIR:WATCHER.LOG")
$
$  IF F$SEARCH(WATCHER_LOG_FILE) .EQS. "" THEN GOTO _NO_LOG_FILE
$
$  WRITE SYS$OUTPUT "Using WATCHER log file ", F$SEARCH(WATCHER_LOG_FILE)
$
$  SEARCH -
     'WATCHER_LOG_FILE' -
     "WATCHER logged out user" -
     /OUTPUT='TEMPFILE_LOG' -
     /EXACT -
     /noHIGHLIGHT
$
$  WRITE SYS$OUTPUT "Getting all records newer than ", P1
$  WRITE SYS$OUTPUT ""
$  WRITE SYS$OUTPUT "-----"
$  WRITE SYS$OUTPUT ""
$
$!!!
$
$  OPEN/READ WATCHER_LOGFILE 'TEMPFILE_LOG'
$  RECORD_COUNT = 0
$
$_KILLED_USER_LOOP:
$  READ/END_OF_FILE=_EOF WATCHER_LOGFILE RECORD
$  KILLED_DATE = F$EXTRACT(1,23,RECORD)
$  IF F$CVTIME(KILLED_DATE,"COMPARISON") .GTS. P1_COMPARE
$  THEN
$
$    KILLED_AT = F$EXTRACT(1,23,RECORD)
$
$    AFTER_USER = F$EXTRACT(F$LOCATE(" user ",RECORD)+6,999,RECORD)
$    KILLED_USER = F$ELEMENT(0,",",AFTER_USER)
$
$    AFTER_TERM = F$EXTRACT(F$LOCATE(" term ",RECORD)+6,999,RECORD)
$    KILLED_TERM = F$ELEMENT(0,":",AFTER_TERM)
$
$    AFTER_PORT = F$ELEMENT(1,"(",AFTER_USER)
$    KILLED_PORT = F$ELEMENT(0,",",AFTER_PORT) - ")"
$    IF KILLED_PORT .EQS. "" THEN KILLED_PORT = "{unknown}"
$
$    KILLED_LAST_ACTIVE = F$EXTRACT(F$LOCATE("last change ",RECORD)+12,999,RECORD)
$
$    IF KILLED_AT .NES. "" .AND. -
        KILLED_USER .NES. "" .AND. -
        KILLED_PORT .NES. "" .AND. -
        KILLED_LAST_ACTIVE .NES. ""
$    THEN
$      GOSUB _FOUND_KILLED_USER
$      KILLED_AT = ""
$      KILLED_USER = ""
$      KILLED_PORT = ""
$      KILLED_LAST_ACTIVE = ""
$    ELSE
$      WRITE SYS$OUTPUT "Error in WATCHER_MAIL: one of the KILLED_* symbols is null..."
$      SHOW SYMBOL KILLED_*
$    ENDIF ! NULL symbols
$
$  ELSE ! date compare
$    RECORD_COUNT = RECORD_COUNT + 1
$    IF ((RECORD_COUNT / 100) * 100) .EQ. RECORD_COUNT THEN WRITE SYS$OUTPUT -
          F$FAO("Currently processing date: !AS", KILLED_DATE)
$  ENDIF ! date compare
$
$  GOTO _KILLED_USER_LOOP
$
$!!!
$
$_EOF:
$  CLOSE WATCHER_LOGFILE
$  IF F$SEARCH(REPORT_FILE) .NES. "" 
$  THEN
$    PRINT -
     /FLAG -
     /NOTE="ROUTING = HELPDESK, terminated user sessions" -
     /NAME="Watcher Mail" -
     /DELETE -
     /QUEUE='P4' -
     'REPORT_FILE' 
$    PRINT_JOB_QUEUED := TRUE
$  ENDIF
$  WRITE SYS$OUTPUT "%WATCHER_MAIL, Normal end of processing."
$  
$
$_EXIT:
$  IF F$TRNLNM("WATCHER_LOGFILE") .NES. "" THEN CLOSE WATCHER_LOGFILE
$  IF F$TRNLNM("NOTICE_FILE") .NES. "" THEN CLOSE NOTICE_FILE
$  IF F$SEARCH(TEMPFILE_LOG) .NES. "" THEN DELETE 'TEMPFILE_LOG';
$  IF F$SEARCH(TEMPFILE_NOTICE) .NES. "" THEN DELETE 'TEMPFILE_NOTICE';
$  IF F$SEARCH(TEMPFILE_PRINT) .NES. "" THEN DELETE 'TEMPFILE_PRINT';
$  IF F$SEARCH(TEMPFILE_MAIL) .NES. "" THEN DELETE 'TEMPFILE_MAIL';
$  IF F$SEARCH(REPORT_FILE) .NES. "" .AND. F$TYPE(PRINT_JOB_QUEUED) .EQS. "" THEN DELETE 'REPORT_FILE';
$  VERIFY = F$VERIFY(VERIFY)
$  EXIT ! Leaving WATCHER_MAIL.COM ...
$
$!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
$
$_FOUND_KILLED_USER:
$
$  IF F$TRNLNM(TEMPFILE_NOTICE) .NES. "" THEN DELETE 'TEMPFILE_NOTICE';
$  CREATE 'TEMPFILE_NOTICE'
$  OPEN/APPEND NOTICE_FILE 'TEMPFILE_NOTICE'
$
$  WRITE NOTICE_FILE "   VMS Username:             ", KILLED_USER
$  WRITE NOTICE_FILE "   Last recorded activity:   ", KILLED_LAST_ACTIVE
$  WRITE NOTICE_FILE "   Session terminated at:    ", KILLED_AT
$  IF KILLED_PORT .NES. ""
$  THEN
$    WRITE NOTICE_FILE "   Logged in from port:      ", KILLED_PORT
$  ELSE
$    WRITE NOTICE_FILE "   Logged in from terminal:  ", KILLED_PORT
$  ENDIF
$      
$  CLOSE NOTICE_FILE
$
$  IF .NOT. UNATTENDED
$  THEN
$  _GET_DESIRED_ACTION:
$    WRITE SYS$OUTPUT ""
$    WRITE SYS$OUTPUT F$FAO("Username: !12AS killed at: !AS",KILLED_USER,KILLED_AT)
$    WRITE SYS$OUTPUT F$FAO("  from port: !AS, terminal ",KILLED_PORT,KILLED_TERM)
$    WRITE SYS$OUTPUT ""
$    WRITE SYS$OUTPUT "  Desired action:"
$    WRITE SYS$OUTPUT "    N. None    - Don't do anything"
$    WRITE SYS$OUTPUT "    P. Print   - Print notification"
$    WRITE SYS$OUTPUT "    M. Mail    - Mail notification"
$    WRITE SYS$OUTPUT "    B. Both    - Both Print and Mail notification"
$    READ SYS$COMMAND ACTION -
     /PROMPT="  Action (N, P, M, B) [N] ? "/END_OF_FILE=_ABORT
$    ACTION = F$EXTRACT(0,1,F$EDIT(ACTION,"UPCASE,COLLAPSE"))
$    IF ACTION .EQS. "" THEN ACTION = "N"
$    VALID_ACTION = "NPMB"
$    IF F$LOCATE(ACTION,VALID_ACTION) .EQ. F$LENGTH(VALID_ACTION)
$    THEN
$      WRITE SYS$OUTPUT "Invalid selection."
$      GOTO _GET_DESIRED_ACTION
$    ENDIF
$  ELSE  ! unattended
$    WRITE SYS$OUTPUT F$FAO("!12AS killed: !AS, !AS (!AS)",KILLED_USER,KILLED_AT,KILLED_TERM,KILLED_PORT)
$    ACTION = F$EXTRACT(0,1,P2)
$  ENDIF ! unattended
$
$!!!
$
$  IF ACTION .EQS. "N"
$  THEN
$    WRITE SYS$OUTPUT "No action taken."
$    GOTO _EXIT_ACTION_CHOICES
$  ENDIF
$  
$!!!
$
$  IF ACTION .EQS. "M" .OR. ACTION .EQS. "B"
$  THEN
$    COPY SYS$INPUT: 'TEMPFILE_MAIL'
Your account was left unattended and was automatically logged out after a
period of inactivity.

$
$    APPEND 'TEMPFILE_NOTICE',SYS$INPUT: 'TEMPFILE_MAIL'

This is a serious security violation.  Leaving your terminal unattended is
an open invitation for someone to view, tamper with, or destroy the data 
accessible from your account.  

This mail message is to remind you to logout of your account when you are 
no longer using it.

If you need any other information, please call the ISD Help Desk at 322-HELP.

-Dan Wing, Systems Programmer, Information Systems, University Hospital

$    
$    IF .NOT. UNATTENDED
$    THEN
$  _GET_MAIL_USERNAMES:
$      READ SYS$COMMAND CC_USER_CHOICE /PROMPT="Carbon Copy to (Return for default, 0 for no CC) [''CC_USER']: "
$      IF CC_USER_CHOICE .EQS. "" THEN CC_USER_CHOICE = CC_USER
$      IF CC_USER_CHOICE .EQS. "0" THEN CC_USER_CHOICE = ""
$      CC_USER = CC_USER_CHOICE
$    ELSE  ! unattended
$      CC_USER = P3
$    ENDIF ! unattended
$
$!!!killed_user := sysmgr
$
$    IF CC_USER .EQS. "" 
$    THEN
$      MAIL_TO = KILLED_USER
$    ELSE
$      MAIL_TO = KILLED_USER + "," + CC_USER
$    ENDIF
$
$    OPEN/APPEND MAILFILE 'TEMPFILE_MAIL'
$    IF CC_USER .NES. "" THEN WRITE MAILFILE "CC: ", CC_USER
$    CLOSE MAILFILE
$
$    SUBJECT_LINE = "System logout warning - ''KILLED_AT'"
$    PERSONAL_LINE = "System logout warning"
$    DEFINE/USER_MODE SYS$INPUT SYS$COMMAND
$    MAIL 'TEMPFILE_MAIL' 'MAIL_TO' -
     /SUBJECT="''SUBJECT_LINE'" -
     /PERSONAL="''PERSONAL_LINE'"
$    WRITE SYS$OUTPUT "User(s) ", MAIL_TO, " were notified by Email."
$  ENDIF
$
$!!!
$
$  IF ACTION .EQS. "P" .OR. ACTION .EQS. "B"
$  THEN 
$    IF F$SEARCH(REPORT_FILE) .EQS. ""
$    THEN
$      CREATE 'REPORT_FILE'
$      OPEN/APPEND REPORT 'REPORT_FILE'
$      WRITE REPORT "WATCHER_MAIL report, created ", F$TIME(), " by user ", F$GETJPI(0,"USERNAME")
$      WRITE REPORT "Report of all WATCHER records from file ", -
     F$SEARCH(WATCHER_LOG_FILE)
$      WRITE REPORT "Since ", P1
$      WRITE REPORT ""
$      WRITE REPORT ""
$      CLOSE REPORT
$    ENDIF
$
$    OPEN/APPEND NOTICE_FILE 'TEMPFILE_NOTICE'
$    WRITE NOTICE_FILE F$FAO("!70*-")
$    CLOSE NOTICE_FILE
$
$    APPEND/NEW_VERSION 'TEMPFILE_NOTICE' 'REPORT_FILE'
$
$    IF .NOT. UNATTENDED THEN WRITE SYS$OUTPUT "Appended to report."
$  ENDIF  ! mail_this_user
$
$
$_EXIT_ACTION_CHOICES:
$  DELETE 'TEMPFILE_NOTICE';
$  RETURN
$
$
$!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
$_ERROR:
$  WRITE SYS$OUTPUT "Unexpected error encountered in WATCHER_MAIL.COM"
$  GOTO _EXIT
$
$_ABORT:
$  WRITE SYS$OUTPUT "User aborted WATCHER_MAIL.COM"
$  GOTO _EXIT
$
$_NO_LOG_FILE:
$  WRITE SYS$OUTPUT "Error - no WATCHER log file (", WATCHER_LOG_FILE, ")"
$  GOTO _EXIT
$
$_HELP:
$  TYPE SYS$INPUT:

  WATCHER_MAIL
    Used with Matt Madison's WATCHER to report or notify users of being
    terminated by WATCHER.

Usage:  @WATCHER_MAIL [p1] [p2] [p3] [p4]
  p1 [optional] = date/time to use for /SINCE selection
  p2 [optional] = MAIL, PRINT, or BOTH 
  p3 [optional] = CC list for Mail notification
  p4 [optional] = printer queue for Print notification
  
$
$  GOTO _EXIT
