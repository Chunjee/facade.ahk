#Include <Is>
#Include <Type>
#Include <IsFuncObj>
#Include <_IsArray>

;-------------------------------------------------------------------------------
; Auxiliary Functions

_Validate_TypeRepr(Value)
{
    local
    Type := Type(Value)
    static TypeNames := {"LIST_NULL":   "List"
                        ,"List_Cons":   "List"
                        ,"STREAM_NULL": "Stream"
                        ,"Stream_Memo": "Stream"
                        ,"Stream_Cons": "Stream"}
    Type := TypeNames.HasKey(Type) ? TypeNames[Type] : Type
    return Type == "Func_Bindable" ? "Bindable " . _Validate_TypeRepr(Value._Func)
         : Type
}

_Validate_ValueRepr(Value)
{
    local
    if (Is(Value, "object"))
    {
        Result := _Validate_TypeRepr(Value)
    }
    else if (Is(Value, "number"))
    {
        VarSetCapacity(Inf, 8)
        NumPut(0x7FF0000000000000, Inf,, "UInt64")
        Inf := NumGet(Inf,, "Double")
        Result := Value == -Inf  ? "-inf"
                : Value == Inf   ? "inf"
                : Value != Value ? "nan"
                : Value
    }
    else
    {
        static EscSeqs := {"`a": "``a"
                          ,"`b": "``b"
                          ,"`t": "``t"
                          ,"`n": "``n"
                          ,"`v": "``v"
                          ,"`f": "``f"
                          ,"`r": "``r"
                          ,"""": """"""
                          ,"``": "````"}
        Result := """"
        for _, Char in StrSplit(Value)
        {
            Result .= EscSeqs.HasKey(Char) ? EscSeqs[Char]
                    : Char
        }
        Result .= """"
    }
    return Result
}

;-------------------------------------------------------------------------------
; Call Defect Reporting

_Validate_Args(Sig, Args)
{
    local
    loop % Args.Length()
    {
        if (not Args.HasKey(A_Index))
        {
            throw Exception("Missing Argument Defect", -2
                           ,Sig)
        }
    }
}

;-------------------------------------------------------------------------------
; Type Defect Reporting

_Validate_NumberArg(Sig, Var, Value)
{
    local
    if (not Is(Value, "number"))
    {
        throw Exception("Type Defect", -2
                       ,Format("{1}  {2} is not a number.  {2}'s type is {3}.", Sig, Var, _Validate_TypeRepr(Value)))
    }
}

_Validate_NumberArgs(Sig, Args)
{
    local
    loop % Args.Length()
    {
        if (not Args.HasKey(A_Index))
        {
            throw Exception("Missing Argument Defect", -2
                           ,Sig)
        }
        if (not Is(Args[A_Index], "number"))
        {
            throw Exception("Type Defect", -2
                           ,Format("{1}  Invalid argument {2}.", Sig, _Validate_TypeRepr(Args[A_Index])))
        }
    }
}

_Validate_IntegerArg(Sig, Var, Value)
{
    local
    if (not Is(Value, "integer"))
    {
        throw Exception("Type Defect", -2
                       ,Format("{1}  {2} is not an Integer.  {2}'s type is {3}.", Sig, Var, _Validate_TypeRepr(Value)))
    }
}

_Validate_IntegerArgs(Sig, Args)
{
    local
    loop % Args.Length()
    {
        if (not Args.HasKey(A_Index))
        {
            throw Exception("Missing Argument Defect", -2
                           ,Sig)
        }
        if (not Is(Args[A_Index], "integer"))
        {
            throw Exception("Type Defect", -2
                           ,Format("{1}  Invalid argument {2}.", Sig, _Validate_TypeRepr(Args[A_Index])))
        }
    }
}

_Validate_StringArg(Sig, Var, Value)
{
    local
    if (Is(Value, "object"))
    {
        throw Exception("Type Defect", -2
                       ,Format("{1}  {2} is not a String.  {2}'s type is {3}.", Sig, Var, _Validate_TypeRepr(Value)))
    }
}

_Validate_StringArgs(Sig, Args)
{
    local
    loop % Args.Length()
    {
        if (not Args.HasKey(A_Index))
        {
            throw Exception("Missing Argument Defect", -2
                           ,Sig)
        }
        if (Is(Args[A_Index], "object"))
        {
            throw Exception("Type Defect", -2
                           ,Format("{1}  Invalid argument {2}.", Sig, _Validate_TypeRepr(Args[A_Index])))
        }
    }
}

_Validate_FuncArg(Sig, Var, Value)
{
    local
    if (not IsFuncObj(Value))
    {
        throw Exception("Type Defect", -2
                       ,Format("{1}  {2} is not a Func.  {2}'s type is {3}.", Sig, Var, _Validate_TypeRepr(Value)))
    }
}

_Validate_FuncArgs(Sig, Args)
{
    local
    loop % Args.Length()
    {
        if (not Args.HasKey(A_Index))
        {
            throw Exception("Missing Argument Defect", -2
                           ,Sig)
        }
        if (not IsFuncObj(Args[A_Index]))
        {
            throw Exception("Type Defect", -2
                           ,Format("{1}  Invalid argument {2}.", Sig, _Validate_TypeRepr(Args[A_Index])))
        }
    }
}

_Validate_ObjArg(Sig, Var, Value)
{
    local
    if (not Is(Value, "object"))
    {
        throw Exception("Type Defect", -2
                       ,Format("{1}  {2} is not an object.  {2}'s type is {3}.", Sig, Var, _Validate_TypeRepr(Value)))
    }
}

_Validate_ObjectArg(Sig, Var, Value)
{
    local
    if (not Type(Value) == "Object")
    {
        throw Exception("Type Defect", -2
                       ,Format("{1}  {2} is not an Object.  {2}'s type is {3}.", Sig, Var, _Validate_TypeRepr(Value)))
    }
}

_Validate_BadArrayArg(Sig, Var, Value)
{
    local
    if (not Type(Value) == "Object")
    {
        throw Exception("Type Defect", -2
                       ,Format("{1}  {2} is not an Array.  {2}'s type is {3}.", Sig, Var, _Validate_TypeRepr(Value)))
    }
}

_Validate_FuncBadArrayArg(Sig, Var, Value)
{
    local
    try
    {
        _Validate_BadArrayArg(Sig, Var, Value)
    }
    catch E
    {
        throw Exception(E.Message, -2, E.Extra)
    }
    for _, Element in Value
    {
        if (not IsFuncObj(Element))
        {
            throw Exception("Type Defect", -2
                           ,Format("{1}  {2} contains an invalid element {3}.", Sig, Var, _Validate_TypeRepr(Element)))
        }
    }
}

_Validate_ArrayArg(Sig, Var, Value)
{
    local
    if (not _IsArray(Value))
    {
        throw Exception("Type Defect", -2
                       ,Format("{1}  {2} is not an Array.  {2}'s type is {3}.", Sig, Var, _Validate_TypeRepr(Value)))
    }
}

_Validate_NonEmptyArrayArg(Sig, Var, Value)
{
    local
    try
    {
        _Validate_ArrayArg(Sig, Var, Value)
    }
    catch E
    {
        throw Exception(E.Message, -2, E.Extra)
    }
    if (Value.Count() == 0)
    {
        throw Exception("Type Defect", -2
                       ,Format("{1}  {2} is an empty Array.", Sig, Var))
    }
}

_Validate_ArrayArgs(Sig, Args)
{
    local
    loop % Args.Length()
    {
        if (not Args.HasKey(A_Index))
        {
            throw Exception("Missing Argument Defect", -2
                           ,Sig)
        }
        if (not _IsArray(Args[A_Index]))
        {
            throw Exception("Type Defect", -2
                           ,Format("{1}  Invalid argument {2}.", Sig, _Validate_TypeRepr(Args[A_Index])))
        }
    }
}

_Validate_ListArg(Sig, Var, Value)
{
    local
    global List
    if (not Is(Value, List))
    {
        throw Exception("Type Defect", -2
                       ,Format("{1}  {2} is not a List.  {2}'s type is {3}.", Sig, Var, _Validate_TypeRepr(Value)))
    }
}

_Validate_NonEmptyListArg(Sig, Var, Value)
{
    local
    global LIST_NULL
    try
    {
        _Validate_ListArg(Sig, Var, Value)
    }
    catch E
    {
        throw Exception(E.Message, -2, E.Extra)
    }
    if (Value == LIST_NULL)
    {
        throw Exception("Type Defect", -2
                       ,Format("{1}  {2} is the empty List.", Sig, Var))
    }
}

_Validate_StreamArg(Sig, Var, Value)
{
    local
    global Stream
    if (not Is(Value, Stream))
    {
        throw Exception("Type Defect", -2
                       ,Format("{1}  {2} is not a Stream.  {2}'s type is {3}.", Sig, Var, _Validate_TypeRepr(Value)))
    }
}

_Validate_NonEmptyStreamArg(Sig, Var, Value)
{
    local
    global STREAM_NULL
    try
    {
        _Validate_StreamArg(Sig, Var, Value)
    }
    catch E
    {
        throw Exception(E.Message, -2, E.Extra)
    }
    if (Value == STREAM_NULL)
    {
        throw Exception("Type Defect", -2
                       ,Format("{1}  {2} is the empty Stream.", Sig, Var))
    }
}

_Validate_StreamArgs(Sig, Args)
{
    local
    global Stream
    loop % Args.Length()
    {
        if (not Args.HasKey(A_Index))
        {
            throw Exception("Missing Argument Defect", -2
                           ,Sig)
        }
        if (not Is(Args[A_Index], Stream))
        {
            throw Exception("Type Defect", -2
                           ,Format("{1}  Invalid argument {2}.", Sig, _Validate_TypeRepr(Args[A_Index])))
        }
    }
}

_Validate_DictArg(Sig, Var, Value)
{
    local
    global Dict
    if (not Is(Value, Dict))
    {
        throw Exception("Type Defect", -2
                       ,Format("{1}  {2} is not a Dict.  {2}'s type is {3}.", Sig, Var, _Validate_TypeRepr(Value)))
    }
}

_Validate_NonEmptyDictArg(Sig, Var, Value)
{
    local
    try
    {
        _Validate_DictArg(Sig, Var, Value)
    }
    catch E
    {
        throw Exception(E.Message, -2, E.Extra)
    }
    if (Value.Count() == 0)
    {
        throw Exception("Type Defect", -2
                       ,Format("{1}  {2} is an empty Dict.", Sig, Var))
    }
}

_Validate_DictArgs(Sig, Args)
{
    local
    global Dict
    loop % Args.Length()
    {
        if (not Args.HasKey(A_Index))
        {
            throw Exception("Missing Argument Defect", -2
                           ,Sig)
        }
        if (not Is(Args[A_Index], Dict))
        {
            throw Exception("Type Defect", -2
                           ,Format("{1}  Invalid argument {2}.", Sig, _Validate_TypeRepr(Args[A_Index])))
        }
    }
}

;-------------------------------------------------------------------------------
; Value Defect Reporting

_Validate_DivisorArg(Sig, Var, Value)
{
    local
    try
    {
        _Validate_NumberArg(Sig, Var, Value)
    }
    catch E
    {
        throw Exception(E.Message, -2, E.Extra)
    }
    if (Value == 0)
    {
        throw Exception("Division by Zero Defect", -2
                       ,Sig)
    }
}

_Validate_NonZeroIntegerArg(Sig, Var, Value)
{
    local
    try
    {
        _Validate_NumberArg(Sig, Var, Value)
    }
    catch E
    {
        throw Exception(E.Message, -2, E.Extra)
    }
    if (Value == 0)
    {
        throw Exception("Value Defect", -2
                       ,Format("{1}  {2} is 0.", Sig, Var))
    }
}

_Validate_NonNegNumberArg(Sig, Var, Value)
{
    local
    try
    {
        _Validate_NumberArg(Sig, Var, Value)
    }
    catch E
    {
        throw Exception(E.Message, -2, E.Extra)
    }
    if (Value < 0)
    {
        throw Exception("Value Defect", -2
                       ,Format("{1}  {2} is negative.  {2} is {3}.", Sig, Var, Value))
    }
}

_Validate_NonNegIntegerArg(Sig, Var, Value)
{
    local
    try
    {
        _Validate_IntegerArg(Sig, Var, Value)
    }
    catch E
    {
        throw Exception(E.Message, -2, E.Extra)
    }
    if (Value < 0)
    {
        throw Exception("Value Defect", -2
                       ,Format("{1}  {2} is negative.  {2} is {3}.", Sig, Var, Value))
    }
}

_Validate_PosNumberArg(Sig, Var, Value)
{
    local
    try
    {
        _Validate_NumberArg(Sig, Var, Value)
    }
    catch E
    {
        throw Exception(E.Message, -2, E.Extra)
    }
    if (Value <= 0)
    {
        throw Exception("Value Defect", -2
                       ,Format("{1}  {2} is not positive.  {2} is {3}.", Sig, Var, Value))
    }
}

_Validate_Neg1To1NumberArg(Sig, Var, Value)
{
    local
    try
    {
        _Validate_NumberArg(Sig, Var, Value)
    }
    catch E
    {
        throw Exception(E.Message, -2, E.Extra)
    }
    if (not (-1 <= Value and Value <= 1))
    {
        throw Exception("Value Defect", -2
                       ,Format("{1}  {2} is not in the interval [-1, 1].  {2} is {3}.", Sig, Var, Value))
    }
}

_Validate_IdentifierArg(Sig, Var, Value)
{
    local
    try
    {
        _Validate_StringArg(Sig, Var, Value)
    }
    catch E
    {
        throw Exception(E.Message, -2, E.Extra)
    }
    if (not Value ~= "S)^[\p{L}_][\p{Xan}_]*$")
    {
        throw Exception("Value Defect", -2
                       ,Format("{1}  {2} is not an identifier.  {2} is {3}.", Sig, Var, _Validate_ValueRepr(Value)))
    }
}

;-------------------------------------------------------------------------------
; Defect Rewriting

_Validate_BlameOrdCmp(Sig, Func)
{
    local
    try
    {
        Result := Func.Call()
    }
    catch E
    {
        RegExMatch(E.Extra, "S)Ordered comparison is undefined between instances of .+ and .+\.$", Match)
        throw Exception("Type Defect", -2
                       ,Format("{1}  {2}", Sig, Match))
    }
    return Result
}

_Validate_BlameKey(Sig, Func)
{
    local
    try
    {
        Result := Func.Call()
    }
    catch E
    {
        if (E.Message == "Key Defect")
        {
            RegExMatch(E.Extra, "S)Key not found.  Key is .+\.$", Match)
            throw Exception("Key Defect", -2
                           ,Format("{1}  {2}", Sig, Match))
        }
        else
        {
            throw E
        }
    }
    return Result
}

_Validate_BlamePath(Sig, Func)
{
    local
    try
    {
        Result := Func.Call()
    }
    catch E
    {
        if (E.Message == "Type Defect" or E.Message == "Key Defect")
        {
            throw Exception(E.Message, -2
                           ,Format("{1}  Invalid Path.", Sig))
        }
        else
        {
            throw E
        }
    }
    return Result
}
