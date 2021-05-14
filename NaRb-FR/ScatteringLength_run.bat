set indir=".\ScatteringLength_Input\"
set outdir=".\ScatteringLength_Output\"
set sumdir=".\Sum\"
for /R %indir% %%f in (*.txt) do (
    molscat-NaRb < %%f > %outdir%%%~nxf
    rename fort.1 %%~nf-sum.txt
    move %%~nf-sum.txt %sumdir%
)
pause