``
token: a, b, c, d, e, f
``
$Start: S
S:    a, S, e
S:    B
S:    D
B:    b, B, e
B:    C
C:    c, C, e
C:    d
D:    E, F
E:    nil
F:    f, F
F:    nil
