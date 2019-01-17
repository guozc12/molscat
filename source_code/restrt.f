      SUBROUTINE RESTRT(IRSTRT,ISAVEU, JTOTL,JTSTEP,MXPAR,MSET,MHI,
     1                  LABELX,ITYPEX,NSTATX,NQNX,UREDX,IPX,JSTATE,
     2                  NNRGX,ENERGX,SIGCUR,SIGACC,SIGDEG,ISST,
     3                  IECONV,MINJT,MAXJT,ISIGU,IPARTU,OTOL,DTOL,
     4                  IXX,RXX,MRSTRT,IERST,IFST,MXP,IPRINT,
     5                  LCURXS,LACCXS,ICHAN,NSIG,NFIELD,IBDX,RUNIT,CINT)
C  Copyright (C) 2018 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      USE SIZES, ONLY: MXELVL, MXNRG => MXNRG_IN_MOLSCAT
      USE BASIS_DATA, ONLY: NLEVEL, JLEVEL, ELEVEL, IDENT
      USE EFVS, EFVNAX => EFVNAM, EFVUNX => EFVUNT, EFVX => EFV,
     1          ISVX => ISVEFV, NEFVX => NEFV
      USE POTENTIAL, ONLY: NDGVLX => NDGVL, NCONSTX => NCONST,
     1                     NRSQX => NRSQ
C
C  MODIFICATIONS FOR VERSION 14, JUL 94
C  RESTART MOLSCAT CALCULATION FROM SAVED TAPE ON UNIT(ISAVEU):
C  IRSTRT= 1  RESTART AFTER A COMPLETED JTOT SET
C        =-1  SAME AS 1, BUT BEGINNING AT &INPUT JTOTL
C        = 2  RESTART AFTER A COMPLETED SYMMETRY BLOCK
C        = 3  RESTART AFTER LAST GOOD JTOT,M,INRG,IFIELD SET
C        = 4  RESTART AFTER LAST COMPLETED JTOT,M,IFIELD SET
C
C  A RESTART RUN SHOULD HAVE SAME INPUT DECK AS ORIGINAL RUN
C    EXCEPT THAT IRSTRT PARAMETER MUST BE SET.
C    FOR IRSTRT=-1, JTOTL MUST BE RESET TO DESIRED RESTART VALUE
C    SOME OTHER PARMS (E.G., INTEGRATION PARMS *MAY* BE CHANGED)
C
C  RECREATES ACCUM CROSS SECTIONS (OUTPUT/PRBR) FROM SAVED S-MATRICES
C
C  JTSV(IRSTRT),MSV(IRSTRT),INSV(IRSTRT)
C    CONTAIN VALUES FOR LAST *COMPLETED* SET FOR EACH IRSTRT OPTION.
C  RETURNS JTOTL,MRSTRT,IERST,IFST -- VALUES AT WHICH TO RECOMMENCE
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION JSTATE(1)
      DIMENSION ENERGX(MXNRG)
      DIMENSION MINJT(MXNRG),MAXJT(MXNRG),ISST(MXNRG),IECONV(MXNRG)
      DIMENSION SIGCUR(1), SIGACC(1), SIGDEG(1), IXX(1),RXX(1)
      CHARACTER(LEFVN) EFVNAM(0:MAXEFV)
      CHARACTER(LEFVU) EFVUNT(0:MAXEFV)
      DOUBLE PRECISION EFV(0:MAXEFV)
      INTEGER PRNTLV
      CHARACTER(80) LABEL,LABELX
      LOGICAL CONSIS,MPLMIN,LCS,LCS3,LCURXS,LACCXS,LDIAG
C  BIG VALUE TO INITIALIZE JSTOP
      DATA IBIG/1000000/
C
C  ALTERED TO USE ARRAY SIZES FROM MODULE SIZES ON 23-06-17 BY CRLS
C  DYNAMIC STORAGE COMMON BLOCK ...
C  USAGE IN RESTRT DOES *NOT* CONFORM W/ USUAL MOLSCAT PHILOSOPHY:
C  X() IS ACCESSED DIRECTLY, VIA IXX() AND RXX()
C  LIMIT CHECKED DIRECTLY AGAINST MX, I.E., CHKSTR IS NOT USED.
C  ON ENTRY IXX(1), RXX(1) ARE EQUIVALENCED TO X(IXNEXT)
      COMMON /MEMORY/ MX,IXNEXT,NIPR,IDUMMY,X(1)
C
      DIMENSION ELVL(MXELVL)
C
C  COMMON TO COMMUNICATION WITH PRBR; EXCEPT FOR MVALUE THESE HAVE
C  BEEN SET IN PRIOR CALL TO BASIN.
      COMMON /PRBASE/ ITYPE,NQN,NSTATE,MVALUE,IEXX,MPLMIN
C
C  --------------------------------------------------------
      IF (IRSTRT.EQ.0 .OR. IRSTRT.LT.-1) RETURN
      CALL GCLOCK(TSTART)
      RMLOCL=RUNIT
C
C  FIRST MXPAR LOCATIONS IN IXX USED TO STORE HIGHEST ENERGY/M
C  (PERHAPS WE SHOULD KEEP HIGHEST ENERGY IN *LAST* JTOT CYCLE)
      IXI=MXPAR
      IXR=(MXPAR+NIPR-1)/NIPR
      IF (IXNEXT+IXR-1.GT.MX) THEN
        WRITE(6,*) ' *** TERMINAL ERROR. SCRATCH STORAGE EXCEEDED.'
        STOP
      ELSE
        DO 1000 I=1,MXPAR
 1000     IXX(I)=-1
      ENDIF
C
      JSTOP=IBIG
      IF (IRSTRT.EQ.-1) THEN
        WRITE(6,*) ' *** RESTRT.  REQUEST TO RESTART AT JTOT =',JTOTL
        JSTOP=JTOTL-JTSTEP
        IRSTRT=1
      ENDIF
      JRSTRT=IRSTRT
      IF (IRSTRT.GE.3) JRSTRT=(7-IRSTRT)
C  ---------------------------------------------------------------
C  CHECK HEADER INFO ON TAPE/FILE FOR AGREEMENT WITH CURRENT RUN PARAMS.
      READ(ISAVEU,END=9001) LABEL,ITYPE,NSTATE,NQN,URED,IP
      WRITE(6,600) ISAVEU,LABEL,LABELX
  600 FORMAT('  ***'/'  *** RESTRT.  DATA FROM UNIT ISAVEU =',I4/
     2       '  *** LABEL  ON  ISAVEU =',A80/
     3       '  *** CURRENT RUN LABEL =',A80/'  ***')
      IF (ITYPE.EQ.ITYPEX .AND. NSTATX.EQ.NSTATE .AND. NQNX.EQ.NQN .AND.
     1    URED.EQ.UREDX) THEN
        WRITE(6,601) ITYPE,NSTATE,NQN,URED,IP
  601   FORMAT(/'  *** CURRENT PARAMETERS AGREE WITH SAVED VALUES'/
     1         6X,'ITYPE =',I3/6X,'NSTATE, NQN =',2I4/6X,'URED =',F8.4/
     2         6X,'IPROGM =',I3)
      ELSE
        WRITE(6,602) ITYPEX,ITYPE,NSTATX,NSTATE,NQNX,NQN,UREDX,URED
  602   FORMAT('  *** ERROR.  CURRENT/SAVED PARAMETERS DO NOT MATCH'/
     1         14X,'ITYPE',2I6/14X,'NSTATE',2I6/14X,'NQN ',2I6/
     2         14X,'URED',2F12.4/'  *** TERMINATING.')
        STOP
      ENDIF
      IF (IPX.NE.IP) WRITE(6,603) IPX
  603 FORMAT(' *** RESTRT. WARNING: CURRENT RUN IS VERSION',I3,
     1       '; DIFFERS FROM SAVE TAPE VERSION')
      IF (IP.LE.13) THEN
        WRITE(6,*) ' *** RESTRT. CURRENT VERSION CANNOT PROCESS',
     1             ' SAVE TAPES IN IPROGM.LE.13 FORMAT'
        STOP
      ENDIF
C
      NSQ=NSTATE*NQN
      NUSED=(IXI+NSQ+NIPR-1)/NIPR  ! SPACE NEEDED FOR CHECKING JSTATE
      IF (IXNEXT+NUSED-1.GT.MX) THEN
        WRITE(6,*) ' *** TERMINAL ERROR.  NOT ENOUGH STORAGE FOR JSTATE'
        STOP
      ENDIF
C  CAREFUL HERE, BECAUSE BOTH THE REAL ARRAY RXX AND THE INTEGER ARRAY IXX
C  ARE OVERLAID FROM THE SAME POINT IN THE X ARRAY (SIGH)
      IXR=IXR+NUSED
      NUSED=IXR+MXNRG             ! SPACE NEEDED FOR CHECKING ENERGY
      IF (IXNEXT+IXR+MXNRG-1.GT.MX) THEN
        WRITE(6,*) ' *** TERMINAL ERROR.  NOT ENOUGH STORAGE FOR MXNRG'
        STOP
      ENDIF

      CALL HDREAD(ISAVEU,.FALSE.,NSTATE,NQN,IP,
     1           IXX(IXI+1),NLVL,ELVL,NDGVL,NCONST,NRSQ,IBOUND,
     2           NEFV,ISVEFV,EFVNAM,EFVUNT,NFLD,NNRG,RXX(IXR+1))
      DO 1001 I=1,NSQ
        IF (IXX(IXI+I).EQ.(JSTATE(I))) GOTO 1001
        WRITE(6,604) (JSTATE(II),IXX(IXI+II),II=1,NSQ)
  604   FORMAT('  *** TERMINAL ERROR.  CURRENT/SAVED JSTATE MISMATCH'/
     1         (8(2X,2I4)))
        STOP
 1001 CONTINUE
      WRITE(6,*) ' *** CURRENT/SAVED JSTATE MATCH'
C
      IF (NLVL.NE.NLEVEL) THEN
        WRITE(6,605) NLVL,NLEVEL
  605   FORMAT('  *** TERMINAL ERROR. CURRENT/SAVED NLEVEL',2I6)
        STOP
      ENDIF
      DO 1002 I=1,NLEVEL
        IF (ELEVEL(I).EQ.ELVL(I)) GOTO 1002
        WRITE(6,606) I,ELEVEL(I),ELVL(I)
  606   FORMAT('  *** TERMINAL ERROR. CURRENT/SAVED ELEVEL(',I3,')=',
     1         2E12.4)
        STOP
 1002 CONTINUE
      WRITE(6,*) ' *** CURRENT/SAVED NLEVEL,ELEVEL MATCH.'
      IF (NDGVLX.NE.NDGVL) THEN
        WRITE(6,999) 'NDGVL',NDGVLX,NDGVL
  999   FORMAT(2X,'*** TERMINAL ERROR.  CURRENT/SAVED ',A,2I6)
        STOP
      ENDIF
      IF (NCONSTX.NE.NCONST) THEN
        WRITE(6,999) 'NCONST',NCONSTX,NCONST
        STOP
      ENDIF
      IF (NRSQX.NE.NRSQ) THEN
        WRITE(6,999) 'NRSQ',NRSQX,NRSQ
        STOP
      ENDIF
      IF (IBDX.NE.IBOUND) THEN
        WRITE(6,999) 'IBOUND',IBDX,IBOUND
        STOP
      ENDIF
      IF (NEFVX.NE.NEFV) THEN
        WRITE(6,999) 'NEFV',NEFVX,NEFV
        STOP
      ENDIF
      IF (ISVX.NE.ISVEFV) THEN
        WRITE(6,999) 'ISVEFV',ISVX,ISVEFV
        STOP
      ENDIF
      DO IEFV=1,NEFV
        IF (EFVNAX(IEFV).NE.EFVNAM(IEFV)) THEN
          WRITE(6,998) 'EFVNAM',EFVNAX(IEFV),EFVNAM(IEFV)
  998     FORMAT(2X,'*** TERMINAL ERROR.  CURRENT/SAVED ',A,2(1X,A))
          STOP
        ENDIF
        IF (EFVUNX(IEFV).NE.EFVUNT(IEFV)) THEN
          WRITE(6,998) 'EFVUNT',EFVUNX(IEFV),EFVUNT(IEFV)
          STOP
        ENDIF
      ENDDO
C
C     READ(ISAVEU,END=9001) NNRG,(RXX(IXR+I),I=1,NNRG)
      IF (NNRG.NE.NNRGX) THEN
        WRITE(6,607) NNRGX,NNRG
  607   FORMAT('  *** TERMINAL ERROR. CURRENT/SAVED NNRG',2I6)
        STOP
      ENDIF
      DO 1003 I=1,NNRG
        IF (RXX(IXR+I).EQ.ENERGX(I)) GOTO 1003
        WRITE(6,608) I,ENERGX(I),RXX(IXR+I)
  608   FORMAT('  *** TERMINAL ERROR. CURRENT/SAVED ENERGY(',I3,')=',
     1         2E12.4)
        STOP
 1003 CONTINUE
      WRITE(6,*) ' *** CURRENT/SAVED NNRG,ENERGY MATCH.'
C
C  CHECKING SPECIFIC TO SOME ITYPES ...
      LCS=ITYPE.EQ.21 .OR. ITYPE.EQ.22 .OR. ITYPE.EQ.25 .OR.
     1    ITYPE.EQ.26 .OR. ITYPE.EQ.27
      LCS3=ITYPE.EQ.23
C  MPLMIN IS AVAILABLE FROM CURRENT RUN IN /PRBASE/, BUT SAVE TAPE
C  CANNOT BE CHECKED FOR ORIGINAL VALUE.  ASSUME IT IS SAME.
C  THIS SHOULD ONLY MATTER FOR PRESSURE BROADENING W/ COUPLED STATES
      IF (LCS .OR. LCS3) THEN
        IF (MPLMIN) THEN
          WRITE(6,*) ' *** CURRENT COUPLED STATES APPROXIMATION ',
     1               'HAS IDENTICAL +/- PROJECTIONS'
        ELSE
          WRITE(6,*) ' *** CURRENT COUPLED STATES APPROX HAS ',
     1               'BOTH +/- PROJECTIONS'
        ENDIF
        WRITE(6,*) '     WILL ATTEMPT TO VERIFY CONSISTENCY WITH ',
     1             'SAVE TAPE'
      ENDIF
C  FOR ITYPE='3' CHECK JLEVEL/JSTATE ARE CONSISTENT
      IF (ITYPE-10*(ITYPE/10).EQ.3) THEN
        CONSIS=.TRUE.
        NLV=0
        IXT=(NQNX-1)*NSTATX
        DO 4002 I=1,NSTATX
          IL=JSTATE(IXT+I)
          NLV=MAX(NLV,IL)
          CONSIS=CONSIS .AND. JLEVEL(2*IL-1).EQ.JSTATE(I)
 4002     CONSIS=CONSIS .AND. JLEVEL(2*IL).EQ.JSTATE(NSTATX+I)
        IF (NLV.EQ.NLVL .AND. CONSIS) THEN
          WRITE(6,*) ' *** ITYPE=3+10*N: JLEVEL/JSTATE ARE CONSISTENT'
        ELSE
          WRITE(6,*) ' *** ERROR. ITYPE=3+10*N: INCONSISTENT JLEVEL/',
     1               'JSTATE.  SHOULD AFFECT ONLY PRBR CALCULATION'
        ENDIF
      ENDIF
C
C  READ THROUGH JTOT/S-MATRICES FIRST TIME, TO SEE WHAT'S THERE
      NOPMX=0
      MAXMIN=0
      JTOLD=-1
      MSOLD=MXPAR
      IFOLD=NFIELD
      INOLD=NNRG
C
C  THESE READ STATEMENTS NEED TO MAINTAIN CONSISTENCY WITH WHAT IS IN
C  LPREAD
C
C  ONLY READING FIRST LINE SO NO NEED TO ASSIGN SPACE FOR INDLEV, L, WVEC,
C  AND CENT
 2000 IFAIL=0
      CALL SLPRD(ISAVEU,JTOT,INRG,ECHK,EFV,EREF,IEXCH,WGHT,M,NOPEN,
     1           IFSET,IXX(IXI),IXX(IXI),RXX(IXR),RXX(IXR),
     2           RXX(IXR),RXX(IXR),
     3           IP,IBOUND,1,IFAIL)
      IF (IFAIL.NE.0) GOTO 9002
      READ (ISAVEU) ! SKIP OVER LINE THAT CONTAINS INDLEV, L/CENT, WVEC
      IF (JTOT.GT.JSTOP) GOTO 9004
C
C  SEE IF M-VALUE IS CONSISTENT W/ MHI,MSET AND MXPAR
      IF (M.GT.MXPAR .OR. M.LE.0) THEN
        WRITE(6,*) ' *** TERMINAL ERROR.  ILLEGAL M-VALUE',M
        WRITE(6,*) ' *** TERMINAL ERROR.  NOTE.  MXPAR =',MXPAR
        STOP
      ELSE
        IXX(M)=MAX(IXX(M),INRG)
      ENDIF
      IF (MSET.GT.0 .AND. (M.LT.MSET .OR. M.GT.MHI)) THEN
        WRITE(6,612) M,MSET,MHI
  612   FORMAT(' *** RESTRT.  WARNING.  M =',I4,
     1         ' INCONSISTENT WITH CURRENT MSET,MHI =',2I4)
      ENDIF
C  CHECK CONSISTENCY OF INRG,ECHK
      IF (ABS(ECHK-ENERGX(INRG)).GT.1.D-8)
     1  WRITE(6,611) JTOT,M,INRG,ECHK
  611   FORMAT(/' *** WARNING.  FOR JTOT,M=',I4,'.',I2,' ENERGY('
     1         ,I4,'), BAD ECHK =',E16.8)
C
      IF (IXNEXT+IXR+NOPEN*NOPEN-1.LE.MX) THEN
        READ(ISAVEU)
        READ(ISAVEU)
      ELSE
        WRITE(6,*) ' *** RESTRT.  TERMINAL ERROR. INADEQUATE SCRATCH ',
     1             'STORAGE FOR SREAL/SIMAG. NOPEN =',NOPEN
        STOP
      ENDIF
C  COMPLETE JTOT,M,INRG SET.  UPDATE NOPMX; SAVE JRSTRT=4 VALUES
      NOPMX=MAX(NOPMX,NOPEN)
      MAXMIN=MAX(MAXMIN,M)
      IF (JRSTRT.EQ.4) THEN
        JTOLD=JTOT
        MSOLD=M
        IFOLD=IFSET
        INOLD=INRG
      ENDIF
      IF (JRSTRT.EQ.3 .AND. INRG.EQ.NNRG) THEN
        JTOLD=JTOT
        MSOLD=M
        IFOLD=IFSET
      ENDIF
      IF (JRSTRT.EQ.2 .AND. INRG.EQ.NNRG .AND. IFSET.EQ.NFIELD) THEN
        JTOLD=JTOT
        MSOLD=M
      ENDIF
      IF (ABS(JRSTRT).EQ.1 .AND. INRG.EQ.NNRG .AND.
     1    IFSET.EQ.NFIELD .AND. M.EQ.MXPAR) THEN
        JTOLD=JTOT
      ENDIF
C
C  GO BACK FOR MORE JTOT, INRG SETS . . .
      GOTO 2000
C
C  END OF FILE CONDITIONS
C
 9001 WRITE(6,*) ' *** TERMINAL ERROR.  PREMATURE EOF READING ISAVEU.'
      STOP
C
C  NORMAL END OF FILE AFTER A COMPLETED SET.
C  DETERMINE IF LAST INPUT COMPLETED 1) M-SET, 2) JTOT
 9002 WRITE(6,699) ISAVEU
  699 FORMAT(/' *** NOTE.   NORMAL EOF REACHED ON UNIT (',I3,')')

      JTNEW=JTOLD
      MNEW=MSOLD
      IFNEW=IFOLD
      INNEW=INOLD
      IF (JRSTRT.EQ.4) THEN
        INNEW=INNEW+1
      ELSEIF (JRSTRT.EQ.3) THEN
        IFNEW=IFNEW+1
        INNEW=1
      ELSEIF (JRSTRT.EQ.2) THEN
        MNEW=MNEW+1
        IFNEW=1
        INNEW=1
      ELSEIF (JRSTRT.EQ.1) THEN
        JTNEW=JTNEW+JTSTEP
        MNEW=1
        IFNEW=1
        INNEW=1
      ENDIF

      IF (INNEW.GT.NNRG) THEN
        IFNEW=IFNEW+1
        INNEW=1
      ENDIF
      IF (IFNEW.GT.NFIELD) THEN
        MNEW=MNEW+1
        IFNEW=1
        INNEW=1
      ENDIF
      IF (MNEW.GT.MXPAR) THEN
        JTNEW=JTNEW+JTSTEP
        MNEW=1
        IFNEW=1
        INNEW=1
      ENDIF

      IF (INRG.EQ.NNRG) THEN
        WRITE(6,*) ' LAST INPUT COMPLETES AN EFV SET'
        IF (IFSET.EQ.NFIELD) THEN
          WRITE(6,*) '            LAST INPUT APPEARS TO COMPLETE AN'//
     1               ' M-SET'
          IF (M.EQ.MAXMIN) THEN
            WRITE(6,*) '             IT ALSO APPEARS TO COMPLETE A JTOT'
          ENDIF
        ENDIF
      ENDIF

C  IRSTRT=-1 CASES: TRY TO ASCERTAIN COMPLETENESS THROUGH JSTOP.
      IF (JSTOP.GE.IBIG) GOTO 3000

      IF (JTOT.NE.JSTOP) THEN
        WRITE(6,*) ' *** LAST COMPLETE JTOT,M,EFV,INRG=',
     1              JTOT,M,IFSET,INRG
        WRITE(6,*) ' *** ERROR.  LAST JTOT.NE.JSTOP',JTOT,JSTOP
        STOP
      ENDIF
      IF (JTOLD.NE.JTOT) THEN
        WRITE(6,*) ' *** POSSIBLE ERROR.'
        WRITE(6,*) '     IT IS NOT CLEAR THAT FINAL JTOT SET IS'//
     1             ' COMPLETE.  ASSUME IT IS.'
        WRITE(6,*) ' *** LAST COMPLETE JTOT,M,EFV,INRG=',
     1              JTOT,M,IFSET,INRG
      ENDIF
      GOTO 3000
C
C  EOF WHILE READING S-MATRICES; ALL JTSV,MSV,INSV SHOULD BE CORRECT.
 9003 WRITE(6,698) ISAVEU
  698 FORMAT(/' *** NOTE. ABNORMAL EOF REACHED ON UNIT (',I3,')'/
     1       '            INCOMPLETE (JTOT,INRG,M)-SET')
      IF (JSTOP.LT.IBIG) THEN
        WRITE(6,*) ' *** ERROR.  ISAVEU DOES NOT HAVE ALL S-MATRICES'//
     1             ' PRIOR TO REQUESTED RESTART AT JTOTL =',JTOTL
        WRITE(6,*) ' *** LAST COMPLETE JTOT,M,EFV,INRG=',
     1              JTOT,M,IFSET,INRG
        STOP
      ENDIF
      GOTO 3000

C  BELOW REACHED IF JSTOP EXCEEDED BEFORE EOF
C  FORCE JTSV(IRSTRT=1) VALUES TO LAST COMPLETED SET
 9004 WRITE(6,*) ' *** ISAVEU INPUT TERMINATED BY IRSTRT=-1, JSTOP =',
     1           JSTOP
C
 3000 WRITE(6,630) JTOT,M,IFSET,INRG
  630 FORMAT(/'  ***',6X,' LAST COMPLETED (JTOT,M,EFV,INRG)-SET ---',
     1       4I5)
      IF (JRSTRT.NE.4)
     1    WRITE(6,631) IRSTRT,JTOLD,MSOLD,IFOLD,INOLD
  631 FORMAT('  *** FOR REQUESTED IRSTRT =',I2/
     1       '  ***',6X,' LAST COMPLETED (JTOT,M,EFV,INRG)-SET ---',4I5)
      WRITE(6,632)
  632 FORMAT('  ***',6X,' THESE S-MATRICES WILL BE REREAD/REPROCESSED')
C
C  END OF READ THROUGH TO CHECK WHAT HAS BEEN SAVED
C
C  ----------------------------------------------------------------
C  READ THROUGH TAPE/FILE AGAIN, BUT ONLY THROUGH TO APPROPRIATE LAST SET
C  AND PROCESS S-MATRICES THROUGH OUTPUT/PRBR
C
C  ALLOCATE STORAGE FOR NB, L, INDLEV, CENT, WV, SR, SI; AND PRBR TEMPORARIES.
C  PLACE THE PERMANENT VARIABLES FIRST (REALS THEN INTEGERS)
C
C  (THIS CODE IS SLIGHTLY LAZY, AND ASSIGNS TOO MUCH SPACE FOR INTEGERS,
C   BUT THAT'S PROBABLY NOT AN ISSUE AT THIS POINT)
      IXWV=IXNEXT               ! WVEC
      IXSR=IXWV+NOPMX           ! SR
      IXSI=IXSR+NOPMX*NOPMX     ! SI
      IXNB=IXSI+NOPMX*NOPMX     ! NB
      IXL=IXJNB+NOPMX           ! L
      IXIND=IXL+NOPMX           ! INDLEV
      IXCENT=IXIND+NOPMX        ! CENT
      IXEINT=IXCENT+N
C  NO SPACE NEEDED FOR EINT - ONLY USED IF IPRINT>10
      IXNEXT=IXEINT !+N
      NUSED=0
      CALL CHKSTR(NUSED)
C  NEXT ASSIGN SPACE FOR TEMPORARIES FOR OUTPUT
      ITSCAT=IXNEXT                 ! SCLEN
      ITKMAT=ITSCAT+2*NOPMX         ! KMAT } THESE ARRAYS WILL NOT BE
      ITWK1=ITKMAT  ! +NOPMX*NOPMX  ! WK1  } USED BECAUSE THE K MATRIX
      ITWK2=ITWK1   ! +NOPMX        ! WK2  } WAS NOT WRITTEN OUT
      IXNEXT=ITWK2  ! +NOPMX
C  NO SPACE NEEDED FOR INDUSE, INDACC, LNEVER - ONLY USED IF IPRINT>5
C  IBOUND, CINT IRRELEVANT - ONLY USED IF IPRINT>10 (RECALL IPRINT SET
C  TO 0 IN CALLS TO OUTPUT FROM RESTRT)
      IXIUSE=ITWK2  ! +NOPMX
      IXIACC=IXIUSE ! +NOPMX
      IXLNEV=IXIACC ! +NSIG
      IXNEXT=IXLNEV ! +NSIG
      NUSED=0
      CALL CHKSTR(NUSED)
C  NEXT ASSIGN SPACE FOR TEMPORARIES FOR PRBR
      IT1=ITSCAT                ! IC
      IT2=IT1+NOPMX             ! IL
      IT3=IT2+NOPMX             ! IC1
      IT4=IT3+NOPMX             ! IL1
      IXNEXT=IT4+NOPMX
      NAVAIL=MX-IXNEXT+1
      IF (NAVAIL.LE.0) THEN
        WRITE(6,*) '  *** RESTRT.  INADEQUATE SCRATCH STORAGE'//
     1             ' TO PROCESS SAVED S-MATRICES.'
        STOP
      ENDIF
C
C  SET VALUES REQUIRED FOR OUTPUT/PRBR
      DO 4001 I=1,NOPMX
 4001   IXX(IXNB-1+I)=I
      RUNIT=1.D0
      TTIME=0.D0
      ISIGPR=0
      ILSU=0
C  REQUEST MINIMAL OUTPUT FROM OUTPUT/PRBR ...
      JPRINT=MIN(1,IPRINT)
C
      REWIND ISAVEU
      READ(ISAVEU,END=9999) LABEL,ITYPE,NSTATE,NQN,URED,IP
      CALL HDREAD(ISAVEU,.FALSE.,NSTATE,NQN,IP,
     1           JSTATE,NLEVEL,ELVL,NDGVL,NCONST,NRSQ,IBOUND,
     1           NEFV,ISVEFV,EFVNAM,EFVUNT,NFIELD,NNRG,ENERGY)
      NSQ=NSTATE*NQN
 4000 IFAIL=0
      CALL SLPRD(ISAVEU,JTOT,INRG,ECHK,EFV,EREF,IEXCH,WGHT,M,NOPEN,
     1           IFSET,IXX(IXIND),IXX(IXL),RXX(IXCENT),RXX(IXWV),
     2           RXX(IXSR),RXX(IXSI),
     3           IP,IBOUND,0,IFAIL)
      IF (IFAIL.GT.0) GOTO 9999
      MXP=MAX(MXP,M)
c     CALL SREAD(ISAVEU,NOPEN,RXX(IXSR),IEND)
c     IF (IEND.GT.0) GOTO 9999
c     CALL SREAD(ISAVEU,NOPEN,RXX(IXSI),IEND)
c     IF (IEND.GT.0) GOTO 9999
C
C  OUTPUT IS USED TO PROCESS S MATRICES INTO CROSS SECTIONS.  
      IACC=((IFSET-1)*NNRG+INRG-1)*NSIG**2+1
c     WRITE(6,*)'HAVE READ',JTOT,M,IFSET,INRG
      CALL OUTPUT(JTOT,IXX(IXNB),IXX(IXJIND),IXX(IXL),IXX(IXIND),
     1            RXX(IXWV),RXX(IXSR),RXX(IXSI),X(ITKMAT),RUNIT,
     2            X(ITSCAT),NOPEN,M,MXPAR,WGHT,IEXCH,
     3            INRG,TTIME,ENERGX(INRG),EREF,SIGCUR,SIGACC(IACC),
     4            SIGDEG,JSTATE,ISST,IECONV,
     5            MINJT,MAXJT,NSTATE,
     6            NQN,OTOL,DTOL,0,ISIGU,IPARTU,ISAVEU,
     7            ISIGPR,IRSTRT,ICHAN,X(ITWK1),X(ITWK2),RXX(IXCENT),
     8            RXX(IXEINT),IBOUND,IXX(IXIUSE),IXX(IXIACC),
     9            IXX(IXLNEV),CINT,IFSET,JPRINT,.TRUE.,.FALSE.)
C
C  BELOW DUPLICATES DRIVER (SG: I DON'T THINK IT IS USED ANYMORE.)
      MOLD=-M
      IF (M.EQ.MXPAR) MOLD=0
C
C  COUPLED STATES PRBR NEEDS MVALUE; CALC FROM M (NB IEXX NOT USED)
C  BELOW TRIES TO BE CONSISTENT WITH MOLSCAT; SHOULD BE MOOT AS IT
C  ONLY AFFECTS PRBR AND ITYPE=23/IDENT.NE.0 IS NOT SUPPORTED.
C  N.B. ORDER OF ITYPE=23 WAS CHANGED IN VERSION 13
      IF (LCS .OR. (LCS3 .AND. IPROGM.LE.12)) THEN
        IF (LCS3 .AND. IDENT.NE.0) THEN
          IF (M.LE.MXPAR/2) THEN
            IEXX=1
            MVALUE=M-1
          ELSE
            IEXX=2
            MVALUE=M-(MXPAR/2)-1
          ENDIF
        ELSE
          MVALUE=M-1
        ENDIF
C  CHECK CONSISTENCY OF MPLMIN/MVALUE,WGHT
        IF ((MPLMIN .AND. (.NOT.((MVALUE.EQ.0 .AND. WGHT.EQ.1.D0) .OR.
     1                           (MVALUE.GT.0 .AND. WGHT.EQ.2.D0))) .OR.
     2      .NOT.MPLMIN .AND. MVALUE.NE.1.D0) .AND. IDENT.EQ.0)
     3       WRITE(6,*) ' *** INCONSISTENT MVALUE/WGHT'
      ELSEIF (LCS3 .AND. IPROGM.GE.13) THEN
C  CODE FOR ORDER STARTING WITH VERSION 13X ...
        IEXX=IEXCH
        IF (IDENT.EQ.0) THEN
          MVALUE=M-1
        ELSE
          IEXX=2-MOD(M,2)
          IF (IEXX.NE.IEXCH) WRITE(6,*)
     1      ' *** INCONSISTENT: IEXCH FROM M .NE. IEXCH ON TAPE'
          MVALUE=(M+1)/2-1
        ENDIF
      ENDIF
      CALL PRBR(JTOT,MOLD,NOPEN,INRG,RUNIT,
     1          IXX(IXNB),IXX(IXJIND),IXX(IXL),RXX(IXWV),
     2          RXX(IXSR),RXX(IXSI),IXX(IT1),IXX(IT2),IXX(IT3),IXX(IT4),
     3          JSTATE,MXPAR,WGHT,JPRINT,ILSU)
C
C  UNTIL WE HIT 'FINAL' SET, GO BACK FOR MORE JTOT,M,INRG ...
      IF (JTOT.NE.JTOLD .OR. M.NE.MSOLD .OR.
     1    INRG.NE.INOLD .OR. IFSET.NE.IFOLD) GOTO 4000
C
C  WE HAVE NOW FINISHED REPROCESSING THE 'SAVED' S-MATRICES
C
      CALL GCLOCK(TEND)
      TUSED=TEND-TSTART
      WRITE(6,634) NUSED,NAVAIL,TUSED
  634 FORMAT('  *** RESTRT.  REPROCESSING COMPLETED.  IT REQUIRED'/
     1       5X,I9,' OF THE',I12,
     2       ' CURRENTLY AVAILABLE WORDS OF STORAGE'/
     3       9X,'AND',F8.2,' CPU SECONDS.')
C
C  CHOOSE 'NEXT' JTOTL,MRSTRT,IERST AND PUT IN CALLING ARGUMENTS
      JTOTL=JTNEW
      MRSTRT=MNEW
      IFST=IFNEW
      IERST=INNEW
      WRITE(6,635) JTOTL,MRSTRT,IERST,IFST
  635 FORMAT('  *** RESTRT.  CALCULATION WILL BE RESTARTED AT'/
     1       15X,'JTOT =',I4,',  M =',I3,',  ENERGY(',I4,'), EFV SET #',
     2       I4)
C
      IXNEXT=IWVX
      RUNIT=RMLOCL
      RETURN
C
 9999 WRITE(6,*) '  *** RESTRT. ERROR: UNEXPECTED EOF REREADING ISAVEU'
      STOP
      END
