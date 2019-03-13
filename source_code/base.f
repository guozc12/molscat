      SUBROUTINE BASE(JTOT, JSTATE, N, JSINDX, L, CM2RU,
     1                EINT, CENT, VL, IV, MXLAM, NPOTL,
     2                LAM, WVEC, WGHT, IEXCH, THETA, PHI, ICODE,
     3                LCOUNT, ERED, NLEVV, IPRINT, IBOUND, ATAU,
     4                DGVL)
C  Copyright (C) 2019 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      USE efvs, ONLY: NEFV, MAPEFV
      USE potential
      USE basis_data
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      SAVE
      logical :: inolls=.false.
C
C  BASE HANDLES QUANTUM BASIS SETS FOR SCATTERING CALCULATION.
C
C  ITYPE DESCRIBES INTERACTION TYPES.
C  CURRENT IMPLEMENTATION FOR
C       ITYPE=1    LINEAR RIGID ROTOR - ATOM
C       ITYPE=2    DIATOMIC VIB-ROTOR - ATOM
C       ITYPE=3    LINEAR RIGID ROTOR - LINEAR RIGID ROTOR
C       ITYPE=4    RIGID ASYMMETRIC TOP - LINEAR RIGID ROTOR
C       ITYPE=5    NEAR-SYMMETRIC TOP RIGID ROTOR - ATOM
C       ITYPE=6    ASYMMETRIC TOP RIGID ROTOR - AN ATOM.
C       ITYPE=7    DIATOMIC VIB-ROTOR - ATOM, WHERE A FULL
C                  SET OF EXPECTATION VALUES OF THE INTERMOLECULAR
C                  POTENTIAL BETWEEN (V,J) AND (V',J') DIATOM INTERNAL
C                  STATES IS SUPPLIED
C       ITYPE=8    ATOM - SURFACE ELASTIC (DIFFRACTIVE) SCATTERING
C
C       ITYPE=ITYPE+10 FOR EFFECTIVE POTENTIAL METHOD OF RABITZ.
C       ITYPE=ITYPE+20 FOR COUPLED STATES OF MCGUIRE-KOURI.
C       ITYPE=ITYPE+30 FOR DLD METHOD OF DEPRISTO AND ALEXANDER.
C
C
C  ENTRY BASIN
C    READS AND PROCESSES &BASIS DATA TO DESCRIBE ASYMPTOTIC LEVELS.
C    QUANTUM NOS. AND INDEXING ARE IN JLEVEL(NLEVEL) AND
C      JSTATE(NSTATE,NQN), IN DIFFERENT FORMATS.
C      ASYMPTOTIC ENERGIES ARE IN ELEVEL(NLEVEL).
C
C  MAIN ENTRY BASE
C    SETS UP BASIS FOR EACH PARTIAL CALCULATION FROM ASYMPTOTIC
C    LEVELS (STORED IN JSTATE) COUPLED WITH INTERACTION ORBITAL ANGULAR
C    MOMENTUM.
C    LCOUNT=.TRUE.  MEANS ONLY COUNT NUMBER OF CHANNELS
C    LCOUNT=.FALSE. MEANS SET UP BASIS FUNCTIONS IN ALLOCATED STORAGE.
C    ICODE (=1...MXPAR) IS AN INDEX FOR THE CURRENT SYMMETRY BLOCK.
C    IPAR AND IEXCH SUBDIVIDE ICODE=1,MXPAR INTO
C         1) PARITY, IPAR=0 (EVEN), 1 (ODD)
C         2) EXCHANGE SYM., IEXCH=0 (NO EXCHANGE), 1 (ODD), 2 (EVEN).
C    IT IS NECESSARY TO SET FOLLOWING --
C         ASYMPTOTIC LEVEL IN JSINDX, ORBITAL ANGULAR MOMENTUM IN L,
C         ASYMPTOTIC ENERGY IN EINT, CENTRIFUGAL ENERGY IN CENT,
C         AND COUPLING MATRIX ELEMENTS IN VL.
C
C      EXTRA FEATURE ADDED AT UNIV. OF WATERLOO MAY 82. ARRAY IV
C      IS AN INDEX ARRAY SUCH THAT VL(I) IS A COEFFICIENT FOR
C      TERM NUMBER IV(I) IN THE POTENTIAL ARRAY RETURNED BY
C      SUBROUTINE POTENL. THE INTRODUCTION OF THIS ARRAY ONLY
C      MAKES ANY REAL DIFFERENCE FOR ITYPE=10*N+7, FOR WHICH IT
C      ENABLES LARGE ECONOMIES IN STORAGE FOR THE VL ARRAY.
C      ** 1/27/93 IV ARRAY USED IF AND ONLY IF IVLFL.GT.0 **
C      NPOTL IS THE NUMBER OF "CHUNKS" OF SIZE N*(N+1)/2 WHICH
C      COMPRISE VL AND IV. NPOTL=MXLAM EXCEPT FOR ITYPE=10*N+7 AND 8.
C      FOR ITYPE=10*N+7, NPOTL IS EQUAL TO K+1, WHERE K IS THE
C      INDEX OF THE HIGHEST ORDER LEGENDRE POLYNOMIAL ACTUALLY
C      PRESENT IN THE POTENTIAL.
C      FOR ITYPE=8, NPOTL=1.
C
C      ADDITIONAL CHANGE MADE MAY 82. THE VL ARRAY IS NOW STORED
C      SO THAT THE POTENTIAL SYMMETRY TERM IS MOST RAPIDLY VARYING,
C      RATHER THAN THE CHANNEL INDICES AS BEFORE. THIS IS TO KEEP
C      PAGING TO A MINIMUM IN SUBROUTINE WAVMAT.
C
C      CODE ADDED FOR BCT HAMILTONIAN SET 2016
C
C  ENTRY DEGEN PROVIDES DEGENERACY INFORMATION FOR USE IN OUTPUT.
C
      DIMENSION CENT(NLEVV),EINT(NLEVV),WVEC(NLEVV),VL(NLEVV),IV(NLEVV)
      DIMENSION ATAU(*),DGVL(*)
      LOGICAL LCOUNT,EIN,LEVIN,MPLMIN,LSIG,BCT
      INTEGER JSINDX(NLEVV),L(NLEVV),LAM(MXLAM),JSTATE(NLEVV)
      INTEGER IPRINT,EUNITS
      CHARACTER(8) QNAME(10),QTYPE(10),PRTP(4,9),PTP(2),EUNAME
      CHARACTER(2) CNQN,CLEN2
      CHARACTER(170) F640,F650,F660,CPQN1,CPQN2,CPQN3
      CHARACTER(10) NAME1,NAME2,CHAS,CHTH
      CHARACTER(1) PLUR(2)
      DATA PLUR/' ','S'/
      DIMENSION WTM(2),IOSNGP(3)
C
C     include common block for data received via pvm
C
cINOLLS include 'all/pvmdat1.f'
cINOLLS include 'all/pvmdat.f'
C
C  DYNAMIC STORAGE COMMON BLOCK ...
      COMMON /MEMORY/ MX,IXNEXT,NIPR,IDUMMY,X(1)
      COMMON /VLFLAG/ IVLFL
C
      COMMON /PRBASE/ ITYPX,NQN,NSTATE,MVALUE,IPTY,MPLMIN
C
      COMMON /VLSAVE/ IVLU
C
C  ARRAYS FOR NAMELIST &BASIS
C     CHARACTER(6) BNAMES(39)
C     DIMENSION LOCN(39),INDX(39)
C
C  V14: ISYM2, JHALF ADDED TO NAMELIST
C  2017: DJ, DJK, DK, DT (CENTRIFUGAL DISTORTION CONSTANTS) ADDED TO
C        NAMELIST
      NAMELIST /BASIS/ A,     ALPHAE,B,     BCT,   BE,    C,
     1                 DE,    DJ,    DJK,   DK,    DT,    ELEVEL,
     2                 EMAX,  EMAXK, EUNITS,EUNAME,EUNIT, IASYMU,IBOUND,
     3                 IDENT, IPHIFL,IOSNGP,ISYM,  ISYM2, ITYPE, IVLU,
     4                 J1MAX, J1MIN, J1STEP,J2MAX, J2MIN, J2STEP,
     5                 JHALF, JLEVEL,JMIN,  JMAX,  JSTEP, JZCSFL,
     6                 JZCSMX,KMAX,  KSET,  NLEVEL,ROTI,  SPNUC,
     7                 WE,    WEXE,  WT
C
      DATA QTYPE/ '     J  ', '     K  ',
     1            '   PRTY ', '    J1  ','    J2  ','   J12  ',
     2            '     V  ', '   TAU  ','        ','SIG INDX'/
      DATA PRTP/'  LINEAR',' RIGID R','OTOR  - ',' ATOM.  ',
     2          '  DIATOM','IC VIB-R','OTOR  - ',' ATOM.  ',
     3          '  LINEAR',' ROTOR -',' LINEAR ','ROTOR.  ',
     4          '  ASYMME','TRIC TOP',' - LINEA','R ROTOR.',
     5          'ATOM - N','EAR SYM.',' TOP RIG','ID ROTOR',
     6          '  ASYMME','TRIC TOP',' - ATOM ','        ',
     7          4*' ',
     8          '  ATOM -',' CORRUGA','TED SURF','ACE     ',
     9          4*' '/
      DATA PTP/', (ODD  ',', (EVEN '/
C
C  SET UP BASIS FUNCTIONS
C
      IEXCH=0
      IPAR=0
C
      IF (ITYPE.EQ.8)  GOTO 5208
      IF (ITP.EQ.9)    GOTO 5209
      IF (ITYPE.LE.10) GOTO 5201
      IF (ITYPE.LE.20) GOTO 5202
      IF (ITYPE.LE.30) GOTO 5203
C
C  CODE FOR DECOUPLED L-DOMINANT APPROX OF ALEXANDER
C
 5204 N=0
      LDLD=ICODE-1
      DO 4001 I=1,NSTATE
        JI=JSTATE(I)
        LI=JTOT+LDLD-JI
        IF (LI.LT.ABS(JTOT-JI) .OR. LI.GT.(JTOT+JI) ) GOTO 4001
        N=N+1
        IF (LCOUNT) GOTO 4001
        JSINDX(N)=I
        L(N)=LI
 4001 CONTINUE
      IF (LCOUNT) GOTO 5000

      GOTO 8000
C
C  CODE BELOW FOR MCGUIRE-KOURI J-Z CONSERVING COUPLED STATES APPROX.
C
 5203 N=0
C>SG  CODE BELOW IS REVISED APR 94 -- NEW ORDERING OF SYMMETRY BLOCKS
      IF (MPLMIN) THEN
        IF (IDENT.EQ.0) THEN
          MVALUE=ICODE-1
          IF (ITYPE.EQ.25) THEN
            IBLOCK=MVALUE/(MJMX+1)
            MVALUE=MOD(MVALUE,MJMX+1)
            IF (ISYM(1).NE.-1) THEN
              KREQ=MOD(IBLOCK,ISYM(1))
              IBLOCK=IBLOCK/ISYM(1)
              IF (LCOUNT .AND. IPRINT.GE.3) WRITE(6,691) ISYM(1),KREQ
  691         FORMAT('  ISYM(1)=',I1,': LEVELS WITH K .NE.',I2,
     1               ' EXCLUDED FROM BASIS SET FOR THIS SYMMETRY BLOCK')
            ENDIF
            IF (ISYM(2).NE.-1) THEN
              JSUM=IBLOCK
              IF (LCOUNT .AND. IPRINT.GE.3) WRITE(6,692) JSUM
  692         FORMAT('  ISYM(2).NE.-1: LEVELS WITH MOD(J+K+PRTY,2).NE.',
     1               I1,' EXCLUDED FROM BASIS SET FOR THIS SYMMETRY',
     2               ' BLOCK')
            ENDIF
          ENDIF
        ELSE
          IEXCH=2-MOD(ICODE,2)
          MVALUE=(ICODE+1)/2-1
          IF (WT(IEXCH).EQ.0.D0) THEN
            IF (IPRINT.GE.3) WRITE(6,690) JTOT,ICODE,PTP(IEXCH)
            GOTO 5000

          ENDIF
        ENDIF
      ELSE
C  CODE BELOW IS FOR MPLMIN=.FALSE. (NOT USED, BUT COULD BE REVIVED)
        IF (IDENT.EQ.0) THEN
          WRITE(6,*) ' *** BASE (APR 94). MPLMIN=.FALSE. .AND. IDENT.'
     1               ,'EQ.0 ARE NOT ALLOWED'
          STOP
        ELSE
          ICD=(ICODE+1)/2
          MVALUE=ICD/2
          IF (ICD-2*(ICD/2).EQ.0) MVALUE=-MVALUE
        ENDIF
      ENDIF
C  SET IPAR (=1 FOR MVALUE=0, =2 OTHERWISE)
      IPAR=1
      IF (MVALUE.NE.0) IPAR=2
C<SG  END OF APR 94 REVISIONS
      DO 5221 I=1,NSTATE
C  SKIP IF J.LT.MVALUE OR EXCLUDED BY EXCHANGE SYMMETRY.
        J1VAL=JSTATE(I)
        J2VAL=JSTATE(NSTATE+I)
        J12VAL=JSTATE(2*NSTATE+I)
        IF (JSTATE(IOFF+I).LT.ABS(MVALUE)) GOTO 5221
        IF ((IBOUND.NE.0 .OR. JZCSFL.NE.0) .AND. JTOT.LT.ABS(MVALUE))
     1    GOTO 5221
        IF (IDENT.NE.0 .AND. J1VAL.EQ.J2VAL .AND.
     1    PARSGN(IEXCH+J12VAL+JTOT+JZCSFL*JSTATE(IOFF+I)).LE.0.D0)
     2    GOTO 5221
        IF (ITYPE.EQ.25) THEN
          IF (ISYM(1).NE.-1 .AND. J2VAL.NE.KREQ) GOTO 5221
          IF (ISYM(2).NE.-1 .AND. MOD(J1VAL+J2VAL+J12VAL,2).NE.JSUM)
     1      GOTO 5221
        ENDIF
        N=N+1
        IF (LCOUNT) GOTO 5221
        JSINDX(N)=I
        L(N)=ABS(JTOT+JZCSFL*(JSTATE(IOFF+I)-2*ABS(MVALUE)))
C  SPECIAL CASE FOR BOHN-CAVAGNERO-TICKNOR HAMILTONIAN FOR DIPOLES
C  USING DIATOM J QUANTUM NUMBER HERE FOR PHYSICAL L
        IF (BCT) L(N)=JSTATE(IOFF+I)
 5221 CONTINUE
      IF (LCOUNT) GOTO 5000

      CALL MCGCPL(N,MXLAM,NPOTL,LAM,NSTATE,JSTATE,JSINDX,L,MVALUE,ITYPE,
     1            IEXCH,VL,IV,IPRINT,ATAU)
      GOTO 8888
C
C
C  CODE BELOW IS FOR RABITZ' EFFECTIVE POTENTIAL METHOD
C  HERE EACH 'STATE' IS A BASIS FUNCTION AND JTOT=0
C
 5202 N=0
      IF (IDENT.EQ.0) GOTO 8001
      IEXCH=ICODE
      IF (WT(IEXCH).NE.0.D0) GOTO 8001
      IF (IPRINT.GE.3) WRITE(6,690) JTOT,ICODE,PTP(IEXCH)
  690 FORMAT(' ***'/
     1       ' *** NOTE.  JTOT =',I4,'.  BLOCK ',I2,A8,
     2       'EXCHANGE) SKIPPED BECAUSE  WEIGHT = 0.0'/' ***')
      GOTO 5000

 8001 DO 5210 I=1,NSTATE
        IF (IDENT.NE.0 .AND. JSTATE(I).EQ.JSTATE(NSTATE+I) .AND.
     1      PARSGN(IEXCH+JTOT).LE.0.D0) GOTO 5210
        N=N+1
        IF (LCOUNT) GOTO 5210
        JSINDX(N)=I
        L(N)=JTOT
 5210 CONTINUE
      IF (LCOUNT) GOTO 5000

      GOTO 8000
C
C
C  CODE BELOW OF AUG 74 IS UNIFIED ITYPE (EXCEPT 8 & 9) CODE.
C  N.B. BASIS FUNCTIONS ARE ORDERED ON L AS IN GORDON'S CODE.
C
 5201 N=0
      IPTY=ICODE-2*(ICODE/2)
      IF (IDENT.EQ.0) GOTO 8002

      IEXCH=(ICODE+1)/2
      IF (WT(IEXCH).NE.0.D0) GOTO 8002

      IF (IPRINT.GE.3) WRITE(6,690) JTOT,ICODE,PTP(IEXCH)
      GOTO 5000

 8002 LMAX=JTOT+JMAX
C  SPECIAL CASE TO LIMIT LMAX BY INPUT ISYM2(1)
      IF (ISYM2(1).GE.0) LMAX=MIN(LMAX,ISYM2(1))
      LMIN=JTOT-JMAX
      IF (LMIN.GE.0) GOTO 4101

      LMIN=JMIN-JTOT
      IF (LMIN.LT.0) LMIN=0
 4101 DO 4201 LI=LMIN,LMAX
        JK=ABS(JTOT-LI)
        JTOP=JTOT+LI
      DO 4201 I=1,NSTATE
C
        IF (IGO.EQ.9001) THEN
          JI=JSTATE(I)
          LPJ=LI+JI+JTOT
        ELSEIF (IGO.EQ.9003) THEN
          JI=JSTATE(2*NSTATE+I)
C  FOR IDENTICAL PARTICLES SKIP IMMEDIATELY IF FUNCTION VANISHES.
          IF (IDENT.NE.0 .AND. JSTATE(I).EQ.JSTATE(NSTATE+I) .AND.
     1        PARSGN(IEXCH+JI+LI).LE.0.D0) GOTO 4201

          LPJ=JSTATE(I)+JSTATE(NSTATE+I)+LI+JTOT
        ELSEIF (IGO.EQ.9004) THEN
          JI = JSTATE(I)
          JAY1 = JSTATE(2*NSTATE + I)
          JAY2 = JSTATE(NSTATE + I)
          LPJ = JSTATE(4*NSTATE + I)
C  LINE BELOW CORRECTED 1 NOV 94 BY SG
          LPJ = LPJ + LPJ/2 + JAY1 + JAY2 + LI + JTOT
        ELSEIF (IGO.EQ.9005) THEN
          JI=JSTATE(I)
          LPJ=JI+JSTATE(I+NSTATE)+JSTATE(I+2*NSTATE)+LI+JTOT
C  FOR SYMMETRIC TOP WITH ISYM(1) OPTION, SKIP IF THIS K NOT WANTED
          IBLOCK=(ICODE-1)/2
          IF (ISYM(1).NE.-1) THEN
            KREQ=MOD(IBLOCK,ISYM(1))
            IF (JSTATE(NSTATE+I).NE.KREQ) GOTO 4201

            IBLOCK=IBLOCK/(ISYM(1))
          ENDIF
C  FOR SYMMETRIC TOP WITH ISYM(2) OPTION, SKIP IF THIS PAR NOT WANTED
          IF (ISYM(2).NE.-1) THEN
            JSUM=IBLOCK
            IF (MOD(JI+JSTATE(NSTATE+I)+JSTATE(2*NSTATE+I),2).NE.JSUM)
     &        GOTO 4201

          ENDIF
        ELSEIF (IGO.EQ.9006) THEN
          JI=JSTATE(I)
          LPJ=JSTATE(2*NSTATE+I)
          LPJ=LPJ+LPJ/2+JI+LI+JTOT
        ENDIF
C
 4005   IF ( (LPJ-2*(LPJ/2)).NE.IPTY) GOTO 4201
        IF (JI.LT.JK .OR. JI.GT.JTOP) GOTO 4201

        N=N+1
        IF (LCOUNT) GOTO 4201

        JSINDX(N)=I
        L(N)=LI
 4201 CONTINUE

      IF (LCOUNT) GOTO 5000

      GOTO 8000
C
 5209 CALL BASE9(LCOUNT,N,JTOT,ICODE,JSTATE,NSTATE,NQN,JSINDX,L,IPRINT)
      IF (IVLFL.EQ.0) NPOTL=MXLAM+NCONST+NRSQ
      IF (LCOUNT) GOTO 5000

      CALL CPL9(N,ICODE,NPOTL,LAM,MXLAM,NSTATE,JSTATE,JSINDX,L,JTOT,
     1          VL,IV,CENT,DGVL,IBOUND,IEXCH,IPRINT)
      GOTO 8888
C
C * * BASIS FUNCTIONS ARE NOW SET-UP IN JSINDX(I), L(I), I=1,N.
C
C  STORE MATRIX ELEMENTS OF THE COUPLING POTENTIAL IN VL.
 8000 CALL COUPLE(N,ITYPE,MXLAM,NPOTL,LAM,NSTATE,JSTATE,JSINDX,L,
     1            JTOT,VL,IV,IEXCH,IPRINT,ATAU)
      GOTO 8888
C
C  CODE FOR SURFACE SCATTERING
C
 5208 CALL SURBAS(JSTATE, N, JSINDX, L, EINT, CENT, VL, IV,
     1            MXLAM, NPOTL, LAM, ERED, WVEC, LCOUNT, THETA, PHI,
     2            EMAXK,IPRINT)
      IF (LCOUNT) GOTO 5000
C
 8888 IF (ITYPE.EQ.8) GOTO 4000
C
C  NOW CALCULATE THE DIAGONAL MATRIX ELEMENTS OF THE HAMILTONIAN
C
C  FIRST THE INTERNAL ROTATIONAL ENERGY FROM ENERGY('SIG-INDEX')
C  APR 94, ALLOW FOR NEGATIVE SIG-INDEX
      DO 8900 I=1,N
        EINT(I)=CM2RU * ELEVEL(ABS(JSTATE(NSTATE*(NQN-1)+JSINDX(I))))
 8900 CONTINUE
      DO 8950 I=1,N
C  NOW THE CENTRIFUGAL POTENTIAL
        IF (IBOUND.EQ.0) THEN
          CENT(I)=DBLE(L(I)*(L(I)+1))
        ELSE
          IF (ITYPE.GE.21 .AND. ITYPE.LE.27) THEN
C  SPECIAL CASE FOR HELICITY DECOUPLING FOR BOUND STATES
            JK=JSTATE(IOFF+JSINDX(I))
            CENT(I)=DBLE(JTOT*(JTOT+1)+JK*(JK+1)-2*MVALUE*MVALUE)
            L(I)=SQRT(CENT(I))
          ELSEIF (ITP.NE.9) THEN
C  ARRIVE HERE IF IBOUND=1 AND NOT BUILT-IN COUPLED STATES.
C  FOR ITYPE=9, IBOUND=1 IS A FLAG TO LEAVE CENT ALONE.
C  OTHERWISE, SET IT FROM L AS IF IBOUND=0
            CENT(I)=DBLE(L(I)*(L(I)+1))
          ENDIF
        ENDIF
 8950 CONTINUE
C
C  THIS COMPLETES THE SPECIFICATION OF THE BASIS BY GIVING VALUES
C  TO ALL RELEVANT MATRIX ELEMENTS
C
 4000 IF (IPRINT.LT.5) GOTO 4020

      IF (NCONST.EQ.0 .AND. NRSQ.EQ.0) THEN
        WRITE(6,'(/2X,A)') 'CHANNEL FUNCTION LIST:'
        WRITE(6,'(/2X,A)') 'EACH CHANNEL FUNCTION IS FORMED BY '//
     1                     'COMBINING A PAIR STATE WITH A VALUE OF L.'
        IF (NDGVL.GT.0)
     1    WRITE(6,'(/2X,A)') 'NOTE THAT EFV-DEPENDENT CONTRIBUTIONS'//
     2                       ' ARE NOT INCLUDED IN THESE PAIR ENERGIES.'
      ELSE
        WRITE(6,'(/2X,A)') 'BASIS FUNCTION LIST:'
      ENDIF
      IF (IBOUND.EQ.0) THEN
        NAME2='    L '
      ELSEIF (NRSQ.EQ.0) THEN
        NAME2='<L**2>'
      ELSE
        NAME2=' '
      ENDIF
C  BUILD FORMAT STATEMENTS
      IF (NCONST.EQ.0 .AND. NRSQ.EQ.0) THEN
        F640="(/2X,'CHANNEL',2X,'PAIR STATE',3X,"//TRIM(ADJUSTL(CPQN1))
     1       //",7X,A6,7X,'PAIR LEVEL',3X,'PAIR ENERGY (CM-1)')"
        F650="(25X,"//TRIM(ADJUSTL(CPQN2))//")"
      ELSE
        F640="(2X,'BASIS FN',8X,'SET',3X,"//TRIM(ADJUSTL(CPQN1))
     1       //",7X,A6)"
        F650="(25X,"//TRIM(ADJUSTL(CPQN2))//")"
      ENDIF

      WRITE(6,FMT=F640) NAME2
      WRITE(6,FMT=F650) (QNAME(IQN),IQN=1,NQN-1)
      IF (IBOUND.EQ.0) THEN
        F660="(2X,I7,5X,I7,2X,"//TRIM(ADJUSTL(CPQN3))
     1       //"3X,I10:,8X,I6,4X,F14.7)"
      ELSE
        F660="(2X,I7,5X,I7,2X,"//TRIM(ADJUSTL(CPQN3))
     1       //":3X,F10.2:,8X,I6,4X,F14.7)"
      ENDIF

      NPQL=(NQN-1)*NSTATE
      DO I=1,N
        IPS=JSINDX(I)
        IF (NCONST.EQ.0 .AND. NRSQ.EQ.0) THEN
          IPL=JSTATE(JSINDX(I)+NPQL)
          IF (IBOUND.EQ.0) THEN
            WRITE(6,FMT=F660) I,IPS,
     1                        (JSTATE(IPS+(IQN-1)*NSTATE),IQN=1,NQN-1),
     2                        L(I),IPL,EINT(I)/CM2RU
          ELSE
            WRITE(6,FMT=F660) I,IPS,
     1                        (JSTATE(IPS+(IQN-1)*NSTATE),IQN=1,NQN-1),
     2                        CENT(I),IPL,EINT(I)/CM2RU
          ENDIF
        ELSE
          IF (IBOUND.EQ.0) THEN
            WRITE(6,FMT=F660) I,IPS,
     1                        (JSTATE(IPS+(IQN-1)*NSTATE),IQN=1,NQN-1),
     2                        L(I)
          ELSEIF (NRSQ.EQ.0) THEN
            WRITE(6,FMT=F660) I,IPS,
     1                        (JSTATE(IPS+(IQN-1)*NSTATE),IQN=1,NQN-1),
     2                        CENT(I)
          ELSE
            WRITE(6,FMT=F660) I,IPS,
     1                        (JSTATE(IPS+(IQN-1)*NSTATE),IQN=1,NQN-1)
          ENDIF
        ENDIF
      ENDDO
 4020 CONTINUE
      IF (IPRINT.GE.26) CALL CPLOUT(IV,VL,N,NVLBLK)
C
C  COMPUTE STATISTICAL WEIGHT FOR THIS SYMMETRY BLOCK
C  AFTER MAY 76  IPAR USED IN PLACE OF IEXCH FOR CS WEIGHTING.
C
      WGHT=1.D0
      IF (IEXCH.GT.0) WGHT=WGHT*WT(MIN(2,IEXCH))
      IF (IPAR.GT.0)  WGHT=WGHT*WTM(MIN(2,IPAR))
 5000 IF (N.LE.0) N=0
      IF (N.EQ.0 .AND. IPRINT.GE.4)
     1  WRITE(6,*) ' BASIS-SET SIZE IS 0 FOR THIS SYMMETRY BLOCK'
      RETURN
C
C * * * * * * * * * * * * * * * * * * * * * * * * * * * END OF BASE * *
C
      ENTRY BASIN(NLEVV,JSTATE,URED,NQ,NLABV,MXPAR,ITYPP,IPRINT,
     1            IOSFLG,IBOUND,NPLEVS,ATAU)
C
C  SET DEFAULT VALUES BEFORE READ(5,BASIS).
      IOFF=0
      NLEVEL=0
      JMIN=0
      JMAX=0
      JSTEP=1
      J2MIN=0
      J2MAX=0
      J2STEP=1
      EMAX=0.D0
      EMAXK=0.D0
      DO 1103 I=1,MXROTS
 1103   ROTI(I)=0.D0
      DO I=1,MXELVL
        ELEVEL(I)=0.D0
      ENDDO
      WT(1)=0.D0
      WT(2)=0.D0
      EMAX=0.D0
      SPNUC=0.D0
      DO 1104 I=1,MXJLVL
 1104   JLEVEL(I)=0
      DO 1105 I=1,3
 1105   IOSNGP(I)=0
      IPHIFL=0
      IDENT=0
      WT(1)=0.D0
      WT(2)=0.D0
      WTM(1)=1.D0
      WTM(2)=1.D0
      MPLMIN=.TRUE.
      EUNITS=1
      EUNIT=1.D0
      EUNAME='B EN UNITS'
      BCT=.FALSE.
      JZCSMX=-1
      IBOUND=0
      JZCSFL=0
      IASYMU=0
      IVLU=0
      IVLFL=0
      NCONST=0
      NRSQ=0
      NEXTRA=0
      NEXTMS=0
      JHALF=1
      DO 1106 I=1,10
        ISYM(I)=-1
 1106   ISYM2(I)=-1
C----------------------------------------------------------------
      if (.not.inolls) READ(5,BASIS)
C
cINOLLS include 'all/rbasis.f'
C
C *** CHECK FIRST OF ALL FOR IOS CASES, INDICATED BY ITYPE.GT.100
      IF (ITYPE.LT.100) GOTO 1999
C
      IF (IPRINT.GE.1) WRITE(6,601)
  601 FORMAT(/'   ',19('*')/3X,'****** I O S ******'/3X,19('*'))
C  FORCE CORRECT IOSFLG.  NLEVV HAS MXA FOR IOSBIN
      IOSFLG=1
      MXA=NLEVV
      NEFV=0
      MAPEFV=0
      CALL IOSBIN(NLEVV,ITYPE,ATAU,MXA,IASYMU,IPHIFL,IOSNGP,IPRINT)
C  RESTORE APPROPRIATE ARGUMENT VARIABLES
      ITYPP=ITYPE
      IXNEXT=IXNEXT+MXA
      RETURN
C
C *** CONTINUE WITH COUPLED CHANNEL CASES
 1999 NSTATE=NLEVEL
      IF (EMAXK.EQ.0.D0) EMAXK=EMAX
C
      IF (EUNITS.NE.0) CALL ECNV(EUNITS,EUNIT,EUNAME,IPRINT)
      JZCSFL=MAX(MIN(JZCSFL,1),-1)
      IF (ITYPE.EQ.8) GOTO 6902
C  BELOW APPLIES EUNIT TO ROTI,ELEVEL
      IF (EUNIT.NE.1.D0 .AND. ITYPE.EQ.9) THEN
        WRITE(6,*)' *** WARNING - ALL ELEMENTS OF ROTI ARRAY',
     1            ' MULTIPLIED BY ',EUNIT
      ENDIF
      DO 6901 I=1,MXROTS
 6901   ROTI(I)=ROTI(I)*EUNIT
      DO I=1,MXELVL
        ELEVEL(I)=ELEVEL(I)*EUNIT
      ENDDO
 6902 EMAX=EMAX*EUNIT
      EMAXK=EMAXK*EUNIT
C
C  PROCESS ITYPE . . .
C
      ITP=MOD(ITYPE,10)
      IADD=ITYPE-ITP
      IF (ITP.NE.6 .AND. ITP.NE.9) IVLU=0
      IF (ITP.EQ.7) ITP=2
      IF (ITP.NE.9) GOTO 6837

      IBOUND=0
      NRSQ=0
      IF (JHALF.NE.1) THEN
        WRITE(6,*) ' *** SETTING JHALF IN NAMELIST IS NOW DEPRECATED.'
        WRITE(6,*) '     PLEASE USE MODULE basis_data IN BAS9IN AND '//
     1             'SET IT THERE.'
      ENDIF
      CALL BAS9IN(PRTP(1,9),IBOUND,IPRINT)
      IF (NEFV.EQ.-1) NEFV=0
      GOTO 3100

 6837 NEFV=0
      MAPEFV=1
      IF (IADD.NE.20) THEN
        IBOUND=0
      ENDIF
      NRSQ=0
      IF (ITYPE.LE.10) GOTO 3100
      IF (ITYPE.LE.20) GOTO 3200
      IF (ITYPE.LE.30) GOTO 3300

      IF (IPRINT.GE.1) WRITE(6,661)
  661 FORMAT(/'  DECOUPLED L-DOMINANT APPROX. OF DEPRISTO AND ',
     1       'ALEXANDER WILL BE USED.')
      GOTO 3100

 3300 IF (IPRINT.GE.1) WRITE(6,662) ITYPE,JZCSFL
  662 FORMAT(/'  COUPLED STATES APPROXIMATION OF MCGUIRE AND KOURI ',
     1       '(C.F.  J. CHEM. PHYS. 60, 2488 (1974))  WILL BE USED.'//
     2       11X,'ITYPE =',I3/11X,'L(I) = JTOT + (',I2,
     3       ') * (J(I)-2*M)')
      IF (IPRINT.GE.1 .AND. IBOUND.NE.0) WRITE(6,663)
  663 FORMAT(/'  DIAGONAL CORIOLIS TERM INCLUDED IN CENTRIFUGAL ',
     1       'POTENTIAL')
      IF (IPRINT.GE.1 .AND. BCT) WRITE(6,664)
  664 FORMAT(/'  BOHN-CAVAGNERO-TICKNOR HAMILTONIAN WITH DIATOM J ',
     1       'USED FOR L'/'  SO L(I) REPLACED WITH DIATOM J(I)')
      GOTO 3100

 3200 IF (IPRINT.GE.1) WRITE(6,665) ITYPE
  665 FORMAT(/'  *EFFECTIVE POTENTIAL METHOD* WILL BE USED.',
     1       ' SEE H. RABITZ,  J. CHEM. PHYS. 57, 1718 (1972).'//
     2       '     ITYPE =',I4)
 3100 IF (IPRINT.GE.1) WRITE(6,600) (PRTP(JJ,ITP),JJ=1,4)
  600 FORMAT(/'  INTERACTION TYPE IS  ', 4A8)
      IF (MOD(ITYPE,10).EQ.7 .AND. IPRINT.GE.1) WRITE(6,6840)
 6840 FORMAT(/'  ITYPE = 10*N+7 OPTION. ALL POTENTIAL MATRICES WILL BE',
     1       ' CONSTRUCTED FROM POTENTIAL TERMS IN WHICH DIATOM ',
     2       'STRETCHING'/'  DEPENDENCE IS PROPERLY AVERAGED OVER ',
     3       'RELEVANT (V,J) AND (V'',J'') DIATOM INTERNAL STATES.')
C
C  PROCESS EXCHANGE SYMMETRY FOR IDENTICAL PARTICLES
      CALL IDPART(ITYPE,IDENT,SPNUC,WT)
C
C  DETERMINE EIN AND LEVIN WHICH DENOTE WHETHER ELEVEL AND JSTATE ARE
C  TAKEN FROM INPUT ELEVEL AND JLEVEL OR ARE CALCULATED.
C  MODIFIED AUG 94 TO ALLOW NEGATIVE NLEVEL FOR ITYPE=6
C  NOTE: ITYPE = 4 CODE DOES NOT USE LEVIN,EIN
      IF (ITP.EQ.4) GOTO 7600

      IF (NLEVEL.GT.0) GOTO 7000

      LEVIN=.FALSE.
      EIN=.FALSE.
      IF (ITP.EQ.6 .AND. NLEVEL.LT.0) GOTO 7001

      GOTO 7100

 7000 LEVIN=.TRUE.
 7001 EIN=.TRUE.
      DO 7200 I=1,ABS(NLEVEL)
        IF (ELEVEL(I).NE.0.D0) GOTO 7100
 7200 CONTINUE
C  IF WE REACH THIS POINT ELEVEL(I) ARE ALL ZERO.
      EIN=.FALSE.
 7100 IF (EIN .OR. ITP.EQ.6) GOTO 7600

      DO 7400 I=1,10
        IF (ROTI(I).NE.0.D0) GOTO 7600
 7400 CONTINUE

      IF (NCONST.NE.0) GOTO 7600

      WRITE(6,630)
  630 FORMAT(/'  * * * ERROR.  ENERGY LEVELS CAN BE OBTAINED NEITHER ',
     1       'FROM ELEVEL NOR ROTI INPUT.')
      WRITE(6,629)
  629 FORMAT(/'  * * * EXECUTION TERMINATING.')
      STOP
C
C  PROCESS ACCORDING TO ITYPE.
C
 7600 CONTINUE
C     IF (ITYPE.EQ.1 .OR. ITYPE.EQ.11 .OR. ITYPE.EQ.21 .OR. ITYPE.EQ.31)
C    1  GOTO 1001
C     IF (ITYPE.EQ.2 .OR. ITYPE.EQ.12 .OR. ITYPE.EQ.22 .OR. ITYPE.EQ.32)
C    1  GOTO 1002
C     IF (ITYPE.EQ.3 .OR. ITYPE.EQ.13 .OR. ITYPE.EQ.23) GOTO 1003
      IF (ITYPE.LT.40 .AND. MOD(ITYPE,10).EQ.1) GOTO 1001
      IF (ITYPE.LT.40 .AND. MOD(ITYPE,10).EQ.2) GOTO 1002
      IF (ITYPE.LT.30 .AND. MOD(ITYPE,10).EQ.3) GOTO 1003
      IF (ITYPE.EQ.4 .OR. ITYPE.EQ.24) GOTO 1004
      IF (ITYPE.LT.30 .AND. MOD(ITYPE,10).EQ.5) GOTO 1005
      IF (ITYPE.LT.30 .AND. MOD(ITYPE,10).EQ.6) GOTO 1006
      IF (ITYPE.LT.40 .AND. MOD(ITYPE,10).EQ.7) GOTO 1002
C     IF (ITYPE.EQ.5 .OR. ITYPE.EQ.15 .OR. ITYPE.EQ.25) GOTO 1005
C     IF (ITYPE.EQ.6 .OR. ITYPE.EQ.16 .OR. ITYPE.EQ.26) GOTO 1006
C     IF (ITYPE.EQ.7 .OR. ITYPE.EQ.17 .OR. ITYPE.EQ.27 .OR. ITYPE.EQ.37)
C    1  GOTO 1002
      IF (ITYPE.EQ.8) GOTO 1008
      IF (ITP.EQ.9)   GOTO 1009
C
C  NO IMPLEMENTATION FOR OTHER TYPES OF INTERACTION PARTNERS.
      WRITE(6,611) ITYPE
  611 FORMAT(/'  ILLEGAL ITYPE =',I8,', EXECUTION TERMINATING.')
      STOP
C
C  * * * * * ITYPE = 1 * * * * *
C
 1001 IGO=9001
      IGODG=3901
 1111 NQN=2
      QNAME(1)=QTYPE(1)
      MXPAR=2
      CALL SET1(LEVIN,EIN,NSTATE,JSTATE,IPRINT)
      IF (ITYPE.LE.10) GOTO 2000
      IF (ITYPE.LE.20) GOTO 1311
      IF (ITYPE.LE.30) GOTO 1411

C  PROCESSING FOR DLD
      GOTO 1400

C  MODIFICATIONS FOR COUPLED STATES . . .
 1411 GOTO 1020

C  MODIFICATIONS NECESSARY FOR EFFECTIVE POTENTIAL METHOD. . .
 1311 IGODG=3911
      MXPAR=1
      GOTO 2000
C
C  * * * * * ITYPE = 2  OR  ITYPE = 7 * * * * *
C  DIATOM VIB-ROTOR PLUS ATOM     -     ADDED FEB 76
C
 1002 IGO=9001
      IGODG=3902
      IVLFL=1
      NQN=3
      MXPAR=2
      QNAME(1)=QTYPE(1)
      QNAME(2)=QTYPE(7)
      CALL SET2(LEVIN,EIN,NSTATE,JSTATE,IPRINT)
      IF (ITYPE.LE.10) GOTO 2000
      IF (ITYPE.LE.20) GOTO 1312
      IF (ITYPE.LE.30) GOTO 1412
      GOTO 1400

 1412 GOTO 1020

 1312 IGODG=3912
      MXPAR=1
      GOTO 2000
C
C  * * * * * ITYPE = 3  * * * * *
C  LINEAR ROTOR - LINEAR ROTOR ADDED AUG. 1974.
C
 1003 NQN=4
      IGO=9003
      IGODG=3903
      QNAME(1)=QTYPE(4)
      QNAME(2)=QTYPE(5)
      QNAME(3)=QTYPE(6)
      MXPAR=2
      CALL SET3(LEVIN,EIN,NSTATE,JSTATE,IPRINT)
      IF (ITYPE.LE.10) GOTO 7703

      IF (ITYPE.LE.20) GOTO 1013

C  CHANGES TO ACCOMMODATE COUPLED STATES APPROX.
      IOFF=2*NSTATE
C  SG (MAR.19.93) USE MPLMIN=.TRUE. EVEN FOR ITYPE=23 W/ IDENT=1
C  THIS INTRODUCES AT MOST PARSGN(J12+J12P+LM) INTO S-MATRIX
C  WHICH DOES NOT AFFECT STATE-TO-STATE CROSS SECTIONS
C  HOWEVER, OUTPUT A WARNING MESSAGE.
      IF (IDENT.NE.0) WRITE(6,603)
  603 FORMAT(/'  *** WARNING.  FOR ITYPE=23, MPLMIN=TRUE SHOULD GIVE',
     1        ' CORRECT STATE-TO-STATE CROSS SECTIONS.'/
     2        '  ***           IT MAY GIVE INCORRECT PHASES FOR',
     3        ' GENERALIZED CROSS SECTIONS.')
C     MPLMIN=.FALSE.                    <-- ORIGINAL
C     IF (IDENT.EQ.0) MPLMIN=.TRUE.    <-- CODE
      GOTO 1020

C  PROCESS JLEVEL TO JSTATE FOR 'EPM' CASE
 1013 NQN=3
      MXPAR=1
      IGODG=3913
C  APR 94: STATEMENT BELOW WAS LOST IN VERSIONS 9-12
      NSTATE=NLEVEL
      DO 7713 I=1,NSTATE
        JSTATE(I)=JLEVEL(2*I-1)
        JSTATE(NSTATE+I)=JLEVEL(2*I)
 7713   JSTATE(2*NSTATE+I)=I
 7703 IF (IDENT.NE.0) MXPAR=2*MXPAR
      GOTO 2000
C
C  * * * * * ITYPE = 4  * * * * *
C  ASYMMETRIC TOP - LINEAR RIGID ROTOR, AUG 90 GISS (TRP)
C
 1004 NQN = 8
      IGO=9004
      IGODG=3904
      QNAME(1) = QTYPE(6)
      QNAME(2) = QTYPE(5)
      QNAME(3) = QTYPE(4)
      QNAME(4) = QTYPE(8)
      QNAME(5) = QTYPE(3)
      QNAME(6) = QTYPE(9)
      QNAME(7) = QTYPE(9)
      MXPAR = 2
      CALL SET4(NSTATE,JSTATE,ATAU,EUNIT,IASYMU,IPRINT)
      IF (ITYPE.LE.10) GOTO 2000

      GOTO 1020
C
C  * * * * * ITYPE = 5  * * * * *
C
 1005 NQN=4
      IGO=9005
      IGODG=3905
      QNAME(1)=QTYPE(1)
      QNAME(2)=QTYPE(2)
      QNAME(3)=QTYPE(3)
      MXPAR=2
      CALL SET5(LEVIN,EIN,NSTATE,JSTATE,IPRINT)
      IF (ISYM(1).NE.-1) THEN
        MXPAR=ISYM(1)*MXPAR
        IF (IPRINT.GE.1) WRITE(6,605) ISYM(1),ISYM(1)-1
  605   FORMAT(/'  ISYM(1) =',I2,' OPTION: SEPARATE CALCULATIONS WILL',
     1         ' BE CARRIED OUT FOR K VALUES FROM 0 TO',I2)
      ENDIF
      IF (ISYM(2).NE.-1) THEN
        MXPAR=2*MXPAR
        IF (IPRINT.GE.1) WRITE(6,606)
  606   FORMAT(/'  ISYM(2).NE.-1 OPTION: SEPARATE CALCULATIONS WILL',
     1         ' BE CARRIED OUT FOR J+K+PRTY EVEN AND ODD')
      ENDIF
      IF (ITYPE.LE.10) GOTO 2000
      IF (ITYPE.LE.20) GOTO 1015

C  MODIFICATIONS FOR COUPLED STATES. . .
      GOTO 1020

C  MODIFICATIONS FOR EFFECTIVE POTENTIAL . . .
 1015 IGODG=3915
      MXPAR=1
      GOTO 2000
C
C  * * * * * ITYPE = 6 * * * * *
C  ASYMMETRIC TOP - ATOM ADDED JULY 76 AT MPI, MUNCHEN.
C
 1006 IGO=9006
      IGODG=3906
      QNAME(1)=QTYPE(1)
      QNAME(2)=QTYPE(8)
      QNAME(3)=QTYPE(3)
      QNAME(4)=QTYPE(9)
      QNAME(5)=QTYPE(9)
      NQN=6
      MXPAR=2
      CALL SET6(LEVIN,EIN,NSTATE,JSTATE,ATAU,EUNIT,IASYMU,IPRINT)
      IF (ITYPE.LE.10) GOTO 2000
      IF (ITYPE.LE.20) GOTO 1316
      IF (ITYPE.LE.30) GOTO 1416

C  ADDITIONAL PROCESSING FOR COUPLED STATES.
 1416 GOTO 1020

C  ADDITIONAL PROCESSING FOR EFFECTIVE POTENTIAL.
 1316 MXPAR=1
      IGODG=3916
      GOTO 2000
C
 1009 IGODG=3909
C  N.B. CODE HERE OR IN SET9 SHOULD ASSIGN APPROPRIATE IVLFL
      CALL SET9(LEVIN,EIN,NSTATE,JSTATE,NQN,QNAME,MXPAR,NLABV,IPRINT)
C
C  RESET NLEVEL TO ZERO SO THAT IT CAN BE OBTAINED FROM GETLEV
C  FOR CASES WHERE THE THRESHOLDS COME FROM DIAGONALISATION
      NPLEVS=NLEVEL
      IF (NCONST.GT.0 .OR. NRSQ.GT.0) NLEVEL=0
C
      GOTO 2000
C
C  **** MCGUIRE COUPLED STATES APPROX.  ****
C  **** ALSO FOR DLD OF DEPRISTO AND ALEXANDER
 1020 WTM(1)=1.D0
      WTM(2)=1.D0
      IF (.NOT.MPLMIN) GOTO 1400

      WTM(2)=2.D0
      IF (IPRINT.GE.1) WRITE(6,604)
  604 FORMAT(/'  *** NOTE.  IN CS CALCULATION MINUS/PLUS M-VALUE ',
     &       'ASSUMED TO BE IDENTICAL.')
 1400 MJMX=0
      DO 1121 I=1,NSTATE
 1121   MJMX=MAX(MJMX,JSTATE(IOFF+I))
      IF (JZCSMX.LT.0) GOTO 1221

      IF (IPRINT.GE.1) WRITE(6,6221) JZCSMX
 6221 FORMAT('  *** NOTE.  CS OR DLD APPROXIMATION SUBSPACE IS ',
     &       'LIMITED BY JZCSMX =',I3/
     &       13X,'CROSS SECTIONS BETWEEN HIGHER J INACCURATE.')
      MJMX=MIN(MJMX,JZCSMX)
 1221 MXPAR=MJMX+1
      IF (.NOT.MPLMIN) MXPAR=MXPAR+MJMX
      IF (ITYPE.EQ.31 .OR. ITYPE.EQ.32 .OR. ITYPE.EQ.37)
     1  MXPAR=MXPAR+MJMX
      IF (ITYPE.EQ.23 .AND. IDENT.NE.0) MXPAR=2*MXPAR
      IF (ITYPE.EQ.25) THEN
        IF (ISYM(1).NE.-1) MXPAR=ISYM(1)*MXPAR
        IF (ISYM(2).NE.-1) MXPAR=2*MXPAR
      ENDIF
C  ADJUST SIG INDEX TO BE NEGATIVE IF J-VALUE IS GREATER THAN JZCSMX
      LSIG=.FALSE.
      IXT=(NQN-1)*NSTATE
C  MODIFIED FOR ITYPE=24 29 JUL 94 (SG)
      IF (ITYPE.EQ.23 .OR. ITYPE.EQ.24) THEN
        IF (ITYPE.EQ.23) IOX=0
        IF (ITYPE.EQ.24) IOX=2*NSTATE
        DO 2001 I=1,NSTATE
C  TWO ROTORS; COMPARE J1+J2 W/ MJMX
          IF (JSTATE(IOX+I)+JSTATE(NSTATE+I).LE.MJMX) GOTO 2001
          JSTATE(IXT+I)=-JSTATE(IXT+I)
          LSIG=.TRUE.
 2001   CONTINUE
      ELSE
        DO 2002 I=1,NSTATE
C  ALL OTHER CASES; N.B. IOFF=0 FOR THESE (J IS 1ST QUANT NO.)
          IF (JSTATE(IOFF+I).LE.MJMX) GOTO 2002
          JSTATE(IXT+I)=-JSTATE(IXT+I)
          LSIG=.TRUE.
 2002   CONTINUE
      ENDIF
      IF (LSIG .AND. IPRINT.GE.1) WRITE(6,672)
  672 FORMAT('  *** NOTE.  NEGATIVE VALUE FOR PAIR LEVEL INDEX',
     1       ' INDICATES THAT LEVEL'/
     2       '             IS AFFECTED BY JZCSMX LIMITATION.'/
     3       '  *** NOTE.  CROSS SECTIONS INCOMPLETE BECAUSE OF JZCSMX',
     4       ' WILL BE MARKED NEGATIVE'/
     5       '             AND PRINTED ONLY IF ISIGPR.GE.2')
      GOTO 2000
C
C  * * * * * ITYPE = 8 * * * * *
C  ATOM - SURFACE SCATTERING:  ADDED AT WATERLOO, DEC 1982
C
 1008 NQN=3
C  IVLFL SET TO REFLECT USE OF IV() ARRAY IN EXTANT ITYPE=8 CODES.
      IVLFL=1
      IGODG=3918
      QNAME(1)='    G1  ' !QTYPE(4)
      QNAME(2)='    G2  ' !QTYPE(5)
      CALL SET8(LEVIN,EIN,NSTATE,JSTATE,URED,IPRINT)
      GOTO 2000
C
C  FINAL BOOKKEEPING.
C
 2000 IXNEXT = IXNEXT + NSTATE*NQN
      NQ = NQN
      QNAME(NQN)=QTYPE(10)
C
      IF (ITYPE.NE.9 .OR. (NCONST.EQ.0 .AND. NRSQ.EQ.0)) NPLEVS=NLEVEL
      IF (NPLEVS.LE.MXELVL) GOTO 1224

      WRITE(6,619) NPLEVS
  619 FORMAT(/'  **** ERROR IN BASE. NOT ENOUGH STORAGE FOR',I4,
     1       ' LEVELS - TERMINATING')
      STOP

 1224 NLEVV=NSTATE
      ITYPP=ITYPE
      ITYPX=ITYPE
      IF (ITYPE-10*(ITYPE/10).EQ.7) ITYPX=ITYPE-5

      IF (NSTATE.LE.0) THEN
        WRITE(6,*) ' *** ERROR. NO LEVELS SPECIFIED IN BASIN'
        STOP
      ENDIF
C
      IF (IPRINT.GE.1) THEN
        WRITE(6,'(/2X,A)') 'QUANTUM NUMBERS FOR INTERACTING PAIR:'
  640   FORMAT(2X,A,I3,A)
        WRITE(CNQN,'(I2)') NQN-1
        NLEN=(NQN-1)*10-28 ! 28 IS LENGTH OF 'PAIR STATE QUANTUM NUMBERS' + 2 SPACES
        WRITE(CLEN2,'(I2)') ABS(NLEN/2)

C  BUILD FORMAT STATEMENTS
        IF (NLEN.GT.0) THEN
          CPQN1=TRIM(ADJUSTL(CLEN2))
     1          //"('-'),1X,'PAIR STATE QUANTUM NUMBERS',1X"
     2          //TRIM(ADJUSTL(CLEN2))//"('-')"
          CPQN2=TRIM(ADJUSTL(CNQN))//'(1X,A8,1X)'
          CPQN3=TRIM(ADJUSTL(CNQN))//'(1X,I8,1X)'
        ELSE
          CPQN1="1X,'PAIR STATE QUANTUM NUMBERS',1X"
          CPQN2=TRIM(ADJUSTL(CLEN2))//"('-'),"//
     1          TRIM(ADJUSTL(CNQN))//"(1X,A8,1X),"//
     2          TRIM(ADJUSTL(CLEN2))//"('-')"
          CPQN3=TRIM(ADJUSTL(CLEN2))//"X,"//
     1          TRIM(ADJUSTL(CNQN))//"(1X,I8,1X),"//
     2          TRIM(ADJUSTL(CLEN2))//"X,"
        ENDIF
        F640="(/2X,A12,2X,"//TRIM(ADJUSTL(CPQN1))//":3X,A,5X,A)"
        F650="(16X,"//TRIM(ADJUSTL(CPQN2))//")"
        F660="(6X,I3,7X,"//TRIM(ADJUSTL(CPQN3))//":3X,I4,4X,F18.7)"

        IF (NCONST.EQ.0 .AND. NRSQ.EQ.0) THEN
          WRITE(6,640) 'EACH PAIR STATE IS LABELLED BY',NQN-1,
     1                 ' QUANTUM NUMBER'//PLUR(MIN(NQN-1,2))
          WRITE(6,*) ' EACH CHANNEL FUNCTION IS FORMED BY COMBINING '//
     1               'A PAIR STATE WITH A VALUE OF L.'
          WRITE(6,*) ' THE RESULTING BASIS SET IS ASYMPTOTICALLY '//
     1               'DIAGONAL.'
          IF (NDGVL.GT.0)
     1      WRITE(6,'(2X,A/)') 'NOTE THAT EFV-DEPENDENT CONTRIBUTIONS'//
     2                         ' ARE NOT INCLUDED IN THESE'//
     3                         ' PAIR ENERGIES.'
          WRITE(6,FMT=F640) 'PAIR STATE  ','PAIR LEVEL',
     1                      'PAIR ENERGY (CM-1)'
          WRITE(6,FMT=F650) (ADJUSTR(QNAME(I)),I=1,NQN-1)
        ELSE
          WRITE(6,640) 'THE BASIS FUNCTIONS ARE LABELLED BY A SET OF ',
     1                 NQN-1,
     2                 ' PAIR STATE QUANTUM NUMBERS AND A VALUE OF L.'
          WRITE(6,*) ' THE RESULTING BASIS SET IS ASYMPTOTICALLY '//
     1               'NON-DIAGONAL.'
          WRITE(6,*)
          WRITE(6,*) ' THE SETS OF PAIR STATE QUANTUM NUMBERS ARE:'
          WRITE(6,FMT=F640) '    SET     '
          WRITE(6,FMT=F650) (ADJUSTR(QNAME(I)),I=1,NQN-1)
        ENDIF

        NQLABS=(NQN-1)*NSTATE
        DO I=1,NSTATE
          IF (NCONST.EQ.0 .AND. NRSQ.EQ.0) THEN
            WRITE(6,FMT=F660) I,(JSTATE(I+(IQN-1)*NSTATE),IQN=1,NQN),
     1                        ELEVEL(ABS(JSTATE(I+NQLABS)))
          ELSE
            WRITE(6,FMT=F660) I,(JSTATE(I+(IQN-1)*NSTATE),IQN=1,NQN-1)
          ENDIF
        ENDDO
      ENDIF
C
C  ALLOW FOR INITIALIZATION OF COUPLE/MCGCPL ROUTINES
      CALL COUPLX
      CALL MCGCPX
      RETURN
C * * * * * * * * * * * * * * * * * * * * * * * * * * * * * END OF BASIN
C
      ENTRY DEGENF(J2,J1,DEGEN)
C
C  RETURNS DEGENERACY FACTOR FOR DENOMINATOR OF CROSS-SECTION CALC.
C  IN OUTPUT.  J1 IS INITIAL, J2 IS FINAL LEVEL.
C  MODIFIED AUG. 74 SO THAT LEVELS REFER TO JLEVEL VALUES.
C
      IF (IGODG.EQ.3901) THEN
        JI=JLEVEL(J1)
        DEGEN=DBLE(2*JI+1)

      ELSEIF (IGODG.EQ.3902) THEN
        JI=JLEVEL(2*J1-1)
        DEGEN=DBLE(2*JI+1)

      ELSEIF (IGODG.EQ.3903) THEN
        JI1=JLEVEL(2*J1-1)
        JI2=JLEVEL(2*J1)
        DEGEN=DBLE((2*JI1+1)*(2*JI2+1))
        IF (IDENT.EQ.0) RETURN

        IF (JI1.EQ.JI2) DEGEN=DEGEN/2.D0
        IF (JLEVEL(2*J2-1).EQ.JLEVEL(2*J2)) DEGEN=DEGEN/2.D0

      ELSEIF (IGODG.EQ.3904) THEN
        JI1=JLEVEL(3*J1-2)
        JI2=JLEVEL(3*J1)
        DEGEN=DBLE((2*JI1+1)*(2*JI2+1))

      ELSEIF (IGODG.EQ.3905) THEN
        JI=JLEVEL(3*J1-2)
        DEGEN=DBLE(2*JI+1)

      ELSEIF (IGODG.EQ.3906) THEN
        JI=JLEVEL(2*J1-1)
        DEGEN=DBLE(2*JI+1)

      ELSEIF (IGODG.EQ.3909) THEN
        CALL DEGEN9(J1,J2,DEGEN)
C
C  FOLLOWING ARE DEGENERACY DENOMINATORS FOR EPM COUNTING CORRECTION.
      ELSEIF (IGODG.EQ.3911) THEN
        JI1=JLEVEL(J1)
        JF1=JLEVEL(J2)
        DEGEN=SQRT(DBLE(2*JI1+1)/DBLE(2*JF1+1))

      ELSEIF (IGODG.EQ.3912) THEN
        JI1=JLEVEL(2*J1-1)
        JF1=JLEVEL(2*J2-1)
        DEGEN=SQRT(DBLE(2*JI1+1)/DBLE(2*JF1+1))

      ELSEIF (IGODG.EQ.3913) THEN
        JI1=JLEVEL(2*J1-1)
        JI2=JLEVEL(2*J1)
        JF1=JLEVEL(2*J2-1)
        JF2=JLEVEL(2*J2)
        DEGEN=SQRT(DBLE((2*JI1+1)*(2*JI2+1)) /
     1             DBLE((2*JF1+1)*(2*JF2+1)) )
        IF (IDENT.EQ.0) RETURN
        IF (JI1.EQ.JI2) DEGEN=DEGEN/2.D0
        IF (JF1.EQ.JF2) DEGEN=DEGEN/2.D0

      ELSEIF (IGODG.EQ.3915) THEN
        JI1=JLEVEL(3*J1-2)
        JF1=JLEVEL(3*J2-2)
        DEGEN=SQRT(DBLE(2*JI1+1)/DBLE(2*JF1+1))

      ELSEIF (IGODG.EQ.3916) THEN
        JI1=JLEVEL(2*J1-1)
        JF1=JLEVEL(2*J2-1)
        DEGEN=SQRT(DBLE(2*JI1+1)/DBLE(2*JF1+1))

      ELSEIF (IGODG.EQ.3918) THEN
        DEGEN=1.D0
      ENDIF

      RETURN
      END
