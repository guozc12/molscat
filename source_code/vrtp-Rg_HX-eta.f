      SUBROUTINE VRTP(IDERIV,R,V)
C  Copyright (C) 2018 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      USE angles
C  THIS VERSION OF VRTP SUBROUTINE DESIGNED SPECIFICALLY FOR H6(4,3,X)
C  POTENTIALS OF Ar-HF AND Ar-HCl
C
C  IT CAN BE USED WITH ETA=0.D0 TO EVALUATE OLDER POTENTIALS FOR OTHER
C  RARE GASES
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      SAVE
C  CHANGED TO USE ANGLES MODULE ON 16-08-2018
C     COMMON/ANGLES/COSANG(MXANG),FACTOR,IHOMO,ICNSYM,IHOMO2,ICNSY2
      COMMON/POTL/POT(100)
      COMMON/VIB/ETA

      IF (IDERIV.NE.0) GOTO 100
      V=EXTPOT(R,COSANG(1))
      RETURN
C
  100 IF (IDERIV.GT.0) THEN
        WRITE(6,601)
  601   FORMAT('  *** ERROR IN VRTP - POTENTIAL DERIVATIVES'//
     1         ' NOT SUPPORTED BY THIS VERSION')
        STOP
      ENDIF
C
      IF (IDERIV.LT.-1) RETURN

      READ(5,*) NPOT
      DO 200 I=1,NPOT
        READ(5,*) POT(I)
  200 CONTINUE
      READ(5,*) ETA

      CALL EXTINT
      R=1.D0
      V=1.D0

      RETURN
      END
