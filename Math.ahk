#Include Is.ahk
#Include _Validate.ahk

Math_Abs(X)
{
    local
    Sig := "Math_Abs(X)"
    _Validate_NumberArg(Sig, "X", X)
    if (Is(X, "integer") and X == -9223372036854775808)
    {
        throw Exception("Value Defect", -1
                       ,Format("{1}  X has no 64-bit non-negative equal in magnitude.  X is -9223372036854775808.", Sig))
    }
    return Abs(X)
}

Math_Ceil(X)
{
    local
    Sig := "Math_Ceil(X)"
    _Validate_NumberArg(Sig, "X", X)
    return Ceil(X)
}

Math_Exp(X)
{
    local
    Sig := "Math_Exp(X)"
    _Validate_NumberArg(Sig, "X", X)
    return Exp(X)
}

Math_Floor(X)
{
    local
    Sig := "Math_Floor(X)"
    _Validate_NumberArg(Sig, "X", X)
    return Floor(X)
}

Math_Log(X)
{
    local
    Sig := "Math_Log(X)"
    _Validate_PosNumberArg(Sig, "X", X)
    return Log(X)
}

Math_Ln(X)
{
    local
    Sig := "Math_Ln(X)"
    _Validate_PosNumberArg(Sig, "X", X)
    return Ln(X)
}

Math_Max(Numbers*)
{
    local
    Sig := "Math_Max(Numbers*)"
    _Validate_NumberArgs(Sig, Numbers)
    if (Numbers.Count() == 0)
    {
        throw Exception("Arity Defect", -1
                       ,Sig)
    }
    return Max(Numbers*)
}

Math_Min(Numbers*)
{
    local
    Sig := "Math_Min(Numbers*)"
    _Validate_NumberArgs(Sig, Numbers)
    if (Numbers.Count() == 0)
    {
        throw Exception("Arity Defect", -1
                       ,Sig)
    }
    return Min(Numbers*)
}

Math_Sqrt(X)
{
    local
    Sig := "Math_Sqrt(X)"
    _Validate_NonNegNumberArg(Sig, "X", X)
    return Sqrt(X)
}

Math_Sin(X)
{
    local
    Sig := "Math_Sin(X)"
    _Validate_NumberArg(Sig, "X", X)
    return Sin(X)
}

Math_Cos(X)
{
    local
    Sig := "Math_Cos(X)"
    _Validate_NumberArg(Sig, "X", X)
    return Cos(X)
}

Math_Tan(X)
{
    local
    Sig := "Math_Tan(X)"
    _Validate_NumberArg(Sig, "X", X)
    return Tan(X)
}

Math_ASin(X)
{
    local
    Sig := "Math_ASin(X)"
    _Validate_Neg1To1NumberArg(Sig, "X", X)
    return ASin(X)
}

Math_ACos(X)
{
    local
    Sig := "Math_ACos(X)"
    _Validate_Neg1To1NumberArg(Sig, "X", X)
    return ACos(X)
}

Math_ATan(X)
{
    local
    Sig := "Math_ATan(X)"
    _Validate_NumberArg(Sig, "X", X)
    return ATan(X)
}
