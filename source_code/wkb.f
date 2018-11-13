      SUBROUTINE WKB(N,MXLAM,NPOTL,SREAL,SIMAG,VL,IV,EINT,CENT,
     1               WVEC,L,P,W,DIAG,IPRINT)
C  Copyright (C) 2018 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
C
C  THIS ROUTINE GETS PHASE SHIFT (S-MATRIX) FOR 1-DIMENSIONAL
C  SCATTERING EQUATION VIA THE WKB APPROXIMATION USING GAUSS-MEHLER
C  NUMERICAL INTEGRATION AS SUGGESTED BY
C  R.T PACK, J. CHEM. PHYS. 60, 633 (1974).
C
C  THIS ROUTINE IS COMPATIBLE WITH MOLSCAT/IOS CODE
C  WRITTEN OCT 1977 BY S. GREEN (GISS), MODIFIED APR 1986 FOR CCP6.
C  MODIFIED JUL 86 WITH MORE SOPHISTICATED START (FIND TURNING PT.)
C  MODIFIED SOME OUTPUT FORMATS 5/13/92
C
C  VARIABLES FOR MOLSCAT COMPATIBILITY . . .
      DIMENSION W(*),SIMAG(*),SREAL(*),P(*),L(*),EINT(*),CENT(*),
     1          DIAG(*),WVEC(*),VL(*),IV(*)
C
C
C  THE NUMBER OF GAUSS POINTS IS INCREASED CHECKING FOR CONVERGENCE
C  PARAMETERS TO CONTROL GAUSS-MEHLER CONVERGENCE ITERATION. . .
      COMMON /WKBCOM/ NGMP(3)
C
C  COMMON BLOCK FOR COMMUNICATING WITH COUPLED EQUATION SOLVERS
C
      COMMON /DRIVE/ DTOL,STEPS,STABIL,CONV,RMIN,RSTOP,XEPS,DR,
     1               DRMAX,RMID,RMATCH,TOLHI,RTURN,VTOL,ESHIFT,
     2               ERED,RMLMDA,NOPEN,JKEEP,ISCRU,MAXSTP,ILDSVU
C
C  TOLERANCES FOR NEWTON-RAPHSON SEARCH FOR R0 . . .
      DATA EPS/5.D-5/ , ITMX/24/
      DATA IDER/1/
C
C  MODIFY CENTRIFUGAL POTENTIAL (CENT) VIA 'LANGER' CORRECTION
      PI=ACOS(-1.D0)
      DCENT=DBLE(L(1))+.5D0
      DCENT=DCENT*DCENT
      CSAVE=CENT(1)
      CENT(1)=DCENT
C  INITIALIZE OTHER VARIABLES
      PI2=2.D0*PI
C
C  FIND TURNING POINT VIA NEWTON-RAPHSON METHOD.  START WITH RMIN
C
      IT=0
      ECNV=EPS*ERED
      RCNV=EPS*RMIN
      R=RMIN
C  IF POTENTIAL IS NOT DECREASING, TRY BACKING UP . . .
 1198 CALL DERMAT(IDER,W,N,R,P,VL,IV,CENT,
     1            RMLMDA,MXLAM,NPOTL,IPRINT)
      IF (W(1).LE.0.D0) GOTO 1000

      IF (IPRINT.GE.10) WRITE(6,699) IT,R,W(1)
  699 FORMAT(/' * * * WKB BAD START.  TRY 7/86 FIX.  ITER, R, DV/DR =',
     1       I4,2F15.5)
      R=0.9D0*R
      IT=IT+1
      IF (IT.LE.ITMX) GOTO 1198

      WRITE(6,697) ITMX
  697 FORMAT(/' * * * ERROR (7/86).  WKB CANNOT START.  ITMX =',I4)
      STOP

 1000 CALL WAVMAT(W,N,R,P,VL,IV,ERED,EINT,CENT,RMLMDA,DIAG,
     1            MXLAM,NPOTL,IPRINT)
      V=W(1)
      CALL DERMAT(IDER,W,N,R,P,VL,IV,CENT,
     1            RMLMDA,MXLAM,NPOTL,IPRINT)
      DVDR=W(1)
      DR=-V/DVDR
C  TO PREVENT OCCASIONAL ERRATIC BEHAVIOR ALLOW ONLY 25% CHANGE IN R
      DRMAX=2.5D-1*ABS(R)
      IF (ABS(DR).LE.DRMAX) GOTO 1199

      IF (DR.LT.0.D0) DRMAX=-DRMAX
      IF (IPRINT.GE.20) WRITE(6,698) IT,R,DR,DRMAX
 698  FORMAT(' * * WKB. 7/86 FIX. ITER, R, DR, DRMAX =',I4,3F15.5)
      DR=DRMAX
 1199 IF (ABS(DR).LE.RCNV .OR. ABS(V).LE.ECNV) GOTO 1009

      IT=IT+1
      R=R+DR
      IF (IT.LE.ITMX) GOTO 1000

      IF (IPRINT.GE.10) WRITE(6,694) IT,R,DR,V,DVDR
  694 FORMAT(' WKB: NEWTON-RAPHSON START FAILED TO CONVERGE. IT =',I4
     &         /16X,'R,DR,V,DVDR=',4E12.4)
C
C  TRY A REGULA-FALSI METHOD.  1ST, UNDO LAST R CHANGE, RESET IT.
      R=R-DR
      IT=0
      XL=R
      YL=V
C  STEP IN DIRECTION OF OPPOSITE SIGN FOR POTENTIAL.
      IF (V*DVDR*DR.LT.0) GOTO 1201

      DR=-DR
 1201 RSV=R
      DO 1202 ITX=1,5
        R=R+DR
        CALL WAVMAT(W,N,R,P,VL,IV,ERED,EINT,CENT,RMLMDA,DIAG,
     1              MXLAM,NPOTL,IPRINT)
        V=W(1)
        IF (V*YL.LT.0.D0) GOTO 1205

 1202 CONTINUE

      DR=-DR
      R=RSV
      DO 1203 ITX=1,5
        R=R+DR
        CALL WAVMAT(W,N,R,P,VL,IV,ERED,EINT,CENT,RMLMDA,DIAG,
     1              MXLAM,NPOTL,IPRINT)
        V=W(1)
        IF (V*YL.LT.0.D0) GOTO 1205
 1203 CONTINUE

      WRITE(6,620)
  620 FORMAT(/' WKB.  * * *  CRASH IN REGULA-FALSI.  GIVING UP.')
      STOP

 1205 XR=R
      YR=V
 1210 SLOPE=(YR-YL)/(XR-XL)
      XINT=YL-SLOPE*XL
      XNEW=-XINT/SLOPE
      CALL WAVMAT(W,N,XNEW,P,VL,IV,ERED,EINT,CENT,RMLMDA,DIAG,
     1            MXLAM,NPOTL,IPRINT)
      YNEW=W(1)
      IT=IT+1
      IF (ABS(YNEW).GT.ECNV) GOTO 1211

 1215 DR=XR-XL
      IF (IPRINT.GE.10) WRITE(6,621) IT,XNEW,DR,YNEW
  621 FORMAT(' WKB: REGULA-FALSI CONVERGED. IT,R,DR,V =',I4,3F10.4)
      R=XNEW
      GOTO 1009

 1211 IF (YNEW*YR.GT.0.D0) GOTO 1212

      IF (YNEW*YL.GT.0.D0) GOTO 1213

      WRITE(6,622) XL,XNEW,XR,YL,YNEW,YR
  622 FORMAT(/' WKB.  IMPOSSIBLE X(L,NEW,R) AND Y(L,NEW,R)=',6E12.4)
      STOP

 1212 YR=YNEW
      XR=XNEW
      GOTO 1220

 1213 YL=YNEW
      XL=XNEW
 1220 IF (ABS(XR-XL).LE.RCNV) GOTO 1215

C  ALLOW FOR TWICE AS MANY ITERATIONS AS NEWTON-RAPHSON.
      IF (IT.LT.2*ITMX) GOTO 1210

      WRITE(6,623) IT,XL,XNEW,XR,YL,YNEW,YR
  623 FORMAT(' WKB: REGULA-FALSI START FAILED TO CONVERGE. IT=',I4/
     1       16X,  'X(L,NEW,R) AND Y(L,NEW,R)=',6E12.4)
C
C  GET WKB PHASE SHIFT BY PACK'S GAUSS-MEHLER QUADRATURE
C
C  FORCE NGMP TO REASONABLE VALUES IF NECESSARY.
 1009 NSTART=MAX(NGMP(1),3)
      NADD=MAX(NGMP(2),1)
      NHI=MAX(NGMP(3),NSTART+3*NADD)
      RMIN=R
      DR0=R
      DWVEC=WVEC(1)
      XKR=DWVEC*DR0
      DO 2000 NPOINT=NSTART,NHI,NADD
        NPSV=NPOINT
        X2NP1=DBLE(2*NPOINT+1)
        TOTAL=0.D0
        XJ=0.D0
        DO 2100 J=1,NPOINT
          XJ=XJ+1.D0
          X=COS(XJ*PI/X2NP1)
          X2=X*X
          WT=(1.D0-X2)*PI/X2NP1
          XCOMP=SQRT(1.D0-X2)
          R=DR0/X
          CALL WAVMAT(W,N,R,P,VL,IV,ERED,EINT,CENT,RMLMDA,DIAG,
     1                MXLAM,NPOTL,IPRINT)
C  WAVMAT GIVES NEGATIVE OF WHAT WE WANT
          W(1)=-W(1)
C  GUARD AGAINST SQUARE ROOTS OF NEGATIVE DW
          IF (W(1).GE.0.D0) GOTO 2109
C  JUDGE AS ROUND-OFF ERROR IF ABS(W) LE. 0.001*ERED
          IF (ABS(W(1)).LE.1.D-3*ERED) GOTO 2108

          WRITE(6,696) R,W(1)
  696     FORMAT('  * * * ERROR.  WKB IN CLASSICALLY FORBIDDEN REGION.',
     1           '  R, W & =',2E16.6)

 2108     W(1)=0.D0
 2109     DW=W(1)
          F=(SQRT(DW)/(DWVEC*XCOMP)-1.D0)/X2
 2100     TOTAL=TOTAL+WT*F
        ETA=XKR*TOTAL+(SQRT(DCENT)-XKR)*PI*.5D0
        IF (NPOINT.GT.NSTART) GOTO 2200

C  ON FIRST ITERATION, GET SET FOR CONVERGENCE TEST.
C  SUBTRACT OUT AN INTEGRAL NUMBER OF 2*PI TO NORMALIZE
        NPI=ETA/PI2
        IF (ETA.LT.0.D0) NPI=NPI-1
        PIMIN=DBLE(NPI)*PI2
        ETA=ETA-PIMIN
        ETAOLD=ETA
        GOTO  2000

C  TEST FOR CONVERGENCE
 2200   ETA=ETA-PIMIN
        X2=ABS(ETA-ETAOLD)
        IF (X2.LE.DTOL) GOTO 2900

        X=ETAOLD
        ETAOLD=ETA
 2000 CONTINUE

C  NOT CONVERGED IF THIS POINT IS REACHED. . .
      NPOINT=NPSV
      NM1=NPOINT-NADD
      WRITE(6,695) NPI,DTOL, NM1,X, NPOINT,ETA
  695 FORMAT(/' * * * WARNING.  NO CONVERGENCE OF GAUSS-MEHLER ',
     1       'INTEGRATION.  NPI =',I4,'   STEST =',E12.4/
     A       (15X,'FOR',I4,'  GAUSS POINTS, ETA-NPI*(2*PI) =',F12.7) )
C  SET CONVERGENCE FLAG, IF CONVERGENCE IS REALLY POOR
      IF (X2.GT.5.D0*DTOL) CONV=-1.D0

 2900 IF (IPRINT.GE.4) WRITE(6,612) NPSV,X2,DR0,NPI,ETA
  612 FORMAT(/'  * * * NOTE.  WKB PHASE SHIFT BY',I4,'-POINT QUAD,'
     1       '  TOL =',E12.4,', R0 =',F8.4,',  ETA IS',I5,'*(2*PI) +',
     2       F9.5)
C
C  CONVERT PHASE SHIFT TO SREAL, SIMAAG / RESTORE FOR RETURN
      SREAL(1)=COS(2.D0*ETA)
      SIMAG(1)=SIN(2.D0*ETA)
      CENT(1)=CSAVE
      RETURN
C
      END
