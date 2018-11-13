      SUBROUTINE PRBR(JTOT,IBLOCK,N,INRG,RM,
     1                NBASIS,JSINDX,L,WVEC,
     2                SREAL,SIMAG,IC,IL,IC1,IL1,
     3                JSTATE,MXPAR,WGHT,IPRINT,ILSU)
C  Copyright (C) 2018 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      USE basis_data, ONLY: NLEVEL, JLEVEL, ELEVEL, JHALF, IDENT
      USE sizes, ONLY: MXNRG => MXNRG_in_MOLSCAT, MXLN
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      SAVE
C
C ***   AUG 76 NEW COUPLED STATES TREATMENT (KOURI ET AL.)
C ***   JUL 86 (CCP6 VERSION 9)  MOD 26 AUG 86 TO GET MXREC PROPERLY.
C ***                            AND MOD 21 OCT 86 : EDIFMX
C ***   OCT 86 VERSION FOR 'OFF-DIAGONAL' CROSS SECTIONS
C ***   JAN 87 CHANGES TO GET MPLMIN HANDLING CORRECT FOR ITYPE=25,26
C ***          AND ADD JTSTEP TO ENTRY PRBOUT (REQUIRES CHANGE IN DRIVER)
C ***   MAR 87 CORRECTIONS FOR ITYPE=26
C ***   DEC 88 INCLUDE ITYPE=7 AND Q=0
C ***   MAR 89 HAS 'IN-CORE' D.A. SIMULATION
C ***          (NEED SUBROUTINE DASIZE/ENTRIES DARD1,DARD2,DAWR1,DAWR2)
C ***   JUL 92 REMOVES ALL REFERENCES TO LCSOLD (OLD, INCORRECT,
C ***          FORMULATION FOR COUPLED STATES:  SEE, E.G.,
C ***               GREEN, ET AL. JCP, 66, 1409 (1977))
C ***          CALLS TO ENTRIES (IN PRBR3) ALSO HAVE BEEN TRAPPED THERE.
C ***   JUN 93 FIXES BUG IN PRBR3 AND USES /MEMORY/ TO ELIMINATE LIMITS.
C ***   AUG 94 V14: ENTRY PRBCNT ADDED AND COMMON CMBASE CHANGED
C ***   JUN 17 ADAPTED TO USE MODULE sizes FOR DIMENSIONING IN CMBASE
C ***   AUG 18 COMMON BLOCK CMBASE REPLACED BY MODULE basis_data
C
C  CALCULATES SIGMA(JA1,JB1;JA,JB;K)
C  WHERE A/B INDICATE INITIAL/FINAL SPECTRAL LINES,
C        A1/B1 ARE AFTER INTERACTION,  AND K IS TENSOR ORDER
C  SEE, E.G., SHAFER AND GORDON, JCP 58, 5422 (1973).
C
C  SUPPOSED TO BE UPWARD COMPATIBLE IF LDIAG=.TRUE.:
C  LDIAG=.TRUE.  TAKES *OLD* INPUT LINE=LEVA,LEVB, LEVA,LEVB, ... ,
C                AND SETS LEVA1=LEVA, LEVB1=LEVB FOR ALL LINES.
C  LDIAG=.FALSE. INPUT IS LINE=LEVA,LEVB,LEVA1,LEVB1,
C                              LEVA,LEVB,LEVA1,LEVB1, ...
C  N.B. LDIAG FORCED TO TRUE FOR ITYPE=3 CALCULATIONS.
C
C  ENTRY PRBRIN ACCEPTS &INPUT DATA AND SETS UP PRES. BROAD. CALC.
C  ENTRY PRBOUT PRINTS OUT ACCUMULATED SIGR, SIGI.
C  ENTRY PRBCNT FINDS WHETHER AN S-MATRIX WILL BE USED FOR PB CALC
C
C  PRBR SPECIFICATIONS --------------------------------------
C
      DIMENSION NBASIS(1),JSINDX(1),L(1),IC(1),IL(1),IC1(1),IL1(1),
     1          JSTATE(NSTATE,NQN)
      DIMENSION WVEC(1),SREAL(1),SIMAG(1)
C
C  JTOT IS TOTAL ANGULAR MOMENTUM
C  IBLOCK = 0 FOR LAST SYMMETRY BLOCK AT THIS JTOT.
C  N IS NUMBER OF OPEN CHANNELS, DETERMINES DIMENSION OF VECTORS.
C  INRG IS INDEX FOR ENERGY VALUES
C  RM IS SCALING FACTOR FOR RADIAL WAVEFUNCTION.
C  NBASIS (I) POINTS TO JSINDX,L VALUES FOR ITH OPEN CHANNEL.
C  JSINDX IS VECTOR OF BASIS SET LEVELS
C  L IS VECTOR OF BASIS ORBITAL ANGULAR MOMENTA.
C  WVEC IS VECTOR OF WAVEVECTORS
C  SREAL(N,N) IS REAL PART OF S MATRIX.
C  SIMAG(N,N) IS IMAGINARY PART OF S MATRIX.
C
      LOGICAL ITYPE3,EPM,LCSNEW,MPLMIN,LCSSYM
      INTEGER JT(2)
C
C  PRBRIN SPECIFICATIONS ------------------------------------
C
      INTEGER NLPRBR,LINE(2*MXLN),ILSU,NNRG,IPRINT,IFEGEN
      INTEGER T(MXLN)
      DIMENSION ENERGY(NNRG)
C
C  NLPRBR =0 FOR NO LINE SHAPE CALC.
C         =N (GT.0) GIVES NO. OF LINES FOR WHICH TO COMPUTE L.S.
C  LINE(4*I-3),...  ,I=1,NLPRBR IS LEVEL DATA FOR LINES.
C  ILSU (NOW REDUNDANT) WAS DIRECT ACCESS FILE FOR WORKING STORAGE
C  ENERGY(NNRG) ARE ENERGIES AT WHICH S MATRIX IS CALCULATED.
C  MXNRG IS MAXIMUM DIMENSION OF ENERGY ARRAY
C  IFEGEN .GT. 0  REQUESTS GENERATION OF ADDITIONAL ENERGY VALUES.
C  IPRINT IS INTEGER PRINT CONTROL.
C
      LOGICAL NOCALC,PF,NDEBUG
      LOGICAL LDIAG,EXISTS,LDIAGX
      CHARACTER(8) PTP(3)
      CHARACTER(2) SFX(2),ORDNL
      CHARACTER(1) PLUR(2)
C  STORAGE DIMENSIONED FOR NO. OF LINES = MAXLN.
      DIMENSION LN(2*MXLN,9)
      DIMENSION EREL(2*MXLN),SIGR(2*MXLN),SIGI(2*MXLN)
      DIMENSION P(2),PRTY(4)
C
C  INFORMATION ORIGINALLY PASSED AS ENTRY PRBRBS, NOW IN COMMON
C
      COMMON /PRBASE/ ITYPE,NQN,NSTATE,MVALUE,IEXCH,MPLMIN
      COMMON /ASSVAR/ IDA
C
C  NSTATE AND NLEVEL ARE NO. OF LEVELS IN BASIS SET.
C  JSTATE AND JLEVEL ARE QUANTUM NUMBERS FOR THESE LEVELS.
C  ELEVEL ARE ENERGIES OF THESE LEVELS.
C  ALTERED TO USE ARRAY SIZES FROM MODULE sizes ON 23-06-17 BY CRLS
C
C  DYNAMIC STORAGE COMMON BLOCK ...
      COMMON /MEMORY/ MX,IXNEXT,NIPR,IDUMMY,X(1)
C
C  --- DATA INITIALIZATIONS ---
C
      DATA PTP/' Q = 0  ',' DIPOLE ',' RAMAN  '/
      DATA P/1.D0,-1.D0/, PRTY/1.D0,-1.D0,-1.D0,1.D0/
      DATA PLUR /' ','S'/
C *** BELOW REPLACES JMH'S CRITERION OF 1.D-10 FOR ENERGY DIFFERENCE
C *** SMALLER VALUE MAY BE NEEDED FOR RESONANCE CALCULATIONS.
      DATA EDIFMX/5.D-6/
C  FOR COMPATABILITY WITH OLD INPUT, SET LDIAG=.TRUE.
      DATA LDIAGX/.FALSE./
C  IF NDEBUG .EQ. .FALSE. CHECK FOR 'IMPOSSIBLE' NUMBERS OF MATCHES.
      DATA NDEBUG/.FALSE./
C  DIMENSION LIMITATION ...
C  FOR CHECKING OVER-WRITE OF "DA FILE"
      DATA JCHKSV/-1/
C
C  STATEMENT FUNCTION (LOGICAL)
      EXISTS(I) = I.GT.0 .AND. I.LE.NLEVEL
C
C * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
C
      IF (NOCALC) RETURN

      IF (JCHKSV.EQ.-1) JCHKSV=JTOT
      DO 3000 IA=1,2
C  IA=1 CHECKS FOR USE OF THIS JTOT,INRG WITH J(ALPHA).
C  IA=2 FOR J(BETA).
        IB=3-IA
C  FIND LINES, I, WHICH USE THIS INRG, JTOT S MATRIX.
        IKEEP=0
        DO 3100 I=1,NLINE
          IF (LN(I,IA+3).NE.INRG) GOTO 3100

          K=LN(I,3)
          JDIFMX=K
          IF (LCSNEW) JDIFMX=0
          JDM=MAX(JDM,JDIFMX)
          IF (ITYPE3) GOTO 3211

C  FOR ITYPE=1,2,5 GET J-VALUE FROM 1ST COL OF JSTATE.
          JA=JSTATE(LN(I,1),1)
          JB=JSTATE(LN(I,2),1)
          JA1=JSTATE(LN(I,8),1)
          JB1=JSTATE(LN(I,9),1)
C  PARITY FACTOR FOR CS WITH MPLMIN; THIS IS NORMALLY +1.
          F3PJ=PARSGN(JA+JA1+JB+JB1)
C  FIND BASIS FNS. CORRESPONDING TO JA/JA1 (JB/JB1) AND GET L VALUES.
C     ROWS=>JA1,IC1,IL1    COLS=>JA,IC,IL
C  FOR DIAG CASE (JA=JA1), IC/IC1 AND IL/IL1 HAVE SAME VALUES.
          NLVAL=0
          NLVAL1=0
          DO 3200 II=1,N
            JJ=NBASIS(II)
            IF (JSINDX(JJ).NE.LN(I,IA)) GOTO 3201

            NLVAL=NLVAL+1
            IC(NLVAL)=II
            IL(NLVAL)=L(JJ)
 3201       IF (JSINDX(JJ).NE.LN(I,IA+7)) GOTO 3200
            NLVAL1=NLVAL1+1
            IC1(NLVAL1)=II
            IL1(NLVAL1)=L(JJ)
 3200     CONTINUE
          GOTO 3212
C
C  FOR ITYPE=3 GET J-VALUE FROM JLEVEL.  RECALL J1,J2 PACKED IN ORDER
C
 3211     JA=JLEVEL(2*LN(I,1)-1)
          JB=JLEVEL(2*LN(I,2)-1)
C  BELOW MAY BE NEEDED FOR COMPATIBILITY IN OFF-DIAG CODE
          JA1=JA
          JB1=JB
C  ALLOCATE TEMPORARY STORAGE FOR SR,SI,TR,JBAR,ISTB,NBLK,LVAL
          NSQ=N*N
          NINTS=(N+NIPR-1)/NIPR
          IT1=IXNEXT     ! SR
          IT2=IT1+NSQ    ! SI
          IT3=IT2+NSQ    ! TR
          IT4=IT3+NSQ    ! JBAR
          IT5=IT4+NINTS  ! ISTB
          IT6=IT5+NINTS  ! NBLK
          IT7=IT6+NINTS  ! LVAL
          IXNEXT=IT7+NINTS
          NUSED=0
          CALL CHKSTR(NUSED)
          CALL PRBR3(N,SREAL,SIMAG,JTOT,NSTATE,NQN,JSTATE,NBASIS,
     1               JSINDX,L,NPACK,LN(I,IA),NLVAL,IC,IL,X(IT1),X(IT2),
     2               X(IT3),X(IT4),X(IT5),X(IT6),X(IT7))
C  N.B. ONLY SR,SI NEED TO BE KEPT, IXNEXT COULD BE REDUCED HERE ...
C         IXNEXT=IT3
C>>SG 1 JUN 93: NLVAL1,IL1,IC1 MUST BE ALSO BE SET (CF. DIAGONAL CASE).
          NLVAL1=NLVAL
          DO 3311 II=1,NLVAL
            IL1(II)=IL(II)
 3311       IC1(II)=IC(II)
C<<SG 1 JUN 93
C
 3212     IF (NLVAL.LE.0 .OR. NLVAL1.LE.0) GOTO 3100
C  GET WAVE NUMBER POINTED TO BY IPWVEC (SHOULD BE SAME FOR ALL IC'S)
          IPWVEC=NBASIS(IC(1))
          FK=WVEC(IPWVEC)
          FK=FK/RM
          FK=PI/(FK*FK)
C
C  CHECK FOR AVAILABILITY OF J(BETA) MATRICES WITH WHICH TO CALC.
          IPTR=LN(I,IB+5)
 3400     IF (IPTR.LE.0) GOTO 5000
C
C  PROCESS CURRENT S MATRIX WITH PREVIOUSLY STORED MATRICES.
 4000     IDA=IPTR
C     READ(ILSU,REC=IDA) IPTIND,IIN,IAIN,JTIN,IPTBK,NNTRY
          CALL DARD1(IPTIND,IIN,IAIN,JTIN,IPTBK,NNTRY)
          IDA=IDA+1
          JT(IA)=JTIN
          JT(IB)=JTOT
          IF (LCSNEW) GOTO 4981

          MVALIN=1
          IF (IPTIND.EQ.-1) GOTO 4001

          WRITE(6,402) IPTR,IPTIND
  402     FORMAT(/'  * * * ERROR.  FOR IPTR =',I6,
     &           ', ILLEGAL IPTIND =',I6)
 4003     IPTR=IPTBK
          GOTO 3400

C  'LCSNEW' CODE CAN USE JSTATE(I,1) AS J-VALUE FOR ITYPE=1,2,5,6
 4981     MVALIN = IPTIND+1000
          IF (IABS(MVALIN).LE.JSTATE(LN(I,IB),1)) GOTO 4001

          WRITE(6,405) IPTIND,JA,JB,IA
  405     FORMAT('  * * * ERROR. MVALUE LARGER THAN J-VALUE IN CS(NEW)',
     1           4I12)
          GOTO 4003

 4001     IF (IIN.EQ.I .AND. IAIN.EQ.IB) GOTO 4002

          WRITE(6,403) IIN,I,IAIN,IA
  403     FORMAT(/'  * * * ERROR.  IIN, I, IAIN, IA =',4I12)
          GOTO 4003

 4002     JDIF=JTOT-JTIN
          IF (JDIF.GE.0) GOTO 4004

          WRITE(6,404) JTOT,JTIN
  404     FORMAT(/'  * * * ERROR.  JTOT.LT.JTIN =',2I6)
          GOTO 4003

 4004     IF (JDIF.GT.JDIFMX) GOTO 5000
C
 4005     ONE=1.D0
C  N.B. FOR ITYPE=1,2,5,6,  JSTATE(LEV,NQN)=LEV
          IF (.NOT.LCSNEW) GOTO 4006

C  SET UP FOR NEW COUPLED STATES CODE
          XJA=DBLE(JSTATE(LN(I,IA),1))
          XJB=DBLE(JSTATE(LN(I,IB),1))
          XJA1=DBLE(JSTATE(LN(I,IA+7),1))
          XJB1=DBLE(JSTATE(LN(I,IB+7),1))
          XN=DBLE(LN(I,3))
          XMA=DBLE(MVALUE)
          XMB=DBLE(MVALIN)
C  FACTORS BELOW FOR ITYPE=25,26 MPLMIN=.TRUE.
          TJ2P=1.D0
          F3P=F3PJ
          IF (.NOT.LCSSYM) GOTO 4006

          IXA=LN(I,IA)
          IXA1=LN(I,IA+7)
          IXB=LN(I,IB)
          IXB1=LN(I,IB+7)
          IF (ITYPE.EQ.26) GOTO 4016

          TJ2P=PARSGN(JSTATE(IXB,2)+JSTATE(IXB,3)+
     1                JSTATE(IXB1,2)+JSTATE(IXB1,3))
          F3P=F3P*TJ2P*PARSGN(JSTATE(IXA,2)+JSTATE(IXA,3)+
     1                        JSTATE(IXA1,2)+JSTATE(IXA1,3))
          GOTO 4006

 4016     TJ2P=PRTY(JSTATE(IXB,3)+1)*PRTY(JSTATE(IXB1,3)+1)
          F3P=F3P*TJ2P*PRTY(JSTATE(IXA,3)+1)*PRTY(JSTATE(IXA1,3)+1)
C  FOR OLD CS CODE, ADD 1 TO SREAL ONLY FOR IBLOCK=MP=0.
 4006     DO 3600 ID=1,NNTRY
C     READ(ILSU,REC=IDA) L1,L2,SR,SI
            CALL DARD2(L1,L2,SR,SI)
            IDA=IDA+1
            NMATCH=0
C
C  II LOOPS FOR L1 => INITIAL (UNPRIMED) I.E. JA:IL,IC (COLS)
C  JJ LOOPS FOR L2 => FINAL (PRIMED) I.E. JA1:IL1,IC1  (ROWS)
            DO 3700 II=1,NLVAL
              IF (L1.NE.IL(II)) GOTO 3700
              DO 3800 JJ=1,NLVAL1
                IF (L2.NE.IL1(JJ)) GOTO 3800
                NMATCH=NMATCH+1
                IX=(IC(II)-1)*N+IC1(JJ)
C *** N.B. ABOVE HAS REVERSED ROWS/COLS FROM OLD CODE,
C ***      BUT NOTE SYMMETRY OF S-MATRIX
                SRNOW=SREAL(IX)
                SINOW=SIMAG(IX)
C  THERE SHOULD ONLY BE 1 MATCH.  IF NDEBUG.EQ..FALSE. CHECK THIS.
                IF (NDEBUG) GOTO 4099
 3800         CONTINUE
 3700       CONTINUE
C
 3999       IF (NMATCH-1) 3600,4099,4098
C
 4098       WRITE(6,409) NMATCH,IPTIND,IIN,IAIN,JTIN,IPTBK,NNTRY,L1,L2
  409       FORMAT(/' * * * WARNING. NMATCH.GT.1 =',I3,
     1             '  FOR IPTIND,IIN,IAIN,JTIN,IPTBK,NNTRY,L1,L2 =',8I6)
            GOTO 3600
C
 4099       CONTINUE
            IF (EPM) GOTO 3630

            IF (LCSNEW) GOTO 3640

C  BELOW IS CLOSE COUPLING CODE . . .
            DJA1=JA1+JA1+1
            DJA=JA+JA+1
            F1=DBLE((2*JTOT+1)*(2*JTIN+1)) * SQRT(DJA1/DJA)
C  FOR ITYPE=3 2 INDICES PACKED INTO L1,L2 - REMOVE 2ND.
            L1N=L1-NPACK*(L1/NPACK)
            L2N=L2-NPACK*(L2/NPACK)
C *** JA,JA1 ADDED TO PARITY FACTOR OCT 86 FOR OFF-DIAGONAL CASE.
C ***  C.F. GREEN, C.P.L. 47, 119 (1977); COREY, MCCOURT, AND LIU,
C ***       J. PHYS. CHEM. 88, 2031 (1984).
            PARIT=PARSGN(JA-JA1+L1N-L2N)
            F2=SIXJ(JA,K,L1N,JT(1),JB,JT(2))
C  N.B. DELTA FUNCTION CONTAINS ALL QUANTUM NUMBERS.
C       FOR SOME CASES CODE BELOW RECALCULATES SIXJ
            IF (L1.EQ.L2 .AND. LN(I,1).EQ.LN(I,8) .AND.
     1          LN(I,2).EQ.LN(I,9)) GOTO 3610

            F3=SIXJ(JA1,K,L2N,JT(1),JB1,JT(2))
            FR=0.D0
            GOTO 3620
C
 3610       F3=F2
            FR=ONE
            GOTO 3620
C
C  BELOW FOR EFFECTIVE POTENTIAL METHOD
 3630       F1=2*JTOT+1
            F2=1.D0
            F3=1.D0
            FR=1.D0
            PARIT=1.D0
            GOTO 3620
C
C  BELOW FOR COUPLED STATES (LCSNEW) CASE
 3640       DJA1=JA1+JA1+1
            DJA=JA+JA+1
            F1=DBLE(2*JTOT+1) * SQRT(DJA1/DJA)
            FR=1.D0
            IF (LN(I,1).NE.LN(I,8) .OR. LN(I,2).NE.LN(I,9)) FR=0.D0
            PARIT=PARSGN(JB+JB1)
C  *** ACCOUNT FOR PLUS/MINUS MVALUE COUNTING. . .
C  *** AFTER OCT 76, THIS IS CONTROLLED BY MPLMIN PASSED FROM BASE.
            TJ1=THRJ(XJA ,XJB ,XN,XMA,-XMB,XMB-XMA)
     1         *THRJ(XJA1,XJB1,XN,XMA,-XMB,XMB-XMA)
            F2=TJ1
            F3=1.D0
            IF (.NOT.MPLMIN) GOTO 3620

            TJ2=THRJ(XJA ,XJB ,XN,XMA,XMB,-XMB-XMA)
     1         *THRJ(XJA1,XJB1,XN,XMA,XMB,-XMB-XMA)
            F2=F2 + TJ2 * TJ2P
            F3=1.D0 + F3P
            IF (MVALUE.EQ.0) F3=F3/2.D0
            IF (MVALIN.EQ.0) F3=F3/2.D0
            GOTO 3620

C
 3620       FCT=F1*F2*F3*FK*PARIT
            FR=(FR-(SR*SRNOW+SI*SINOW))*FCT
            FI=P(IA)*(SI*SRNOW-SR*SINOW)*FCT
            SIGR(I)=SIGR(I)+FR
            SIGI(I)=SIGI(I)+FI
            IF (I.NE.IKEEP .AND. IPRINT.GE.4) WRITE(6,602)
  602       FORMAT(1X)
            IKEEP=I
            IF (IPRINT.GE.4) WRITE(6,408) I,JT(IA),JT(IB),FR,SIGR(I),FI,
     1                                    SIGI(I)
  408       FORMAT('  LINE',I3,' BETWEEN JTOT =',I4,' AND',I4,':',E14.6,
     1             ' ADDED TO SIGR =',E14.6,/
     2             37X,E14.6,' ADDED TO SIGI =',E14.6)
 3600     CONTINUE
C  THIS COMPLETES CALC. FOR ALL SAVED S MATRIX ELEMENTS IN THIS SET.
C  FOLLOW POINTERS BACKWARDS TO FIND OTHER S MATRICES.
          IPTR=IPTBK
          GOTO 3400
C
C  NO MORE STORED S MATRICES TO PROCESS.
C  STORE CURRENT MATRIX VALUES FOR FUTURE USE.
C
 5000     NNTRY=NLVAL*NLVAL1
          IF (NEXTDA+NNTRY.LT.MXREC) GOTO 4200

          WRITE(6,401) MXREC
  401     FORMAT(/' *** PRBR. WARNING: TEMPORARY STORAGE OF',I8,
     1           ' WORDS EXCEEDED.'/
     2           ' ***       WRAP-AROUND FEATURE WILL BE USED')
          IF (JTOT-JCHKSV.LE.JDM+1) THEN
            WRITE(6,491)
  491       FORMAT(' *** PRBR. POSSIBLE ERROR')
            WRITE(6,492) JCHKSV,JTOT,JDM
  492       FORMAT(11X,'INITIAL, FINAL JTOT WERE',2I5,'.',
     1             ' NEED  DELTA-JTOT =',I3)
C  ONE MIGHT WANT TO TERMINATE CALCULATION HERE.
          ELSE
            WRITE(6,493)
  493       FORMAT(' *** PRBR. PROBABLY OK.')
            WRITE(6,492) JCHKSV,JTOT,JDM
          ENDIF
          JCHKSV=JTOT
          NEXTDA=1
C
 4200     IPTIND=-1
          IF (LCSNEW) IPTIND=MVALUE-1000
          IPTBK=LN(I,IA+5)
C
C  IDA IS ASSOCIATED VARIABLE, SET TO NEXT AVAILABLE RECORD AFTER
C  READ/WRITE.
          IDA=NEXTDA
C     WRITE(ILSU,REC=IDA) IPTIND,I,IA,JTOT,IPTBK,NNTRY
          CALL DAWR1(IPTIND,I,IA,JTOT,IPTBK,NNTRY)
          IDA=IDA+1
          DO 4100 II=1,NLVAL
          DO 4100 JJ=1,NLVAL1
C  IX IS INDEX TO SREAL, SIMAG. CHANGED FOR OFF-DIAG CODE TO
C  CORRESPOND WITH CHOICE IN DO 3700 LOOP ABOVE
            IX=(IC(II)-1)*N+IC1(JJ)
            L1=IL(II)
            L2=IL1(JJ)
C     WRITE(ILSU,REC=IDA) L1,L2,SREAL(IX),SIMAG(IX)
            CALL DAWR2(L1,L2,SREAL(IX),SIMAG(IX))
 4100       IDA=IDA+1
C
          LN(I,IA+5)=NEXTDA
          NEXTDA=IDA
C  THIS FINISHES PROCESSING LINE=I FOR IA.
C  FOR ITYPE3 RESTORE SREAL,SIMAG AND RELEASE TEMP STORAGE
          IF (ITYPE3) THEN
            CALL PRBR3R(N,SREAL,SIMAG,X(IT1),X(IT2))
C  RELEASE TEMPORARY STORAGE
            IXNEXT=IT1
          ENDIF
C
 3100   CONTINUE
C  THIS ENDS LOOP OVER I = 1,NLINE
 3000 CONTINUE
C  THIS ENDS LOOP OVER IA = ALPHA, BETA.
      RETURN
C * * * * * * * * * * * * * * * * * * * * * * * * * * * * * END OF PRBR
C
C
      ENTRY PRBRIN(NLPRBR,LINE,T,ILSU,NNRG,ENERGY,IFEGEN,
     1             JSTATE,IPRINT)
C
      LDIAG=LDIAGX
      NEXTDA=1
      JDM=0
C  NPACK IS USED TO PACK TWO INDICES (J1,J2) INTO ONE INTEGER VAR.
      NPACK=2**16
      PI=ACOS(-1.D0)
      IF (NLPRBR.GT.0) GOTO 1000

      NOCALC=.TRUE.
      RETURN

 1000 WRITE(6,111)
  111 FORMAT(//'  REVIEW OF REQUESTED PRESSURE BROADENING CALCULATION.')
      WRITE(6,610)
  610 FORMAT(/'  ****** THIS IS OFF-DIAGONAL VERSION (DEC 88) ******')
      IF (LDIAG) WRITE(6,609)
  609 FORMAT(9X,'LDIAG = TRUE OPTION TO HANDLE OLD INPUT')
C  COUPLED STATES (ITYPE=25,26 ADDED OCT 76) / 'OLD' CS CODE REMOVED
      LCSNEW=ITYPE.EQ.21 .OR. ITYPE.EQ.22
      LCSSYM=ITYPE.EQ.25 .OR. ITYPE.EQ.26
      LCSNEW=LCSNEW .OR. LCSSYM
      EPM=ITYPE.EQ.11 .OR. ITYPE.EQ.12 .OR. ITYPE.EQ.15 .OR. ITYPE.EQ.16
      ITYPE3=ITYPE.EQ.3
C  TRAP TYPES INCONSISTENT W/LDIAG=.FALSE.
      IF (LDIAG .OR. .NOT.(ITYPE3 .OR. EPM)) GOTO 1992

      IF (ITYPE3) THEN
        LDIAG=.TRUE.
        WRITE(6,*) '  *** FOR ITYPE=3 LDIAG HAS BEEN FORCED TO TRUE.'
        WRITE(6,*) '  *** CHECK THAT &INPUT LINE DATA IS COMPATIBLE.'
      ELSE
        WRITE(6,197) ITYPE
  197   FORMAT(/'  *** LDIAG=.TRUE. INCOMPATIBLE WITH ITYPE =',I4,';',
     1         ' REQUEST CANCELED.')
        NOCALC=.TRUE.
        RETURN
      ENDIF
 1992 IF (ITYPE.EQ.1 .OR. ITYPE.EQ.2 .OR. ITYPE.EQ.5) GOTO 1990
      IF (ITYPE.EQ.6) GOTO 1990
      IF (ITYPE.EQ.7) GOTO 1990
      IF (ITYPE.EQ.31) GOTO 1990

      IF (ITYPE3 .AND. IDENT.EQ.0) GOTO 1991

      IF (LCSNEW) GOTO 1990
      IF (EPM) GOTO  1990

      WRITE(6,199) ITYPE
  199 FORMAT(/'  * * * WARNING.  REQUESTED PRESSURE BROADENING ',
     1       'CALCULATION  NOT SUPPORTED FOR ITYPE =',I4,'.'/
     2       18X,'REQUEST CANCELLED.')
      NOCALC=.TRUE.
      RETURN

 1991 WRITE(6,198)
  198 FORMAT(/'  * * * WARNING.  LIMITED IMPLEMENTATION FOR PRESSURE ',
     1       'BROADENING WITH ITYPE = 3 .AND. IDENT = 0')
 1990 NOCALC=.FALSE.
C  NPL IS NUMBER OF INDICES PER LINE
      NPL=4
      IF (LDIAG) NPL=2
      WRITE(6,100) NLPRBR,PLUR(MIN(NLPRBR,2))
  100 FORMAT(/'  PRESSURE-BROADENING LINE-SHAPE CALCULATION REQUESTED',
     1       ' FOR',I4,' LINE',A1)
C  N.B. DIMENSION OF LINE PASSED FROM DRIVER IS 2*MXLN
      IF ((NPL*NLPRBR)/2.LE.MXLN) GOTO 1100

      I=(2*MXLN)/NPL
      WRITE(6,101) NLPRBR,I
  101 FORMAT(/'  * * * WARNING. ',I5,' LINES REQUESTED, REDUCED TO MAX',
     1       ' OF',I3)
      NLPRBR=I
 1100 WRITE(6,110)
  110 FORMAT(/5X,' LINE   LEV(A) LEV(B)  LEV(A1) LEV(B1)')
      DO 1103 I=1,NLPRBR
        IST=NPL*(I-1)
 1103   WRITE(6,112) I,(LINE(IST+II),II=1,NPL)
  112   FORMAT(5X,I4,I8,I6,I9,I7)
      NLINE=0
      NEWE=NNRG
      DO 1200 I=1,NLPRBR
        PF=.FALSE.
        L1=LINE((NPL*(I-1))+1)
        L2=LINE((NPL*(I-1))+2)
        IF (LDIAG) GOTO 1104

        L3=LINE((NPL*(I-1))+3)
        L4=LINE((NPL*(I-1))+4)
        GOTO 1105

 1104   L3=L1
        L4=L2
 1105   IF (EXISTS(L1) .AND. EXISTS(L2) .AND. EXISTS(L3) .AND.
     1      EXISTS(L4)) GOTO 1150
        WRITE(6,108) L1,L2,L3,L4
  108   FORMAT(/'  * * * WARNING.  REQUESTED LINE FOR LEVELS',4I4,
     1         '  CANNOT BE PROCESSED - OUTSIDE NSTATE RANGE.')
        GOTO 1200

 1150   IF (ITYPE3) GOTO 1151

C  FOR ITYPE=1,2,5 TAKE J-VALUE FROM JSTATE(LEV,1)
        JA=JSTATE(L1,1)
        JB=JSTATE(L2,1)
        JA1=JSTATE(L3,1)
        JB1=JSTATE(L4,1)
        GOTO 1152

C  FOR ITYPE=3 TAKE J-VALUES FROM JLEVEL.  RECALL J1,J2 PACKED.
 1151   JA=JLEVEL(2*L1-1)
        JB=JLEVEL(2*L2-1)
        JA1=JA
        JB1=JB
 1152   K=T(I)
        K1=K
        IF (K.GE.0) GOTO 1106

C  IF 'LTYPE' NOT INPUT, CALCULATE FROM J-VALUES
        K=IABS(JA-JB)
        K1=IABS(JA1-JB1)
C  OTHER THAN DIPOLE AND RAMAN (Q=0,2) TRANSITIONS NOT IMPLEMENTED.
C  ALSO, MUST HAVE SAME 'K' FOR JA/JB AND JA1/JB1
 1106   IF ((K.EQ.0 .OR. K.EQ.1 .OR. K.EQ.2) .AND. (K.EQ.K1)) GOTO 1300

        WRITE(6,102) JA,JB,JA1,JB1,I
  102   FORMAT(/'  * * * *  ONLY DIPOLE AND RAMAN TRANSITIONS '
     1         'IMPLEMENTED.  CANNOT PROCESS JA,JB,JA1,JB1=',4I4/
     2         10X,'SPECIFY LTYPE(',I3,' ) = 0, 1 OR 2 IN &INPUT.')
        GOTO 1200

 1300   NEPL=0
        IF (IFEGEN.LE.0) GOTO 1301

C  GENERATE ENERGY VALUES IF NECESSARY TO LINE AT REQUESTED E'S.
        DO 1401 II=1,NNRG
          EA=ENERGY(II)+ELEVEL(L1)
          DO 1501 JJ=1,NEWE
            ED=(ENERGY(JJ)-EA)/ENERGY(JJ)
            IF (ABS(ED).GT.EDIFMX) GOTO 1501

            JL=JJ
            GOTO 1502

 1501     CONTINUE
          NEWE=NEWE+1
          IF (NEWE.LT.MXNRG) GOTO 1201

 1202     WRITE(6,611) I,II
  611     FORMAT(/'  * * * WARNING.  CANNOT ADD ENERGY VALUE FOR LINE',
     1           I4,'  RELATIVE ENERGY NO.',I4)
          NEWE=NEWE-1
          GOTO 1401

 1201     ENERGY(NEWE)=EA
          JL=NEWE
 1502     EB=ENERGY(II)+ELEVEL(L2)
          DO 1101 JJ=1,NEWE
            ED=(ENERGY(JJ)-EB)/ENERGY(JJ)
            IF (ABS(ED).GT.EDIFMX) GOTO 1101

            JK=JJ
            GOTO 1102

 1101     CONTINUE
          NEWE=NEWE+1
          IF (NEWE.GE.MXNRG) GOTO 1202

          ENERGY(NEWE)=EB
          JK=NEWE
 1102     NEPL=NEPL+1
          IF (NLINE.LT.MXLN) GOTO 1108

          WRITE(6,109) L1,L2,L3,L4,JL,JK
          GOTO 1200

 1108     NLINE=NLINE+1
          LN(NLINE,1)=L1
          LN(NLINE,2)=L2
          LN(NLINE,3)=K
          LN(NLINE,4)=JL
          LN(NLINE,5)=JK
          LN(NLINE,6)=0
          LN(NLINE,7)=0
          LN(NLINE,8)=L3
          LN(NLINE,9)=L4
          SIGR(NLINE)=0.D0
          SIGI(NLINE)=0.D0
          EREL(NLINE)=ENERGY(II)
          IF (PF) GOTO 1601

          WRITE(6,103) L1,JA,L2,JB,L3,JA1,L4,JB1,PTP(K+1)
          PF=.TRUE.
 1601     SFX(1)=ORDNL(JL)
          SFX(2)=ORDNL(JK)
          WRITE(6,104) EREL(NLINE),JL,SFX(1),JK,SFX(2)
 1401   CONTINUE
        GOTO 1403
C
C  CHECK FOR AVAILABLE PAIRS OF ENERGIES WITH SAME INITIAL REL KE
C
 1301   DO 1400 II=1,NNRG
          EA=ENERGY(II)-ELEVEL(L1)
C *** 2 SEPT. 86 TO PREVENT CHOOSING NEGATIVE ENERGIES
          IF (EA.LE.0.D0) GOTO 1400

          DO 1500 JJ=1,NNRG
            EB=ENERGY(JJ)-ELEVEL(L2)
            ED=(EA-EB)/MAX(EA,EB,1.D0)
            IF (ABS(ED).GT.EDIFMX) GOTO 1500

            NEPL=NEPL+1
            IF (NLINE.LT.MAXLN) GOTO 1109

            WRITE(6,109) L1,L2,L3,L4,II,JJ
  109       FORMAT(/'  * * * WARNING.  NO MORE TABLE SPACE FOR '
     1             'LEVELS =',4I3,', AND ENERGIES=',2I4,
     2             ';   WILL BE SKIPPED.')
            GOTO 1200

 1109       NLINE=NLINE+1
            LN(NLINE,1)=L1
            LN(NLINE,2)=L2
            LN(NLINE,3)=K
            LN(NLINE,4)=II
            LN(NLINE,5)=JJ
            LN(NLINE,6)=0
            LN(NLINE,7)=0
            LN(NLINE,8)=L3
            LN(NLINE,9)=L4
            SIGR(NLINE)=0.D0
            SIGI(NLINE)=0.D0
            EREL(NLINE)=(EA+EB)/2.D0
            IF (PF) GOTO 1600

            WRITE(6,103) L1,JA,L2,JB,L3,JA1,L4,JB1,PTP(K+1)
  103       FORMAT(/'  LEVELS',I3,' (JA =',I3,' ), ',I3,' (JB =',I3,
     1             ' ) **TO** LEVELS',I3,' (JA1 =',I3,' ),',I3,
     1             ' (JB1 =',I3,' ) WILL BE PROCESSED FOR',A8,
     1             'RADIATION.')
            PF=.TRUE.
 1600       WRITE(6,*) LN(NLINE,4),MOD(LN(NLINE,4),10),
     1                 MIN(MOD(LN(NLINE,4),10),4)
            WRITE(6,104) EREL(NLINE),
     1                   LN(NLINE,4),ORDNL(LN(NLINE,4)),
     2                   LN(NLINE,5),ORDNL(LN(NLINE,5))
  104       FORMAT(12X,'AT RELATIVE K.E. =',F18.9,' CM-1  WITH',I4,
     1             '-',A2,' AND',I4,'-',A2,
     2             ' ENERGY VALUES RESPECTIVELY.')
 1500     CONTINUE
 1400   CONTINUE
 1403   IF (NEPL.GT.0) GOTO 1200

        WRITE(6,105) L1,L2
  105   FORMAT(/'  * * * WARNING. NO RELEVANT PAIRS OF ENERGY VALUES ',
     1         'FOR REQUESTED LEVELS =',2I4)
 1200 CONTINUE
C
      IF (IFEGEN.LE.0) GOTO 1701
C
C  REMOVE ENERGIES THAT ARE NOT NEEDED FOR PRESSURE-BROADENING
      NNRG=NEWE
      II=1
 1609 IF (II.GT.NNRG) GOTO 1615

      DO 1610 I=1,NLINE
        IF (LN(I,4).EQ.II .OR. LN(I,5).EQ.II) THEN
C  WE ARE USING THIS ENERGY. CHECK THE NEXT
          II=II+1
          GOTO 1609

        ENDIF
 1610 CONTINUE
C  REACH HERE IF IT IS NOT USED.  COMPRESS LIST & REVISE INDEXES
      NNRG=NNRG-1
      DO 1611 JJ=II,NNRG
        ENERGY(JJ)=ENERGY(JJ+1)
 1611 CONTINUE
      DO 1612 I=1,NLINE
        IF (LN(I,4).GT.II) LN(I,4)=LN(I,4)-1
 1612   IF (LN(I,5).GT.II) LN(I,5)=LN(I,5)-1
      GOTO 1609
C
C  SORT ENERGIES INTO DESCENDING ORDER, RENUMBER LN(,4) AND LN(,5)
C
 1615 DO 1809 JJ=1,NNRG
        II=0
        ETOP=0.D0
        DO 1805 I=JJ,NNRG
          IF (ETOP.GE.ENERGY(I)) GOTO 1805
          ETOP=ENERGY(I)
          II=I
 1805   CONTINUE
        ENERGY(II)=ENERGY(JJ)
        ENERGY(JJ)=ETOP
        DO 1808 I=1,NLINE
          KK=LN(I,4)
          IF (KK.EQ.JJ) LN(I,4)=II
          IF (KK.EQ.II) LN(I,4)=JJ
          KK=LN(I,5)
          IF (KK.EQ.JJ) LN(I,5)=II
 1808     IF (KK.EQ.II) LN(I,5)=JJ
 1809 CONTINUE
      WRITE(6,612) NNRG,PLUR(MIN(NNRG,2)),(I,ENERGY(I),I=1,NNRG)
  612 FORMAT(//'  MODIFIED ENERGY LIST NOW CONTAINS',I4,'  VALUE',A1
     1       /(15X,'ENERGY(',I3,') =',F18.9))
      WRITE(6,921)
  921 FORMAT(/'  LINE-SHAPE TABLES HAVE BEEN MODIFIED ACCORDINGLY.')
 1701 IF (NLINE.GT.0) GOTO 1700
      WRITE(6,106)
  106 FORMAT(/'  * * * WARNING. NONE OF REQUESTED LINES CAN BE ',
     1       'PROCESSED.  REQUEST CANCELLED.')
      NOCALC=.TRUE.
      RETURN

C  CODE FOR IN-CORE ROUTINES REPLACES OLDER CODE BELOW
 1700 CALL DAOPEN
      CALL DASIZE(ILSU,MXREC)
      RETURN
C1700 IF (ILSU.LE.0) GOTO 1900
C
C  OLD CODE FOR OPENING PRESSURE BROADENING SCRATCH FILE.
C  THIS IS NOW REPLACED BY IN-CORE STORAGE (JUN 92).
C  THE APPROPRIATE RECORD LENGTH IS MACHINE-DEPENDENT, AND
C  MUST BE SUFFICIENT TO STORE 6 INTEGERS. FOR EXAMPLE:
C
C     IBM:   LREC = 24 (BYTES)
C     VAX:   LREC =  6 (LONGWORDS)
C     CRAY:  LREC = 48 (BYTES)
C
C     LREC=24
C     OPEN(ILSU,STATUS='SCRATCH',ACCESS='DIRECT',FORM='UNFORMATTED',
C    1     RECL=LREC,ERR=1900)
C
C1900 WRITE(6,107) ILSU
C 107 FORMAT(/'  * * * WARNING.  UNABLE TO OPEN DIRECT ACCESS FILE ON ',
C    1       'CHANNEL',I3,'.  REQUESTED LINE-SHAPE CALCULATION ',
C            'CANCELLED.')
C     NOCALC=.TRUE.
C     RETURN
C     IF (ILSU.LE.100) WRITE(6,200) ILSU
C 200 FORMAT(/'  LINE SHAPE CALCULATION USES DIRECT ACCESS FILE ON ',
C    1       'CHANNEL',I4,' FOR TEMPORARY STORAGE')
C     RETURN
C
C * * * * * * * * * * * * * * * * * * * * * * * * * * * * END OF PRBRIN
C
      ENTRY PRBCNT(INRG,JSINDX,N,IUSE)
C
C  SEE WHETHER THIS S-MATRIX WILL CONTRIBUTE TO ANY OF THE LINES
C  REQUESTED: IUSE=1 MEANS THAT IT WILL.
C
C  THIS CODE MAY NOT WORK FOR DIATOM-DIATOM: BE CAUTIOUS FOR NOW
      IF (ITYPE3) GOTO 5920
C
      DO 5910 I=1,NLINE
      DO 5910 IA=1,2
        IF (LN(I,IA+3).NE.INRG) GOTO 5910

        DO 5908 II=1,N
          L1=JSINDX(II)
          IF (L1.EQ.LN(I,IA) .OR. L1.EQ.LN(I,IA+7)) GOTO 5920

 5908   CONTINUE
 5910 CONTINUE
      IUSE=0
      RETURN
C
 5920 IUSE=1
      RETURN
C
C * * * * * * * * * * * * * * * * * * * * * * * * * * * * END OF PRBCNT
C
      ENTRY PRBOUT(JTSTEP,JTOT)

      IF (NOCALC) RETURN

      IF (JTOT.NE.-99999) THEN
        WRITE(6,671) JTOT
  671   FORMAT(/'  ACCUMULATED PRESSURE-BROADENING CROSS SECTIONS',
     1         ' (IN ANG**2) FOR JTOT =',I5)
      ELSE
        WRITE(6,674)
  674   FORMAT(/'  TOTAL ACCUMULATED PRESSURE-BROADENING CROSS',
     1         ' SECTIONS (IN ANG**2)')
      ENDIF
      FACTJ=1.D0
      IF (JTSTEP.GT.1) THEN
        FACTJ=DBLE(JTSTEP)/DBLE(JHALF)
        WRITE(6,672) FACTJ
  672   FORMAT(/'  *** NOTE *** CROSS SECTIONS MULTIPLIED BY',F5.1,
     1         ' TO ACCOUNT FOR JTSTEP')
      ENDIF
      WRITE(6,673)
  673 FORMAT(/'  LINE LEV(A) LEV(B) LEV(A1) LEV(B1)  TYPE',8X,
     1       'EREL (CM-1)',11X,'RE(S)',12X,'IM(S)')
C
      DO 6996 I=1,NLINE
        SIGRJS=SIGR(I)*FACTJ
        SIGIJS=SIGI(I)*FACTJ
 6996   WRITE(6,601) I,LN(I,1),LN(I,2),LN(I,8),LN(I,9),
     1               PTP(LN(I,3)+1),EREL(I),SIGRJS,SIGIJS
  601   FORMAT(2I5,2I7,I8,3X,A8,F18.9,1P,2E17.6)

      RETURN
      END
