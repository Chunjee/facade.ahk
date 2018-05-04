#Include <Is>
#Include <Type>
#Include <IsFuncObj>
#Include <_IsArray>
#Include <_Validate>

; This is a redundant Array FoldL definition to avoid circular dependencies.
_Op_ArrayFoldL(Func, Init, Array)
{
    local
    A     := Init
    Index := 1
    while (Index <= Array.Count())
    {
        A := Func.Call(A, Array[Index])
        ++Index
    }
    return A
}

; This is a redundant Array FoldL1 definition to avoid circular dependencies.
_Op_ArrayFoldL1(Func, Array)
{
    local
    A     := Array[1]
    Index := 2
    while (Index <= Array.Count())
    {
        A := Func.Call(A, Array[Index])
        ++Index
    }
    return A
}

Op_Bin(X)
{
    local
    Sig := "Op_Bin(X)"
    _Validate_IntegerArg(Sig, "X", X)
    static Digits := {0x0 << 60: "0000"
                     ,0x1 << 60: "0001"
                     ,0x2 << 60: "0010"
                     ,0x3 << 60: "0011"
                     ,0x4 << 60: "0100"
                     ,0x5 << 60: "0101"
                     ,0x6 << 60: "0110"
                     ,0x7 << 60: "0111"
                     ,0x8 << 60: "1000"
                     ,0x9 << 60: "1001"
                     ,0xA << 60: "1010"
                     ,0xB << 60: "1011"
                     ,0xC << 60: "1100"
                     ,0xD << 60: "1101"
                     ,0xE << 60: "1110"
                     ,0xF << 60: "1111"}
    static Mask := 0xF << 60
    VarSetCapacity(Result, 132)
    Result := "0b"
    loop 16
    {
        Result .= Digits[X << 4 * (A_Index - 1) & Mask]
    }
    return Result
}

Op_Hex(X)
{
    local
    Sig := "Op_Hex(X)"
    _Validate_IntegerArg(Sig, "X", X)
    return Format("0x{:016X}", X)
}

_Op_CCeil(X)
{
    local
    return DllCall("msvcrt\ceil", "Double", X, "Double")
}

_Op_CFloor(X)
{
    local
    return DllCall("msvcrt\floor", "Double", X, "Double")
}

Op_Round(X, N := 0)
{
    local
    Sig := "Op_Round(X [, N])"
    _Validate_NumberArg(Sig, "X", X)
    _Validate_IntegerArg(Sig, "N", N)
    Multiplier    := N == 0 ? 1 : 10 ** N
    MovedPoint    := X * Multiplier
    AbsMod        := Abs(Op_Mod(MovedPoint, 1))
    ; DLLCalls are used to avoid integer overflow.
    Rounded       := AbsMod < 0.5 ? X >= 0 ? _Op_CFloor(MovedPoint) : _Op_CCeil(MovedPoint)
                   : AbsMod > 0.5 ? X >= 0 ? _Op_CCeil(MovedPoint)  : _Op_CFloor(MovedPoint)
                   : Op_Mod(_Op_CCeil(MovedPoint), 2) == 0 ? _Op_CCeil(MovedPoint) : _Op_CFloor(MovedPoint)
    RestoredPoint := Rounded / Multiplier
    if (N > 0)
    {
        ; Format does not work.
        Halves := StrSplit(RestoredPoint, ".")
        Halves[2] := SubStr(Halves[2], 1, N)
        while (StrLen(Halves[2]) < N)
        {
            Halves[2] .= "0"
        }
        Result := Halves[1] . "." . Halves[2]
    }
    else
    {
        Result := Op_Integer(RestoredPoint)
    }
    return Result
}

Op_Integer(X)
{
    local
    Sig := "Op_Integer(X)"
    if (X ~= "iS)^[ \t]*[-+]?0(?:b[01]+|x[0-9A-F]+)[ \t]*$")
    {
        static Digits := {"0":  0
                         ,"1":  1
                         ,"2":  2
                         ,"3":  3
                         ,"4":  4
                         ,"5":  5
                         ,"6":  6
                         ,"7":  7
                         ,"8":  8
                         ,"9":  9
                         ,"A": 10
                         ,"B": 11
                         ,"C": 12
                         ,"D": 13
                         ,"E": 14
                         ,"F": 15}
        RegExMatch(X, "OiS)(?<Sign>[-+]?)0(?<Radix>[bx])(?<Number>[0-9A-F]+)", Match)
        BitWidth := Match.Value("Radix") = "b" ? 1 : 4
        Number := Match.Value("Number")
        X := 0
        while (Number != "")
        {
            X <<= BitWidth
            X |= Digits[SubStr(Number, 1, 1) . ""]
            Number := SubStr(Number, 2)
        }
        X := Match.Value("Sign") == "-" ? -X : X
    }
    else if (X ~= "iS)^[ \t]*[-+]?(?:\d+e[-+]?\d+|inf(?:inity)?|nan(?:\(ind\))?)[ \t]*$")
    {
        X := Op_Float(X)
    }
    _Validate_NumberArg(Sig, "X", X)
    VarSetCapacity(Inf, 8)
    NumPut(0x7FF0000000000000, Inf,, "UInt64")
    Inf := NumGet(Inf,, "Double")
    if (X == -Inf or X == Inf or X != X)
    {
        throw Exception("Value Defect", -1
                       ,Format("{1}  X cannot be converted to an Integer.  X is {2}.", Sig, _Validate_ValueRepr(X)))
    }
    return X & -1
}

Op_Float(X)
{
    local
    Sig := "Op_Float(X)"
    if (X ~= "iS)^[ \t]*[-+]?0(?:b[01]+|x[0-9A-F]+)[ \t]*$")
    {
        X := Op_Integer(X)
    }
    else if (X ~= "iS)^[ \t]*[-+]?\d+e[-+]?\d+[ \t]*$")
    {
        X := StrReplace(X, "e", ".e")
    }
    else if (X ~= "iS)^[ \t]*[-+]?inf(?:inity)?[ \t]*$")
    {
        VarSetCapacity(Inf, 8)
        NumPut(0x7FF0000000000000, Inf,, "UInt64")
        Inf := NumGet(Inf,, "Double")
        X := InStr(X, "-") ? -Inf : Inf
    }
    else if (X ~= "iS)^[ \t]*[-+]?nan(?:\(ind\))?[ \t]*$")
    {
        VarSetCapacity(NaN, 8)
        ; This works correctly despite the sign bit being set.
        NumPut(0xFFF8000000000000, NaN,, "UInt64")
        NaN := NumGet(NaN,, "Double")
        X := NaN
    }
    _Validate_NumberArg(Sig, "X", X)
    return X + 0.0
}

Op_GetProp(Prop, Obj)
{
    local
    Sig := "Op_GetProp(Prop, Obj)"
    _Validate_IdentifierArg(Sig, "Prop", Prop)
    _Validate_ObjArg(Sig, "Obj", Obj)
    return Obj[Prop]
}

_Op_HasGetMethod(Obj)
{
    local
    try
    {
        Result := IsFuncObj(Obj.Get)
    }
    catch
    {
        Result := false
    }
    return Result
}

Op_Get(Key, Obj)
{
    local
    Sig := "Op_Get(Key, Obj)"
    _Validate_ObjArg(Sig, "Obj", Obj)
    try
    {
        if (Type(Obj) == "Object")
        {
            if (not ObjHasKey(Obj, Key))
            {
                throw Exception("Key Defect")
            }
            Result := ObjRawGet(Obj, Key)
        }
        else if (_Op_HasGetMethod(Obj))
        {
            Result := Obj.Get(Key)
        }
        else
        {
            Result := Obj[Key]
        }
    }
    catch E
    {
        if (E.Message == "Key Defect")
        {
            throw Exception("Key Defect", -1
                           ,Format("{1}  Key not found.  Key is {2}.", Sig, _Validate_ValueRepr(Key)))
        }
        else
        {
            throw E
        }
    }
    return Result
}

Op_Expt(X, Y)
{
    local
    Sig := "Op_Expt(X, Y)"
    _Validate_NumberArg(Sig, "X", X)
    _Validate_NumberArg(Sig, "Y", Y)
    if (X < 0 and Y != Op_Integer(Y))
    {
        throw Exception("Value Defect", -1
                       ,Format("{1}  Negative base with a fractional exponent.  X is {2} and Y is {3}.", Sig, X, Y))
    }
    if (X == 0 and Y < 0)
    {
        throw Exception("Division by Zero Defect", -1
                       ,Format("{1}  X is {2} and Y is {3}.", Sig, X, Y))
    }
    return X ** Y
}

Op_BNot(X)
{
    local
    Sig := "Op_BNot(X)"
    _Validate_IntegerArg(Sig, "X", X)
    return X ^ -1
}

_Op_MulAux(X, Y)
{
    local
    return X * Y
}

Op_Mul(Numbers*)
{
    local
    Sig := "Op_Mul(Numbers*)"
    _Validate_NumberArgs(Sig, Numbers)
    return _Op_ArrayFoldL(Func("_Op_MulAux"), 1, Numbers)
}

_Op_DivAux(X, Y)
{
    local
    if (Y == 0)
    {
        throw Exception("Division by Zero Defect")
    }
    return X / Y
}

Op_Div(Numbers*)
{
    local
    Sig := "Op_Div(Numbers*)"
    _Validate_NumberArgs(Sig, Numbers)
    try
    {
        if (Numbers.Count() == 0)
        {
            throw Exception("Arity Defect")
        }
        else if (Numbers.Count() == 1)
        {
            if (Numbers[1] == 0)
            {
                throw Exception("Division by Zero Defect")
            }
            Result := 1 / Numbers[1]
        }
        else
        {
            Result := _Op_ArrayFoldL1(Func("_Op_DivAux"), Numbers)
        }
    }
    catch E
    {
        throw Exception(E.Message, -1
                       ,Sig)
    }
    return Result
}

Op_FloorDiv(X, Y)
{
    local
    Sig := "Op_FloorDiv(X, Y)"
    _Validate_NumberArg(Sig, "X", X)
    _Validate_DivisorArg(Sig, "Y", Y)
    return Floor(X / Y)
}

Op_Mod(X, Y)
{
    local
    Sig := "Op_Mod(X, Y)"
    _Validate_NumberArg(Sig, "X", X)
    _Validate_DivisorArg(Sig, "Y", Y)
    return X - Y * Op_FloorDiv(X, Y)
}

_Op_AddAux(X, Y)
{
    local
    return X + Y
}

Op_Add(Numbers*)
{
    local
    Sig := "Op_Add(Numbers*)"
    _Validate_NumberArgs(Sig, Numbers)
    return _Op_ArrayFoldL(Func("_Op_AddAux"), 0, Numbers)
}

_Op_SubAux(X, Y)
{
    local
    return X - Y
}

Op_Sub(Numbers*)
{
    local
    Sig := "Op_Sub(Numbers*)"
    _Validate_NumberArgs(Sig, Numbers)
    if (Numbers.Count() == 0)
    {
        throw Exception("Arity Defect", -1
                       ,Sig)
    }
    else if (Numbers.Count() == 1)
    {
        Result := 0 - Numbers[1]
    }
    else
    {
        Result := _Op_ArrayFoldL1(Func("_Op_SubAux"), Numbers)
    }
    return Result
}

Op_BAsl(X, N)
{
    local
    Sig := "Op_BAsl(X, N)"
    _Validate_IntegerArg(Sig, "X", X)
    _Validate_NonNegIntegerArg(Sig, "N", N)
    return N >= 64 ? 0 : X << N
}

Op_BAsr(X, N)
{
    local
    Sig := "Op_BAsr(X, N)"
    _Validate_IntegerArg(Sig, "X", X)
    _Validate_NonNegIntegerArg(Sig, "N", N)
    return N >= 64 ? X >= 0 ? 0 : -1 : X >> N
}

Op_BLsr(X, N)
{
    local
    Sig := "Op_BLsr(X, N)"
    _Validate_IntegerArg(Sig, "X", X)
    _Validate_NonNegIntegerArg(Sig, "N", N)
    return N >= 64 ? 0 : X >> N & Op_BNot(1 << 63 >> N << 1)
}

_Op_BAndAux(X, Y)
{
    local
    return X & Y
}

Op_BAnd(Integers*)
{
    local
    Sig := "Op_BAnd(Integers*)"
    _Validate_IntegerArgs(Sig, Integers)
    return _Op_ArrayFoldL(Func("_Op_BAndAux"), -1, Integers)
}

_Op_BXorAux(X, Y)
{
    local
    return X ^ Y
}

Op_BXor(Integers*)
{
    local
    Sig := "Op_BXor(Integers*)"
    _Validate_IntegerArgs(Sig, Integers)
    return _Op_ArrayFoldL(Func("_Op_BXorAux"), 0, Integers)
}

_Op_BOrAux(X, Y)
{
    local
    return X | Y
}

Op_BOr(Integers*)
{
    local
    Sig := "Op_BOr(Integers*)"
    _Validate_IntegerArgs(Sig, Integers)
    return _Op_ArrayFoldL(Func("_Op_BOrAux"), 0, Integers)
}

_Op_Eq(ScalarEq, A, B)
{
    ; This function is necessary because performing an ordered comparison on
    ; types with undefined order should be a defect (even if their identities
    ; are equal), but performing an (in)equality test on all types should be
    ; valid.
    local
    TypeA := _Validate_TypeRepr(A)
    TypeB := _Validate_TypeRepr(B)
    if (ScalarEq.Call(A, B))
    {
        ; Identity, numeric, and string equality are conflated.
        Result := true
    }
    else if (   TypeA == "Stream" and TypeB == "Stream"
             or TypeA == "List"   and TypeB == "List"
             or _IsArray(A)       and _IsArray(B))
    {
        ; Arrays and Objects (dictionaries) are conflated, so comparing Arrays
        ; must come before comparing dictionaries.
        AEnum  := A._NewEnum()
        BEnum  := B._NewEnum()
        Result := true
        loop
        {
            AHadValue := AEnum.Next(_, AValue)
            BHadValue := BEnum.Next(_, BValue)
            if (AHadValue and BHadValue)
            {
                Result := _Op_Eq(ScalarEq, AValue, BValue)
            }
        }
        until (not Result or not AHadValue or not BHadValue)
        Result := Result and not AHadValue and not BHadValue
    }
    else if (   TypeA == "Dict"   and TypeB == "Dict"
             or TypeA == "Object" and TypeB == "Object")
    {
        Result := A.Count() == B.Count()
        AEnum  := A._NewEnum()
        while (Result and AEnum.Next(Key, Value))
        {
            Result := B.HasKey(Key) and Op_Eq(Value, Op_Get(Key, B))
        }
    }
    else
    {
        Result := false
    }
    return Result
}

_Op_Cmp(ScalarCmp, A, B)
{
    ; This function can return -1 (less than), 0 (equal), 1 (greater than), or
    ; "" (incomparable).  The existence of NaN makes floating point values
    ; partially ordered and the existence of non-empty disjoint sets makes
    ; dictionaries partially ordered, so an incomparable value is necessary.
    local
    TypeA := _Validate_TypeRepr(A)
    TypeB := _Validate_TypeRepr(B)
    if (not Is(A, "object") and not Is(B, "object"))
    {
        ; Numeric and string comparison are conflated.
        Result := ScalarCmp.Call(A, B)
    }
    else if (   TypeA == "Stream" and TypeB == "Stream"
             or TypeA == "List"   and TypeB == "List"
             or _IsArray(A)       and _IsArray(B))
    {
        ; Arrays and Objects (dictionaries) are conflated, so comparing Arrays
        ; must come before comparing dictionaries.
        AEnum  := A._NewEnum()
        BEnum  := B._NewEnum()
        Result := 0
        loop
        {
            AHadValue := AEnum.Next(_, AValue)
            BHadValue := BEnum.Next(_, BValue)
            if (AHadValue and BHadValue)
            {
                Result := _Op_Cmp(ScalarCmp, AValue, BValue)
            }
        }
        until (not Result == 0 or not AHadValue or not BHadValue)
        Result := Result == 0 ? AHadValue ?  1
                              : BHadValue ? -1
                              : 0
                : Result
    }
    else if (   TypeA == "Dict"   and TypeB == "Dict"
             or TypeA == "Object" and TypeB == "Object")
    {
        Result := (A.Count() > B.Count()) - (A.Count() < B.Count())
        if (Result == 1)
        {
            LesserEnum := B._NewEnum()
            Greater    := A
        }
        else
        {
            ; This also works in the = case.
            LesserEnum := A._NewEnum()
            Greater    := B
        }
        while (Result != "" and LesserEnum.Next(Key, Value))
        {
            Result := Greater.HasKey(Key) and Op_Eq(Value, Op_Get(Key, Greater)) ? Result
                    : ""
        }
    }
    else
    {
        throw Exception("Type Defect",
                       ,Format("Ordered comparison is undefined between instances of {1} and {2}.", TypeA, TypeB))
    }
    return Result
}

_Op_TestArgs(Test, Args)
{
    local
    Result := true
    Index  := 1
    while (Result and Index + 1 <= Args.Count())
    {
        Result := Test.Call(Args[Index], Args[Index + 1])
        ++Index
    }
    return Result
}

_Op_CsEq(A, B)
{
    local
    return A == B
}

_Op_CsCmp(A, B)
{
    local
    if (A != A or B != B)
    {
        ; NaN breaks the law of trichotomy, so it must be handled before
        ; comparing numbers.
        Result := ""
    }
    else
    {
        CaseSense := A_StringCaseSense
        StringCaseSense On
        Result := (A > B) - (A < B)
        StringCaseSense %CaseSense%
    }
    return Result
}

_Op_LtAux(ScalarCmp, A, B)
{
    local
    Cmp := _Op_Cmp(ScalarCmp, A, B)
    return Cmp == -1
}

Op_Lt(Args*)
{
    local
    Sig := "Op_Lt(Args*)"
    _Validate_Args(Sig, Args)
    return _Validate_BlameOrdCmp(Sig
                                ,Func("_Op_TestArgs")
                                     .Bind(Func("_Op_LtAux")
                                               .Bind(Func("_Op_CsCmp"))
                                          ,Args))
}

_Op_GtAux(ScalarCmp, A, B)
{
    local
    Cmp := _Op_Cmp(ScalarCmp, A, B)
    return Cmp == 1
}

Op_Gt(Args*)
{
    local
    Sig := "Op_Gt(Args*)"
    _Validate_Args(Sig, Args)
    return _Validate_BlameOrdCmp(Sig
                                ,Func("_Op_TestArgs")
                                     .Bind(Func("_Op_GtAux")
                                               .Bind(Func("_Op_CsCmp"))
                                          ,Args))
}

_Op_LeAux(ScalarCmp, A, B)
{
    local
    Cmp := _Op_Cmp(ScalarCmp, A, B)
    return Cmp != "" and Cmp <= 0
}

Op_Le(Args*)
{
    local
    Sig := "Op_Le(Args*)"
    _Validate_Args(Sig, Args)
    return _Validate_BlameOrdCmp(Sig
                                ,Func("_Op_TestArgs")
                                     .Bind(Func("_Op_LeAux")
                                               .Bind(Func("_Op_CsCmp"))
                                          ,Args))
}

_Op_GeAux(ScalarCmp, A, B)
{
    local
    Cmp := _Op_Cmp(ScalarCmp, A, B)
    return Cmp != "" and Cmp >= 0
}

Op_Ge(Args*)
{
    local
    Sig := "Op_Ge(Args*)"
    _Validate_Args(Sig, Args)
    return _Validate_BlameOrdCmp(Sig
                                ,Func("_Op_TestArgs")
                                     .Bind(Func("_Op_GeAux")
                                               .Bind(Func("_Op_CsCmp"))
                                          ,Args))
}

Op_Eq(Args*)
{
    local
    Sig := "Op_Eq(Args*)"
    _Validate_Args(Sig, Args)
    return _Op_TestArgs(Func("_Op_Eq").Bind(Func("_Op_CsEq")), Args)
}

Op_Ne(Args*)
{
    local
    Sig := "Op_Ne(Args*)"
    _Validate_Args(Sig, Args)
    return Args.Count() < 2 ? true
         : not Op_Eq(Args*)
}

Op_IdEq(Args*)
{
    local
    Sig := "Op_IdEq(Args*)"
    _Validate_Args(Sig, Args)
    return _Op_TestArgs(Func("_Op_CsEq"), Args)
}

Op_IdNe(Args*)
{
    local
    Sig := "Op_IdNe(Args*)"
    _Validate_Args(Sig, Args)
    return Args.Count() < 2 ? true
         : not Op_IdEq(Args*)
}
