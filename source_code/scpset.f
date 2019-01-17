      SUBROUTINE SCPSET(IPRSEG,RBSEG,RESEG,DRSEG,STPSEG,
     1                  TOLSEG,CAYSEG,POWSEG)
C  Copyright (C) 2018 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3

C  CR Le Sueur Dec 2018
      IMPLICIT NONE

C  THIS ROUTINE SETS UP ARRAYS OF VALUES FOR CONTROLLING HOW EACH
C  SEGMENT OF A SCATTERING CALCULATION IS CARRIED OUT

      DOUBLE PRECISION, INTENT(OUT) :: RBSEG(2),RESEG(2),DRSEG(2),
     1                                 TOLSEG(2),STPSEG(2),CAYSEG(2),
     2                                 POWSEG(2)
      INTEGER,          INTENT(OUT) :: IPRSEG(2)
C
C  COMMON BLOCK FOR CONTROL OF PROPAGATION SEGMENTS
      COMMON /RADIAL/ RMNINT,RMXINT,RMID,RMATCH,DRS,DRL,STEPS,STEPL,
     1                POWRS,POWRL,TOLHIS,TOLHIL,CAYS,CAYL,UNSET,
     2                IPROPS,IPROPL,NSEG

      DOUBLE PRECISION RMNINT,RMXINT,RMID,RMATCH,
     1                 STEPS,STEPL,TOLHIS,TOLHIL,DRS,DRL,CAYS,CAYL,
     1                 POWRS,POWRL,UNSET
      INTEGER          IPROPS,IPROPL,NSEG

      IPRSEG(1)=IPROPS
      RBSEG(1)=RMNINT
      RESEG(NSEG)=RMXINT
      CAYSEG(1)=CAYS
      DRSEG(1)=DRS
      POWSEG(1)=POWRS
      STPSEG(1)=STEPS
      TOLSEG(1)=TOLHIS

      IF (NSEG.EQ.2) THEN
        IPRSEG(2)=IPROPL
        RESEG(1)=MIN(RMID,RMXINT)
        RBSEG(2)=MAX(RMNINT,RMID)
C RMNINT -> MIN(RMID,RMXINT); MAX(RMNINT,RMID) -> RMXINT
C RMNINT RMID RMXINT: OK (2)
C RMID RMNINT RMXINT: RMNINT -> RMID (NOT EXECUTED); RMNINT -> RMXINT (YES)
C RMNINT RMXINT RMID: RMNINT -> RMXINT (YES);          RMID -> RMXINT (NOT EXECUTED)
        IF (RMID.LT.RMNINT) THEN
          RESEG(1)=RBSEG(2)
        ELSEIF (RMID.GT.RMXINT) THEN
          RBSEG(2)=RESEG(1)
        ENDIF
        CAYSEG(2)=CAYL
        DRSEG(2)=DRL
        POWSEG(2)=POWRL
        STPSEG(2)=STEPL
        TOLSEG(2)=TOLHIL
      ENDIF

      RETURN
      END
