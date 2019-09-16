#Include Is.ahk
#Include _Validate.ahk
#Include Op.ahk

class Func_Bindable
{
    __New(Func, Args*)
    {
        local
        global Func_Bindable
        if (Is(Func, Func_Bindable))
        {
            if (Args.Length() == 0)
            {
                Result := Func
            }
            else
            {
                this._Func     := Func._Func
                this._Bindings := []
                this._Bindings.Push(Func._Bindings*)
                this._Bindings.Push(Args*)
                Result := this
            }
        }
        else
        {
            this._Func     := Func
            this._Bindings := []
            this._Bindings.Push(Args*)
            Result := this
        }
        return Result
    }

    Bind(Args*)
    {
        local
        global Func_Bindable
        return new Func_Bindable(this, Args*)
    }

    Call(Args*)
    {
        local
        FullArgs := []
        FullArgs.Push(this._Bindings*)
        FullArgs.Push(Args*)
        return this._Func.Call(FullArgs*)
    }

    __Get(Key)
    {
        local
        if (Key != "base" and not this.base.HasKey(Key))
        {
            ; Members we did not override pass through.
            return this._Func[Key]
        }
    }

    __Call(Method, Args*)
    {
        local
        if (Method == "")
        {
            ; %Func%(Args*)
            return this.Call(Args*)
        }
    }
}

Func_DllFunc(NameOrPtr, Types*)
{
    local
    Sig := "Func_DllFunc(NameOrPtr, Types*)"
    if (Is(NameOrPtr, "object"))
    {
        throw Exception("Type Defect", -1
                       ,Format("{1}  NameOrPtr is not a String or Integer.  NameOrPtr's type is {2}.", Sig, _Validate_TypeRepr(NameOrPtr)))
    }
    loop % Types.Length()
    {
        if (not Types.HasKey(A_Index))
        {
            throw Exception("Missing Argument Defect", -1
                           ,Sig)
        }
        if (Is(Types[A_Index], "object"))
        {
            throw Exception("Type Defect", -1
                           ,Format("{1}  Invalid argument {2}.", Sig, _Validate_TypeRepr(Types[A_Index])))
        }
        if (not Types[A_Index] ~= "iS)^(?:U?(?:Char|Short|Int|Int64)|Float|Double|[AW]?Str|Ptr)[\*P]?$")
        {
            throw Exception("Value Defect", -1
                           ,Format("{1}  Invalid argument {2}.", Sig, _Validate_ValueRepr(Types[A_Index])))
        }
    }
    Positions := [0]
    loop % Types.Count()
    {
        Positions.Push(A_Index)
        Positions.Push(A_Index + Types.Count())
    }
    Positions.Pop()
    return Func_Bind(Func_Rearg(Func("DllCall"), Positions), NameOrPtr, Types*)
}

Func_Bind(Func, Args*)
{
    local
    global Func_Bindable
    Sig := "Func_Bind(Func, Args*)"
    _Validate_FuncArg(Sig, "Func", Func)
    return new Func_Bindable(Func, Args*)
}

Func_BindMethod(Method, Obj, Args*)
{
    local
    Sig := "Func_BindMethod(Method, Obj, Args*)"
    _Validate_IdentifierArg(Sig, "Method", Method)
    _Validate_ObjArg(Sig, "Obj", Obj)
    return Func_Bind(ObjBindMethod(Obj, Method), Args*)
}

_Func_MethodCallerAux(Method, Args, Obj, Rest*)
{
    local
    Args := Args.Clone()
    Args.Push(Rest*)
    return Obj[Method](Args*)
}

Func_MethodCaller(Method, Args*)
{
    local
    Sig := "Func_MethodCaller(Method, Args*)"
    _Validate_IdentifierArg(Sig, "Method", Method)
    return Func_Bind(Func("_Func_MethodCallerAux"), Method, Args)
}

Func_Applicable(Obj)
{
    local
    Sig := "Func_Applicable(Obj)"
    _Validate_ObjArg(Sig, "Obj", Obj)
    return Func_Flip(Func("Op_Get")).Bind(Obj)
}

Func_Apply(Func, Args)
{
    local
    Sig := "Func_Apply(Func, Args)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_BadArrayArg(Sig, "Args", Args)
    return Func.Call(Args*)
}

_Func_ApplyArgsWithAux(Func, ArgsFuncs, Args*)
{
    local
    ResultArgs := []
    for Index, ArgsFunc in ArgsFuncs
    {
        ResultArgs[Index] := ArgsFunc.Call(Args*)
    }
    return Func.Call(ResultArgs*)
}

Func_ApplyArgsWith(Func, ArgsFuncs)
{
    local
    Sig := "Func_ApplyArgsWith(Func, ArgsFuncs)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_FuncBadArrayArg(Sig, "ArgsFuncs", ArgsFuncs)
    return Func_Bind(Func("_Func_ApplyArgsWithAux"), Func, ArgsFuncs)
}

_Func_ApplyRespWithAux(Func, RespFuncs, Args*)
{
    local
    ResultArgs := []
    for Index, RespFunc in RespFuncs
    {
        if (not Args.HasKey(Index))
        {
            throw Exception("Missing Argument Defect")
        }
        ResultArgs[Index] := RespFunc.Call(Args[Index])
    }
    return Func.Call(ResultArgs*)
}

Func_ApplyRespWith(Func, RespFuncs)
{
    local
    Sig := "Func_ApplyRespWith(Func, RespFuncs)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_FuncBadArrayArg(Sig, "RespFuncs", RespFuncs)
    return Func_Bind(Func("_Func_ApplyRespWithAux"), Func, RespFuncs)
}

_Func_CompAux(Funcs, Args*)
{
    local
    Index  := Funcs.Count()
    Result := Funcs[Index].Call(Args*)
    --Index
    while (Index >= 1)
    {
        Result := Funcs[Index].Call(Result)
        --Index
    }
    return Result
}

Func_Comp(Funcs*)
{
    local
    Sig := "Func_Comp(Funcs*)"
    _Validate_FuncArgs(Sig, Funcs)
    return Funcs.Count() == 0 ? Func_Bind(Func("Func_Id"))
         : Funcs.Count() == 1 ? Func_Bind(Funcs[1])
         : Func_Bind(Func("_Func_CompAux"), Funcs)
}

_Func_ReargAux(MaxPosition, Func, Positions, Args*)
{
    local
    NewArgs := []
    for Destination, Source in Positions
    {
        NewArgs[Destination] := Args[Source + 1]
    }
    while (MaxPosition + 1 < Args.Length())
    {
        ++MaxPosition
        ++Destination
        if (Args.HasKey(MaxPosition + 1))
        {
            NewArgs[Destination] := Args[MaxPosition + 1]
        }
    }
    return Func.Call(NewArgs*)
}

Func_Rearg(Func, Positions)
{
    local
    Sig := "Func_Rearg(Func, Positions)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_BadArrayArg(Sig, "Positions", Positions)
    MaxPosition       := 0
    FilteredPositions := []
    for Index, Value in Positions
    {
        if (    Is(Index, "integer")
            and 1 <= Index)
        {
            if (not Is(Value, "integer"))
            {
                throw Exception("Type Defect", -1
                               ,Format("{1}  Invalid position {2}.", Sig, _Validate_TypeRepr(Value)))
            }
            if (not 0 <= Value)
            {
                throw Exception("Value Defect", -1
                               ,Format("{1}  Invalid position {2}.", Sig, Value))
            }
            MaxPosition              := Value > MaxPosition ? Value
                                      : MaxPosition
            FilteredPositions[Index] := Value
        }
    }
    FilteredPositions.SetCapacity(0)
    return Func_Bind(Func("_Func_ReargAux"), MaxPosition, Func, FilteredPositions)
}

Func_Flip(F)
{
    local
    Sig := "Func_Flip(F)"
    _Validate_FuncArg(Sig, "F", F)
    return Func_Rearg(F, [1, 0])
}

Func_HookL(F, G)
{
    local
    Sig := "Func_HookL(F, G)"
    _Validate_FuncArg(Sig, "F", F)
    _Validate_FuncArg(Sig, "G", G)
    return Func_ApplyRespWith(F, [Func("Func_Id"), G])
}

Func_HookR(F, G)
{
    local
    Sig := "Func_HookR(F, G)"
    _Validate_FuncArg(Sig, "F", F)
    _Validate_FuncArg(Sig, "G", G)
    return Func_ApplyRespWith(F, [G, Func("Func_Id")])
}

Func_Id(X)
{
    local
    return X
}

_Func_ConstAux(X, Args*)
{
    local
    return X
}

Func_Const(X)
{
    local
    return Func_Bind(Func("_Func_ConstAux"), X)
}

Func_On(F, G)
{
    local
    Sig := "Func_On(F, G)"
    _Validate_FuncArg(Sig, "F", F)
    _Validate_FuncArg(Sig, "G", G)
    return Func_ApplyRespWith(F, [G, G])
}

_Func_CNotAux(Pred, Args*)
{
    local
    return not Pred.Call(Args*)
}

Func_CNot(Pred)
{
    local
    Sig := "Func_CNot(Pred)"
    _Validate_FuncArg(Sig, "Pred", Pred)
    return Func_Bind(Func("_Func_CNotAux"), Pred)
}

_Func_CAndAux(Preds, Args*)
{
    local
    Result := true
    Index  := 1
    while (Result and Index <= Preds.Count())
    {
        Result := Preds[Index].Call(Args*)
        ++Index
    }
    return Result
}

Func_CAnd(Preds*)
{
    local
    Sig := "Func_CAnd(Preds*)"
    _Validate_FuncArgs(Sig, Preds)
    return Preds.Count() == 0 ? Func_Const(true)
         : Preds.Count() == 1 ? Func_Bind(Preds[1])
         : Func_Bind(Func("_Func_CAndAux"), Preds)
}

_Func_COrAux(Preds, Args*)
{
    local
    Result := false
    Index  := 1
    while (not Result and Index <= Preds.Count())
    {
        Result := Preds[Index].Call(Args*)
        ++Index
    }
    return Result
}

Func_COr(Preds*)
{
    local
    Sig := "Func_COr(Preds*)"
    _Validate_FuncArgs(Sig, Preds)
    return Preds.Count() == 0 ? Func_Const(false)
         : Preds.Count() == 1 ? Func_Bind(Preds[1])
         : Func_Bind(Func("_Func_COrAux"), Preds)
}

_Func_CIfAux(Pred, ThenFunc, ElseFunc, Args*)
{
    local
    return Pred.Call(Args*) ? ThenFunc.Call(Args*) : ElseFunc.Call(Args*)
}

Func_CIf(Pred, ThenFunc, ElseFunc)
{
    local
    Sig := "Func_CIf(Pred, ThenFunc, ElseFunc)"
    _Validate_FuncArg(Sig, "Pred", Pred)
    _Validate_FuncArg(Sig, "ThenFunc", ThenFunc)
    _Validate_FuncArg(Sig, "ElseFunc", ElseFunc)
    return Func_Bind(Func("_Func_CIfAux"), Pred, ThenFunc, ElseFunc)
}

_Func_CWhileAux(Pred, Func, X)
{
    local
    while (Pred.Call(X))
    {
        X := Func.Call(X)
    }
    return X
}

Func_CWhile(Pred, Func)
{
    local
    Sig := "Func_CWhile(Pred, Func)"
    _Validate_FuncArg(Sig, "Pred", Pred)
    _Validate_FuncArg(Sig, "Func", Func)
    return Func_Bind(Func("_Func_CWhileAux"), Pred, Func)
}

_Func_FailSafeAux(Funcs, Args*)
{
    local
    Failed := true
    Index  := 1
    while (Failed and Index <= Funcs.Count())
    {
        try
        {
            Result := Funcs[Index].Call(Args*)
            Failed := false
        }
        catch E
        {
            ++Index
        }
    }
    if (Failed)
    {
        throw E
    }
    return Result
}

Func_FailSafe(Funcs*)
{
    local
    Sig := "Func_FailSafe(Funcs*)"
    _Validate_FuncArgs(Sig, Funcs)
    if (Funcs.Count() == 0)
    {
        throw Exception("Arity Defect", -1
                       ,Sig)
    }
    else if (Funcs.Count() == 1)
    {
        Result := Func_Bind(Funcs[1])
    }
    else
    {
        Result := Func_Bind(Func("_Func_FailSafeAux"), Funcs)
    }
    return Result
}

Func_Default(Func, Default)
{
    local
    Sig := "Func_Default(Func, Default)"
    _Validate_FuncArg(Sig, "Func", Func)
    return Func_Comp(Func_CIf(Func("Op_Eq").Bind("")
                             ,Func_Const(Default)
                             ,Func("Func_Id"))
                    ,Func_FailSafe(Func, Func_Const(Default)))
}
