      module pot_data_Tiemann
C  Copyright (C) 2018 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C  MODULE CONTAINING PARAMETERS OF A PAIR OF TIEMANN-STYLE
C  POTENTIAL CURVES OF AN ALKALI DIMER
C  UNITS USED ARE CM-1 AND POWERS OF ANGSTROM
C
C  POTENTIAL 1 IS SINGLET X, POTENTIAL 2 IS TRIPLET A
C
      USE physical_constants
      SAVE
C
C  KCS PARAMETERS FROM FERBER ET AL., PRA 88, 012516 (2013)
C
      CHARACTER(72) :: POTNAM = 
     X ' Rb2 potential from Strauss et al., PRA 82, 052514 (2010)'
C
C  PRINT CONTROL (FOR POTENTIAL ROUTINE ONLY)
C  0 = SILENT, 1 = TITLE, 2 = INTERNALLY CALCULATED PARAMETERS
C
      INTEGER IPRINT/2/
C
C  NUMBER OF TERMS IN POWER SERIES FOR CENTRAL REGION
C  (NOTE: HIGHEST POWER + 1 BECAUSE ARRAYS START AT 0)
C
      INTEGER :: NA(2) = (/26,13/)
C
C  EXPANSION COEFFICIENTS:
C  NOTE THAT A(0,NV) IS CALCULATED INTERNALLY
C  AND THE INPUT VALUE IS JUST PRINTED FOR COMPARISON
C
      DOUBLE PRECISION :: A(0:25,2) = RESHAPE((/
     X -3993.592873D0, 
     X 0.000000000000000000D0,
     X 0.282069372972346137D5,
     X 0.560425000209256905D4,
     X -0.423962138510562945D5,
     X -0.598558066508841584D5,
     X -0.162613532034769596D5,
     X -0.405142102246254944D5,
     X  0.195237415352729586D6,
     X  0.413823663033582852D6,
     X -0.425543284828921501D7,
     X  0.546674790157210198D6,
     X  0.663194778861331940D8,
     X -0.558341849704095051D8,
     X -0.573987344918535471D9,
     X  0.102010964189156187D10,
     X  0.300040150506311035D10,
     X -0.893187252759830856D10,
     X -0.736002541483347511D10,
     X  0.423130460980355225D11,
     X -0.786351477693491840D10,
     X -0.102470557344862152D12,
     X  0.895155811349267578D11,
     X  0.830355322355692902D11,
     X -0.150102297761234375D12,
     X  0.586778574293387070D11,
     X
     X -241.503352D0,
     X -0.672503402304666542D0,
     X  0.195494577140503543D4,
     X -0.141544168453406223D4,
     X -0.221166468149940465D4,
     X  0.165443726445793004D4,
     X -0.596412188910614259D4,
     X  0.654481694231538040D4,
     X  0.261413416681972012D5,
     X -0.349701859112702878D5,
     X -0.328185277155018630D5,
     X  0.790208849885562522D5,
     X -0.398783520249289213D5,
     X  0.D0, 0.D0, 0.D0, 0.D0, 0.D0, 0.D0, 0.D0,
     X  0.D0, 0.D0, 0.D0, 0.D0, 0.D0, 0.D0 /), SHAPE(A))
C
C  RM AND B USED IN DEFINITION OF XI,
C  SHORT-RANGE AND LONG-RANGE MATCHING POINTS,
C  PARAMETERS OF SHORT-RANGE POTENTIAL ASR + BSR*R**NSR.
C
C  NOTE THAT ASR AND BSR ARE NORMALLY CALCULATED INTERNALLY
C  TO MATCH THE POWER-SERIES AND ITS DERIVATIVE AT RSR.
C  AND THE INPUT VALUES ARE JUST PRINTED FOR COMPARISON.
C  HOWEVER, IF MATCHD IS /.FALSE./, BSR IS LEFT AT ITS
C  INPUT VALUE AND ASR IS CALCULATED FROM IT.
C  THIS IS NEEDED E.G. FOR RBCS 2012, WHERE THE PUBLISHED VALUE
C  OF BSR IS NOT AS REQUIRED TO MATCH THE DERIVATIVE.
C
       DOUBLE PRECISION ::
     X  RM(2)  = (/4.209912760D0, 6.0933451D0/),
     X  B(2)   = (/ -0.13D0, -0.33D0/),
     X  RSR(2) = (/3.126D0, 5.07D0/),
     X  RLR(2) = (/11.00D0, 11.00D0/),
     X  NSR(2)  = (/4.533895D0, 4.5338950D0/),
     X  ASR(2) = (/-0.638904880D4, -0.619088543D3/),
     X  BSR(2) = (/0.112005361D7, 0.956231677D6/)
C
      LOGICAL :: MATCHD = .TRUE.
C
C  DISPERSION COEFFICIENTS
C
       DOUBLE PRECISION ::
     X  C6 = 0.2270032D8,
     X  C8 = 0.7782886D9,
     X  C10 = 0.2868869D11
C
C  EXTRA -C26/R**26 TERM PRESENT IN LONG-RANGE POTENTIAL FOR RB2
C
       INTEGER ::
     X  NEX = 26
       DOUBLE PRECISION ::
     X  CEX = 0.2819810D26
C
C  PARAMETERS OF EXCHANGE POTENTIAL
C  NOTE THAT BETA AND GAMMA ARE CONVENTIONALLY LINKED.
C  THREE OPTIONS ARE IMPLEMENTED HERE:
C        GAMBET = 0: USE INPUT VALUES UNCHANGED
C        GAMBET = 1: CALCULATE GAMMA FROM BETA
C        GAMBET = 2: CALCULATE BETA FROM GAMMA
C  IF CHANGED, THE INPUT VALUE IS PRINTED FOR COMPARISON
C
       INTEGER :: GAMBET = 1
       DOUBLE PRECISION ::
     X  EXSIGN(2) = (/-1.D0, +1.D0/),
     X  AEX = 0.1317786D5,
     X  GAMMA = 5.317689D0,
     X  BETA = 2.093816D0
C
C  DISTANCE UNITS TO BE USED BY MOLSCAT/BOUND:
C  1.D0 FOR ANGSTROM, 0.529... FOR BOHR, ETC.
C
      DOUBLE PRECISION :: RUNITM = bohr_to_Angstrom
      CHARACTER(8)     :: LENUNT = 'BOHR'
C
C  COMMON BLOCK TO BE USED FOR ANY PARAMETERS TO BE CHANGED BY
C  OTHER ROUTINES, FOR EXAMPLE WHEN LEAST-SQUARES FITTING
C
      COMMON/POTEXT/NSR
C
      end module pot_data_Tiemann
