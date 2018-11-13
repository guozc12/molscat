      SUBROUTINE SURBAS(JSTATE, N, JSINDX, L, EINT, CENT, VL, IV,
     1                  MXLAM, NPOTL, LAM, ERED, WVEC, LCOUNT, THETA,
     2                  PHI, EMAXK, IPRINT)
C  Copyright (C) 2018 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      USE basis_data
      USE physical_constants
C
C  SUBROUTINE TO SET UP ATOM-SURFACE SCATTERING.
C  THIS VERSION USES 2 ELEMENTS OF THE VL ARRAY FOR EACH PAIR OF
C  BASIS FUNCTIONS, SO REQUIRES NPOTL=2 RETURNED FROM POTENL.
C  COMMON BLOCK NPOT COMMUNICATES THIS TO POTENL
C  VERSION 14 CMBASE
C  AUG 18 CMBASE COMMON BLOCK REPLACED BY MODULE basis_data
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      SAVE
      INTEGER FIND
      LOGICAL LCOUNT,LEVIN,EIN,HEX,ORTHOG,EQUIV
      DIMENSION JSTATE(1), JSINDX(1), L(1), EINT(1), CENT(1),
     1          WVEC(1), VL(1), IV(1), LAM(1)
      COMMON /NPOT/ NPTL
      COMMON /LATSYM/ HEX,ORTHOG,EQUIV
C  16-10-16: BFCT IS NOW STORED IN MODULE physical_constants
C     DATA BFCT /16.857630D0/
C
      SQUARE(AA,BB) = AA*AA + BB*BB + 2.D0*AA*BB*COSLAT
C
C  ISYM1 IS A LABEL FOR THE TYPE OF SYMMETRIZATION:
C      < 0  NO SYMMETRIZATION
C      = 0   0 DEGREE SYMMETRIZATION FOR RECTANGULAR OR HEX LATTICE
C      = 1  30 DEGREE SYMMETRIZATION FOR HEX LATTICE
C      = 2  45 DEGREE SYMMETRIZATION FOR SQUARE LATTICE
C
      ISYM1 = -1
      IF ((HEX .OR. ORTHOG) .AND. ABS(PHI).LT.1.D-10) ISYM1 = 0
      IF (HEX .AND. ABS(MOD(PHI,60.D0)-30.D0).LT.1.D-10) ISYM1 = 1
      IF (ORTHOG .AND. EQUIV .AND. ABS(MOD(PHI,90.D0)-45.D0).LT.1.D-10)
     1  ISYM1 = 2
C
      PARA=SQRT(ERED)*SIN(THETA*PI/180.D0)
      SINPHI=SIN(PHI*PI/180.D0)
      COSPHI=COS(PHI*PI/180.D0)
      XK2=PARA*SINPHI/SINLAT
      XK1=PARA*COSPHI-XK2*COSLAT
      IF (LCOUNT) GOTO 50

      IF (IPRINT.GE.1) THEN
        WRITE(6,598) N,THETA,PHI,XK1,XK2
  598   FORMAT(/I4,' CHANNEL BASIS FOR THETA =',F8.3,'  PHI =',F8.3,
     1         ' DEGREES'/'  CORRESPONDING TO K = (',2F10.6,' ) A-1')
        IF (ISYM1.GE.0) WRITE(6,599)
  599   FORMAT('  SYMMETRIZED BASIS USED FOR THESE ANGLES'/
     1         '  NOTE THAT CALCULATED INTENSITIES FOR OUT-OF-PLANE',
     2         ' BEAMS ARE IMPLICITLY SUMMED OVER EQUIVALENT PAIRS')
        IF (EMAXK.NE.EMAX) WRITE(6,600) EMAXK
  600   FORMAT('  BASIS FUNCTIONS LIMITED BY EMAXK =',F10.3)
      ENDIF
C
   50 I=0
      N=0
      DO 200 N1=1,NLEVEL
        J1=JSTATE(N1+NLEVEL)
        IF (ISYM1.GE.0 .AND. 2*J1.LT.ISYM1*JSTATE(N1)) GOTO 200
        AA=XK1+XH*DBLE(JSTATE(N1))
        BB=XK2+XK*DBLE(J1)
        ECHAN=SQUARE(AA,BB)
        IF (ECHAN*ESCALE.GT.EMAXK) GOTO 200
        N=N+1
        IF (LCOUNT) GOTO 200
        EINT(N)=ECHAN
        DIF=ERED-ECHAN
        WVEC(N)=SIGN(SQRT(ABS(DIF)),DIF)
        JSINDX(N)=JSTATE(N1+NST2)
        L(N)=0
        CENT(N)=0.D0
        DO 100 M=1,N
          N2=JSINDX(M)
          J2=JSTATE(N2+NLEVEL)
          IF (ISYM1.GE.0 .AND. 2*J2.LT.ISYM1*JSTATE(N2)) GOTO 100
          I=I+1
          I1=JSTATE(N2)-JSTATE(N1)
          I2=J2-J1
          IV(I)=FIND(I1,I2,LAM,MXLAM)
          VL(I)=1.D0
          IF (IV(I).EQ.0) VL(I)=0.D0
          I=I+1
          IV(I)=0
          VL(I)=0.D0
          IF (ISYM1.LT.0) GOTO 100
          IF (2*J1.EQ.ISYM1*JSTATE(N1) .NEQV. 2*J2.EQ.ISYM1*JSTATE(N2))
     1      VL(I-1)=VL(I-1)*ROOT2
          IF (2*J1.EQ.ISYM1*JSTATE(N1)  .OR.  2*J2.EQ.ISYM1*JSTATE(N2))
     1      GOTO 100
C
C  IDENTIFY FOURIER COMPONENT CONNECTING SIGMA(N1) TO N2
C
          GOTO(70,80),ISYM1
          I1=JSTATE(N1)
          IF (HEX) I1=I1-J1
          I2=-J1
          GOTO 90

   70     I1=JSTATE(N1)
          I2=I1-J1
          GOTO 90

   80     I1=J1
          I2=JSTATE(N1)
   90     I1=JSTATE(N2)-I1
          I2=J2-I2
          IV(I)=FIND(I1,I2,LAM,MXLAM)
          VL(I)=1.D0
          IF (IV(I).EQ.0) VL(I)=0.D0
  100   CONTINUE
  200 CONTINUE
      RETURN
C  =================================================== END OF SURBAS
C
C
      ENTRY SET8(LEVIN,EIN,NSTATE,JSTATE,URED,IPRINT)
C
      NPTL=2
      ROOT2=SQRT(2.D0)
      ESCALE=BFCT/URED
C
      EMIN=0.D0
      PI=ACOS(-1.D0)
      COSLAT=COS(ROTI(3)*PI/180.D0)
      SINLAT=SIN(ROTI(3)*PI/180.D0)
      ORTHOG = ABS(COSLAT).LT.1.D-8
      EQUIV  = ABS(ROTI(1)-ROTI(2)).LT.1.D-8
      HEX    = EQUIV .AND. ABS(COSLAT+0.5D0).LT.1.D-8
      XH=2.D0*PI/SINLAT/ROTI(1)
      XK=2.D0*PI/SINLAT/ROTI(2)

      IF (IPRINT.GE.1) WRITE(6,601)(ROTI(I),I=1,3),COSLAT
  601 FORMAT('  LATTICE LENGTHS ARE',F10.6,' AND',F10.6,' A'/
     1       '  RECIPROCAL LATTICE ANGLE IS   ',F10.3,' DEGREES,',
     2       '  COSINE =',F10.6/)
C
      IF (LEVIN) GOTO 500

      IF (IPRINT.GE.1) WRITE(6,602) EMIN,EMAX,J1MAX,J2MAX
  602 FORMAT('  BASIS FUNCTIONS GENERATED WITH'/5X,'EMIN   =',F10.3/
     1       5X,'EMAX   =',F10.3/5X,'G1MAX  =',I10/5X,'G2MAX  =',I10/)

      N1MAX=SQRT(EMAX)/(SINLAT*XH)
      N1MAX=MIN(N1MAX,J1MAX)
      NLEVEL=0
      DO 300 N1=-N1MAX,N1MAX
        AA=DBLE(N1)*XH
        BB=AA*COSLAT
        N2MAX=(ABS(BB)+SQRT(EMAX+BB*BB-AA*AA))/XK
        N2MAX=MIN(N2MAX,J2MAX)
      DO 300 N2=-N2MAX,N2MAX
        BB=DBLE(N2)*XK
        E=SQUARE(AA,BB)*ESCALE
        IF (E.LT.EMIN .OR. E.GT.EMAX) GOTO 300
        NLEVEL=NLEVEL+1
        JLEVEL(2*NLEVEL-1)=N1
        JLEVEL(2*NLEVEL)  =N2
        ELEVEL(NLEVEL)=E
  300 CONTINUE
C
C  SORT CHANNELS ON ENERGY FOR K=0
C
      DO 400 N1=1,NLEVEL
      DO 400 N2=N1+1,NLEVEL
        IF (ELEVEL(N2).GE.ELEVEL(N1)) GOTO 400
        E=ELEVEL(N1)
        ELEVEL(N1)=ELEVEL(N2)
        ELEVEL(N2)=E
        I1=2*N1
        I2=2*N2
        I=JLEVEL(I1-1)
        JLEVEL(I1-1)=JLEVEL(I2-1)
        JLEVEL(I2-1)=I
        I=JLEVEL(I1)
        JLEVEL(I1)=JLEVEL(I2)
        JLEVEL(I2)=I
  400 CONTINUE
      GOTO 700
C
  500 DO 520 N1=1,NLEVEL
      DO 520 N2=N1+1,NLEVEL
  520   IF (JLEVEL(2*N1-1).EQ.JLEVEL(2*N2-1) .AND.
     1      JLEVEL(2*N1)  .EQ.JLEVEL(2*N2)) GOTO 530

      GOTO 540

  530 WRITE(6,603) N1,N2
  603 FORMAT(' **** BASIS FUNCTIONS',I3,' AND',I3,' ARE THE SAME.',
     1       '  TERMINATING.')
      STOP

  540 IF (IPRINT.GE.1) WRITE(6,604) NLEVEL
  604 FORMAT('  BASIS FUNCTIONS TAKEN FROM JLEVEL INPUT WITH NLEVEL =',
     1       I3)

  700 NSTATE=NLEVEL
      NST2=2*NSTATE
      DO 800 I=1,NSTATE
        N1=JLEVEL(2*I-1)
        N2=JLEVEL(2*I)
        JSTATE(I)=N1
        JSTATE(I+NSTATE)=N2
        JSTATE(I+NST2)=I
        IF (.NOT.LEVIN) GOTO 800
        AA=DBLE(N1)*XH
        BB=DBLE(N2)*XK
        ELEVEL(I)=SQUARE(AA,BB)*BFCT/URED
  800 CONTINUE
C
      IF (EIN .AND. IPRINT.GE.1) WRITE(6,605)
  605 FORMAT(' *** NOTE. INPUT CHANNEL ENERGIES OVERWRITTEN BY VALUES',
     1       ' CALCULATED FROM LATTICE PARAMETERS'/)
      RETURN
      END
