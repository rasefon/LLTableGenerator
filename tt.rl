``
token: tPlus, tMul, tLp, tRp, tEnd
token: tId
# nil is predefined keyword.
``
$Start: E
E:    T,E1
E1:   tPlus,T,E1
E1:   nil
T:    F,T1
T1:   tMul,F,T1
T1:   nil
F:    F1
F1:   tLp,E,tRp
F1:   tId
