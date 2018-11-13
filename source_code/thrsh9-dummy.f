      SUBROUTINE THRSH9(IREF,MONQN,NQN1,EREF,IPRINT)
C  Copyright (C) 2018 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION MONQN(NQN1)
C
C  USER-SUPPLIED ROUTINE TO SUPPLY AN INCOMING THRESHOLD ENERGY
C  BASED ON MONOMER QUANTUM NUMBERS.
C
C  SPECIFICATION CHANGED MAY 2015
C
C  NOW EXPECTS A SET OF MONOMER QUANTUM NUMBERS IN THE ARRAY MONQN
C  ONLY CALLED IF MONQN(1) IS NOT -99999 (WHICH IS THE DEFAULT).
C  UNDER OTHER CONDITIONS IT IS NOT NECESSARY TO IMPLEMENT IT
C  AND THIS DUMMY ROUTINE CAN BE USED INSTEAD.
C
C  THE PURPOSE OF THRSH9 IS TO ALLOW THE USER TO SPECIFY AN ORIGIN
C  OF ENERGY USED FOR THE ENERGY ARRAY (AND EMIN AND EMAX),
C  IF THE NORMAL IREF MECHANISM (SPECIFYING THE ENERGY WITH
C  RESPECT TO THE THRESHOLD ENERGY OF A CHANNEL THAT APPEARS IN
C  THE COUPLED EQUATIONS) IS NOT GENERAL ENOUGH.
C
C  A FUNCTIONAL THRSH9 ROUTINE WOULD USUALLY BE IMPLEMENTED AS AN
C  ENTRY POINT IN A BASE9 ROUTINE, SO THAT IT CAN USE QUANTITIES
C  READ IN BASE AND BASE9.
C
      WRITE(6,*) ' EMPTY SUBROUTINE THRSH9 CALLED.'
      WRITE(6,*) ' MONQN(1).NE.-99999 REQUIRES A USER-SUPPLIED THRSH9.'
      STOP
      RETURN
      END

