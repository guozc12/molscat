      SUBROUTINE FINDRX(ENERGY,EINT,CENT,NNRG,N,CM2RU,
     1                  RMAX,RSTOP,EREF,IRXSET,IPRINT)
C  Copyright (C) 2019 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)

C  COMMON BLOCK THAT CARRIES PROPAGATION INFORMATION
      INTEGER MXSEG,IDIR,IFLG,NSEGS,NSTEPS
      DOUBLE PRECISION RST,REND,DRPR,STEPS
      PARAMETER (MXSEG=3)
      COMMON /PRPDTA/ RST(MXSEG),REND(MXSEG),DRPR(MXSEG),
     1                IDIR(MXSEG),IFLG(MXSEG),NSEGS,NSTEPS(MXSEG)
C
C  SUBROUTINE TO SCAN INPUT ENERGIES AND THRESHOLDS TO DETERMINE
C  A SAFE RMAX WHICH IS OUTSIDE THE CENTRIFUGAL BARRIER FOR
C  ALL COMBINATIONS. ALSO FIND THE LARGEST VALUE OF NOPEN
C  TO SAFEGUARD AGAINST SHRINKING THE BASIS SET TOO FAR.
C
      DIMENSION ENERGY(NNRG),EINT(N),CENT(N)
C
      RSTOP=RMAX
      DO 200 J=1,NNRG
        ERED=(ENERGY(J)+EREF)*CM2RU
        DO 100 I=1,N
          DIF=ERED-EINT(I)
          IF (DIF.LT.0.D0) GOTO 100
          IF (IRXSET.LE.0) GOTO 100
          RCENT=SQRT(CENT(I)/DIF)
          RSTOP=MAX(RSTOP,RCENT)
  100   CONTINUE
  200 CONTINUE

      IF (RSTOP.GT.RMAX .AND. IPRINT.GE.9) WRITE(6,601) RSTOP
  601 FORMAT(/'  RMAX INCREASED TO',1PG13.6,' FOR THIS SYMMETRY BLOCK',
     1       ' TO ENSURE THAT OPEN-CHANNEL MATCHING'/'  OCCURS BEYOND',
     2       ' THE CENTRIFUGAL BARRIER FOR ALL ENERGIES')
      RETURN
      END
