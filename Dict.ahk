#include %A_LineFile%\..\Is.ahk
#include %A_LineFile%\..\_Validate.ahk
#include %A_LineFile%\..\Func.ahk
#include %A_LineFile%\..\_Push.ahk
#include %A_LineFile%\..\_Dict.ahk
#include %A_LineFile%\..\Array.ahk

Dict(Items*)
{
    local
    global Dict
    Sig := "Dict(Items*)"
    loop % Items.Length()
    {
        if (not Items.HasKey(A_Index))
        {
            throw Exception("Missing Argument Defect", -1
                           ,Sig)
        }
        if (   not Array_IsArray(Items[A_Index])
            or not Items[A_Index].Count() == 2)
        {
            throw Exception("Type Defect", -1
                           ,Format("{1}  Invalid argument {2}.", Sig, _Validate_TypeRepr(Items[A_Index])))
        }
    }
    return new Dict(Items*)
}

Dict_FromObject(Object)
{
    local
    Sig := "Dict_FromObject(Object)"
    _Validate_ObjectArg(Sig, "Object", Object)
    Result := Dict()
    for Key, Value in Object
    {
        Result.Set(Key, Value)
    }
    return Result
}

_Dict_ToObjectAux(A, X)
{
    local
    if (not ObjHasKey(A, X[1]))
    {
        ObjRawSet(A, X[1], X[2])
    }
    else
    {
        throw Exception("Value Defect", -3
                       ,"Dict_ToObject(Dict)  Dict contains keys that collide when case-folded.")
    }
    return A
}

Dict_ToObject(Dict)
{
    local
    Sig := "Dict_ToObject(Dict)"
    _Validate_DictArg(Sig, "Dict", Dict)
    Result := {}
    Result.SetCapacity(Dict.Count())
    return Dict_Fold(Func("_Dict_ToObjectAux"), Result, Dict)
}

Dict_IsDict(Value)
{
    local
    global Dict
    return Is(Value, Dict)
}

Dict_IsEmpty(Value)
{
    local
    return Dict_IsDict(Value) and Value.Count() == 0
}

Dict_Count(Dict)
{
    local
    Sig := "Dict_Count(Dict)"
    _Validate_DictArg(Sig, "Dict", Dict)
    return Dict.Count()
}

Dict_HasKey(Key, Dict)
{
    local
    Sig := "Dict_HasKey(Key, Dict)"
    _Validate_DictArg(Sig, "Dict", Dict)
    return Dict.HasKey(Key)
}

Dict_Get(Key, Dict)
{
    local
    Sig := "Dict_Get(Key, Dict)"
    _Validate_DictArg(Sig, "Dict", Dict)
    return _Validate_BlameKey(Sig, ObjBindMethod(Dict, "Get", Key))
}

Dict_Set(Key, Value, Dict)
{
    local
    Sig := "Dict_Set(Key, Value, Dict)"
    _Validate_DictArg(Sig, "Dict", Dict)
    Result := Dict.Clone()
    Result.Set(Key, Value)
    return Result
}

Dict_Update(Key, Func, Dict)
{
    local
    Sig := "Dict_Update(Key, Func, Dict)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_DictArg(Sig, "Dict", Dict)
    return Dict_Set(Key
                   ,Func.Call(_Validate_BlameKey(Sig
                                                ,Func("Dict_Get")
                                                     .Bind(Key, Dict)))
                   ,Dict)
}

Dict_Delete(Key, Dict)
{
    local
    Sig := "Dict_Delete(Key, Dict)"
    _Validate_DictArg(Sig, "Dict", Dict)
    Result := Dict.Clone()
    _Validate_BlameKey(Sig, ObjBindMethod(Result, "Delete", Key))
    return Result
}

Dict_CountIn(Path, Dict)
{
    local
    Sig := "Dict_CountIn(Path, Dict)"
    _Validate_ArrayArg(Sig, "Path", Path)
    _Validate_DictArg(Sig, "Dict", Dict)
    LastDict := _Validate_BlamePath(Sig, Func("Dict_GetIn").Bind(Path, Dict))
    if (Dict_IsDict(LastDict))
    {
        Result := LastDict.Count()
    }
    else
    {
        throw Exception("Type Defect", -1
                       ,Format("{1}  Invalid Path.", Sig))
    }
    return Result
}

Dict_HasKeyIn(Path, Dict)
{
    local
    Sig := "Dict_HasKeyIn(Path, Dict)"
    _Validate_ArrayArg(Sig, "Path", Path)
    _Validate_DictArg(Sig, "Dict", Dict)
    Result := true
    Index  := 1
    while (Result and Index <= Path.Count())
    {
        if (Dict_IsDict(Dict))
        {
            Result := Dict.HasKey(Path[Index])
            Dict   := Result ? Dict.Get(Path[Index]) : ""
            ++Index
        }
        else
        {
            Result := false
        }
    }
    return Result
}

Dict_GetIn(Path, Dict)
{
    local
    Sig := "Dict_GetIn(Path, Dict)"
    _Validate_ArrayArg(Sig, "Path", Path)
    _Validate_DictArg(Sig, "Dict", Dict)
    return _Validate_BlamePath(Sig
                              ,Func("Array_FoldL")
                                   .Bind(Func_Flip(Func("Dict_Get"))
                                        ,Dict
                                        ,Path))
}

_Dict_ReconstructAux(Path, Index, Dict, Func)
{
    local
    Key := Path[Index]
    if (Index == Path.Count())
    {
        Result := Func.Call(Key, Dict)
    }
    else
    {
        Result := Dict_Set(Key
                          ,_Dict_ReconstructAux(Path
                                               ,Index + 1
                                               ,Dict_Get(Key, Dict)
                                               ,Func)
                          ,Dict)
    }
    return Result
}

_Dict_Reconstruct(Path, Func, Dict)
{
    local
    if (Path.Count() == 0)
    {
        Result := Dict.Clone()
    }
    else
    {
        Result := _Dict_ReconstructAux(Path
                                      ,1
                                      ,Dict
                                      ,Func)
    }
    return Result
}

Dict_SetIn(Path, Value, Dict)
{
    local
    Sig := "Dict_SetIn(Path, Value, Dict)"
    _Validate_ArrayArg(Sig, "Path", Path)
    _Validate_DictArg(Sig, "Dict", Dict)
    return _Validate_BlamePath(Sig
                              ,Func("_Dict_Reconstruct")
                                   .Bind(Path
                                        ,Func_Rearg(Func("Dict_Set"), [1, 0, 2]).Bind(Value)
                                        ,Dict))
}

Dict_UpdateIn(Path, Func, Dict)
{
    local
    Sig := "Dict_UpdateIn(Path, Func, Dict)"
    _Validate_ArrayArg(Sig, "Path", Path)
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_DictArg(Sig, "Dict", Dict)
    return _Validate_BlamePath(Sig
                              ,Func("_Dict_Reconstruct")
                                   .Bind(Path
                                        ,Func_Rearg(Func("Dict_Update"), [1, 0, 2]).Bind(Func)
                                        ,Dict))
}

Dict_DeleteIn(Path, Dict)
{
    local
    Sig := "Dict_DeleteIn(Path, Dict)"
    _Validate_ArrayArg(Sig, "Path", Path)
    _Validate_DictArg(Sig, "Dict", Dict)
    return _Validate_BlamePath(Sig
                              ,Func("_Dict_Reconstruct")
                                   .Bind(Path
                                        ,Func("Dict_Delete")
                                        ,Dict))
}

Dict_Merge(Func, Dicts*)
{
    local
    Sig := "Dict_Merge(Func, Dicts*)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_DictArgs(Sig, Dicts)
    if (Dicts.Count() == 0)
    {
        Result := Dict()
    }
    else
    {
        Result := Dicts[1].Clone()
        Index  := 2
        while (Index <= Dicts.Count())
        {
            for Key, XValue in Dicts[Index]
            {
                if (Result.HasKey(Key))
                {
                    Result.Set(Key, Func.Call(Key, Result.Get(Key), XValue))
                }
                else
                {
                    Result.Set(Key, XValue)
                }
            }
            ++Index
        }
    }
    return Result
}

_Dict_UnionAux(Key, AValue, XValue)
{
    local
    return XValue
}

Dict_Union(Dicts*)
{
    local
    Sig := "Dict_Union(Dicts*)"
    _Validate_DictArgs(Sig, Dicts)
    return Dict_Merge(Func("_Dict_UnionAux"), Dicts*)
}

Dict_Intersection(Dicts*)
{
    local
    Sig := "Dict_Intersection(Dicts*)"
    _Validate_DictArgs(Sig, Dicts)
    if (Dicts.Count() == 0)
    {
        throw Exception("Arity Defect", -1
                       ,Sig)
    }
    else if (Dicts.Count() == 1)
    {
        Result := Dicts[1].Clone()
    }
    else
    {
        Result := Dict()
        for Key in Dicts[1]
        {
            if (Dicts[Dicts.Count()].HasKey(Key))
            {
                Result.Set(Key, Dicts[Dicts.Count()].Get(Key))
            }
        }
        Index  := 2
        Stop   := Dicts.Count() - 1
        while (Index <= Stop)
        {
            for Key in Result.Clone()
            {
                if (not Dicts[Index].HasKey(Key))
                {
                    Result.Delete(Key)
                }
            }
            ++Index
        }
    }
    return Result
}

Dict_Difference(Dicts*)
{
    local
    Sig := "Dict_Difference(Dicts*)"
    _Validate_DictArgs(Sig, Dicts)
    if (Dicts.Count() == 0)
    {
        throw Exception("Arity Defect", -1
                       ,Sig)
    }
    else
    {
        Result := Dicts[1].Clone()
        Index  := 2
        while (Index <= Dicts.Count())
        {
            for Key in Dicts[Index]
            {
                if (Result.HasKey(Key))
                {
                    Result.Delete(Key)
                }
            }
            ++Index
        }
    }
    return Result
}

Dict_IsDisjoint(Dicts*)
{
    local
    Sig := "Dict_IsDisjoint(Dicts*)"
    _Validate_DictArgs(Sig, Dicts)
    Result := true
    if (Dicts.Count() == 2)
    {
        if (Dicts[1].Count() <= Dicts[2].Count())
        {
            LesserEnum := Dicts[1]._NewEnum()
            Greater    := Dicts[2]
        }
        else
        {
            LesserEnum := Dicts[2]._NewEnum()
            Greater    := Dicts[1]
        }
        while (Result and LesserEnum.Next(Key))
        {
            if (Greater.HasKey(Key))
            {
                Result := false
            }
        }
    }
    else if (Dicts.Count() > 2)
    {
        CumulativeUnion := Dicts[1].Clone()
        Index           := 2
        while (Result and Index <= Dicts.Count())
        {
            DictEnum := Dicts[Index]._NewEnum()
            while (Result and DictEnum.Next(Key))
            {
                if (CumulativeUnion.HasKey(Key))
                {
                    Result := false
                }
                else
                {
                    CumulativeUnion.Set(Key, "")
                }
            }
            ++Index
        }
    }
    return Result
}

Dict_Fold(Func, Init, Dict)
{
    local
    Sig := "Dict_Fold(Func, Init, Dict)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_DictArg(Sig, "Dict", Dict)
    Enum := Dict._NewEnum()
    A    := Init
    while (Enum.Next(Key, Value))
    {
        A := Func.Call(A, [Key, Value])
    }
    return A
}

Dict_Fold1(Func, Dict)
{
    local
    Sig := "Dict_Fold1(Func, Dict)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_NonEmptyDictArg(Sig, "Dict", Dict)
    Enum := Dict._NewEnum()
    Enum.Next(Key, Value)
    A    := [Key, Value]
    while (Enum.Next(Key, Value))
    {
        A := Func.Call(A, [Key, Value])
    }
    return A
}

_Dict_FilterAux(Pred, A, X)
{
    local
    if (Pred.Call(X))
    {
        A.Set(X*)
    }
    return A
}

Dict_Filter(Pred, Dict)
{
    local
    Sig := "Dict_Filter(Pred, Dict)"
    _Validate_FuncArg(Sig, "Pred", Pred)
    _Validate_DictArg(Sig, "Dict", Dict)
    return Dict_Fold(Func("_Dict_FilterAux").Bind(Pred), Dict(), Dict)
}

Dict_KeyPred(Pred)
{
    local
    Sig := "Dict_KeyPred(Pred)"
    _Validate_FuncArg(Sig, "Pred", Pred)
    return Func_Comp(Pred, Func("Array_Get").Bind(0))
}

Dict_ValuePred(Pred)
{
    local
    Sig := "Dict_ValuePred(Pred)"
    _Validate_FuncArg(Sig, "Pred", Pred)
    return Func_Comp(Pred, Func("Array_Get").Bind(1))
}

_Dict_MapAux(Func, A, X)
{
    local
    NewItem := Func.Call(X)
    if (not A.HasKey(NewItem[1]))
    {
        A.Set(NewItem*)
    }
    else
    {
        throw Exception("Value Defect", -3
                       ,"Dict_Map(Func, Dict)  Func is not injective for keys.")
    }
    return A
}

Dict_Map(Func, Dict)
{
    local
    Sig := "Dict_Map(Func, Dict)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_DictArg(Sig, "Dict", Dict)
    return Dict_Fold(Func("_Dict_MapAux").Bind(Func), Dict(), Dict)
}

Dict_KeyFunc(Func)
{
    local
    Sig := "Dict_KeyFunc(Func)"
    _Validate_FuncArg(Sig, "Func", Func)
    return Func_ApplyArgsWith(Func("Array")
                                  ,[Func_Comp(Func, Func("Array_Get").Bind(0))
                                   ,Func("Array_Get").Bind(1)])
}

Dict_ValueFunc(Func)
{
    local
    Sig := "Dict_ValueFunc(Func)"
    _Validate_FuncArg(Sig, "Func", Func)
    return Func_ApplyArgsWith(Func("Array")
                                  ,[Func("Array_Get").Bind(0)
                                   ,Func_Comp(Func, Func("Array_Get").Bind(1))])
}

_Dict_InvertAux(X)
{
    local
    return [X[2], X[1]]
}

Dict_Invert(Dict)
{
    local
    Sig := "Dict_Invert(Dict)"
    _Validate_DictArg(Sig, "Dict", Dict)
    try
    {
        Result := Dict_Map(Func("_Dict_InvertAux"), Dict)
    }
    catch E
    {
        if (    E.Message == "Value Defect"
            and E.Extra   == "Dict_Map(Func, Dict)  Func is not injective for keys.")
        {
            throw Exception("Value Defect", -1
                           ,Format("{1}  Dict contains duplicate values.", Sig))
        }
        else
        {
            throw E
        }
    }
    return Result
}

Dict_Items(Dict)
{
    local
    Sig := "Dict_Items(Dict)"
    _Validate_DictArg(Sig, "Dict", Dict)
    Result := []
    Result.SetCapacity(Dict.Count())
    return Dict_Fold(Func("_Push")
                    ,Result
                    ,Dict)
}

Dict_Keys(Dict)
{
    local
    Sig := "Dict_Keys(Dict)"
    _Validate_DictArg(Sig, "Dict", Dict)
    Result := []
    Result.SetCapacity(Dict.Count())
    return Dict_Fold(Func_HookL(Func("_Push"), Func("Array_Get").Bind(0))
                    ,Result
                    ,Dict)
}

Dict_Values(Dict)
{
    local
    Sig := "Dict_Values(Dict)"
    _Validate_DictArg(Sig, "Dict", Dict)
    Result := []
    Result.SetCapacity(Dict.Count())
    return Dict_Fold(Func_HookL(Func("_Push"), Func("Array_Get").Bind(1))
                    ,Result
                    ,Dict)
}
