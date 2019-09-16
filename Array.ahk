#include %A_LineFile%\..\Is.ahk
#include %A_LineFile%\..\Type.ahk
#include %A_LineFile%\..\_IsArray.ahk
#include %A_LineFile%\..\_Validate.ahk
#include %A_LineFile%\..\Op.ahk
#include %A_LineFile%\..\Func.ahk
#include %A_LineFile%\..\_Push.ahk
#include %A_LineFile%\..\_Dict.ahk
#include %A_LineFile%\..\_DedupBy.ahk
#include %A_LineFile%\..\_Sinks.ahk

Array_FromBadArray(Func, Array, Length := "")
{
    local
    Length := Length == "" ? Array.Length() : Length
    Sig := "Array_FromBadArray(Func, Array [, Length])"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_BadArrayArg(Sig, "Array", Array)
    _Validate_NonNegIntegerArg(Sig, "Length", Length)
    if (Length < Array.Length())
    {
        throw Exception("Value Defect", -1
                       ,Format("{1}  Length < Array length.", Sig))
    }
    Result := []
    Result.SetCapacity(Length)
    loop % Length
    {
        Result[A_Index] := Array.HasKey(A_Index) ? Array[A_Index]
                         : Func.Call(A_Index - 1)
    }
    return Result
}

Array_ToBadArray(Pred, Array)
{
    local
    Sig := "Array_ToBadArray(Pred, Array)"
    _Validate_FuncArg(Sig, "Pred", Pred)
    _Validate_BadArrayArg(Sig, "Array", Array)
    Result := []
    for Index, Value in Array
    {
        if (    Is(Index, "integer")
            and 1 <= Index
            and not Pred.Call(Index - 1, Value))
        {
            Result[Index] := Value
        }
    }
    Result.SetCapacity(0)
    return Result
}

Array_IsArray(Value)
{
    local
    return _IsArray(Value)
}

Array_IsEmpty(Value)
{
    local
    return Type(Value) == "Object" and Value.Count() == 0
}

Array_Count(Array)
{
    local
    Sig := "Array_Count(Array)"
    _Validate_ArrayArg(Sig, "Array", Array)
    return Array.Count()
}

Array_Get(I, Array)
{
    local
    Sig := "Array_Get(I, Array)"
    _Validate_IntegerArg(Sig, "I", I)
    _Validate_ArrayArg(Sig, "Array", Array)
    BadIndex := I >= 0 ? 1 + I : Array.Count() + 1 + I
    if (not Op_Le(1, BadIndex, Array.Count()))
    {
        throw Exception("Index Defect", -1
                       ,Format("{1}  I is out of bounds.  I is {2}.", Sig, I))
    }
    return Array[BadIndex]
}

Array_Interpose(Between, Array, BeforeLast := "")
{
    local
    Sig := "Array_Interpose(Between, Array [, BeforeLast])"
    _Validate_ArrayArg(Sig, "Array", Array)
    Result := []
    Result.SetCapacity(Array.Count() * 2 - 1)
    loop % Array.Count()
    {
        if (A_Index != 1)
        {
            if (A_Index == Array.Count() and BeforeLast != "")
            {
                Result.Push(BeforeLast)
            }
            else
            {
                Result.Push(Between)
            }
        }
        Result.Push(Array[A_Index])
    }
    return Result
}

_Array_ConcatAux(A, X)
{
    local
    A.Push(X*)
    return A
}

Array_Concat(Arrays*)
{
    local
    Sig := "Array_Concat(Arrays*)"
    _Validate_ArrayArgs(Sig, Arrays)
    Result := []
    Result.SetCapacity(Array_FoldL(Func_HookL(Func("Op_Add")
                                             ,Func("Array_Count"))
                                  ,0
                                  ,Arrays))
    return Array_FoldL(Func("_Array_ConcatAux"), Result, Arrays)
}

_Array_FlattenAux(A, X)
{
    local
    if (Array_IsArray(X))
    {
        A.Push(Array_Flatten(X)*)
    }
    else
    {
        A.Push(X)
    }
    return A
}

Array_Flatten(Array)
{
    local
    Sig := "Array_Flatten(Array)"
    _Validate_ArrayArg(Sig, "Array", Array)
    Result := Array_FoldL(Func("_Array_FlattenAux"), [], Array)
    Result.SetCapacity(0)
    return Result
}

Array_All(Pred, Array)
{
    local
    Sig := "Array_All(Pred, Array)"
    _Validate_FuncArg(Sig, "Pred", Pred)
    _Validate_ArrayArg(Sig, "Array", Array)
    return _Sinks_All(Pred, Array)
}

Array_Exists(Pred, Array)
{
    local
    Sig := "Array_Exists(Pred, Array)"
    _Validate_FuncArg(Sig, "Pred", Pred)
    _Validate_ArrayArg(Sig, "Array", Array)
    return _Sinks_Exists(Pred, Array)
}

Array_FoldL(Func, Init, Array)
{
    local
    Sig := "Array_FoldL(Func, Init, Array)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_ArrayArg(Sig, "Array", Array)
    A     := Init
    Index := 1
    while (Index <= Array.Count())
    {
        A := Func.Call(A, Array[Index])
        ++Index
    }
    return A
}

Array_FoldR(Func, Init, Array)
{
    local
    Sig := "Array_FoldR(Func, Init, Array)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_ArrayArg(Sig, "Array", Array)
    A     := Init
    Index := Array.Count()
    while (Index >= 1)
    {
        A := Func.Call(Array[Index], A)
        --Index
    }
    return A
}

Array_FoldL1(Func, Array)
{
    local
    Sig := "Array_FoldL1(Func, Array)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_NonEmptyArrayArg(Sig, "Array", Array)
    A     := Array[1]
    Index := 2
    while (Index <= Array.Count())
    {
        A := Func.Call(A, Array[Index])
        ++Index
    }
    return A
}

Array_FoldR1(Func, Array)
{
    local
    Sig := "Array_FoldR1(Func, Array)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_NonEmptyArrayArg(Sig, "Array", Array)
    A     := Array[Array.Count()]
    Index := Array.Count() - 1
    while (Index >= 1)
    {
        A := Func.Call(Array[Index], A)
        --Index
    }
    return A
}

_Array_ScanLAux(Func, A, X)
{
    local
    A.Push(Func.Call(A[A.Count()], X))
    return A
}

Array_ScanL(Func, Init, Array)
{
    local
    Sig := "Array_ScanL(Func, Init, Array)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_ArrayArg(Sig, "Array", Array)
    Result := [Init]
    Result.SetCapacity(Array.Count() + 1)
    return Array_FoldL(Func("_Array_ScanLAux").Bind(Func)
                      ,Result
                      ,Array)
}

_Array_ScanRAux(Func, X, A)
{
    local
    A.Push(Func.Call(X, A[A.Count()]))
    return A
}

Array_ScanR(Func, Init, Array)
{
    local
    Sig := "Array_ScanR(Func, Init, Array)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_ArrayArg(Sig, "Array", Array)
    Result := [Init]
    Result.SetCapacity(Array.Count() + 1)
    return Array_Reverse(Array_FoldR(Func("_Array_ScanRAux").Bind(Func)
                                    ,Result
                                    ,Array))
}

_Array_ScanL1Aux(Func, A, X)
{
    local
    if (A.Count() == 0)
    {
        A.Push(X)
    }
    else
    {
        A.Push(Func.Call(A[A.Count()], X))
    }
    return A
}

Array_ScanL1(Func, Array)
{
    local
    Sig := "Array_ScanL1(Func, Array)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_ArrayArg(Sig, "Array", Array)
    Result := []
    if (Array.Count() > 0)
    {
        Result.SetCapacity(Array.Count())
        Result := Array_FoldL(Func("_Array_ScanL1Aux").Bind(Func)
                             ,Result
                             ,Array)
    }
    return Result
}

_Array_ScanR1Aux(Func, X, A)
{
    local
    if (A.Count() == 0)
    {
        A.Push(X)
    }
    else
    {
        A.Push(Func.Call(X, A[A.Count()]))
    }
    return A
}

Array_ScanR1(Func, Array)
{
    local
    Sig := "Array_ScanR1(Func, Array)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_ArrayArg(Sig, "Array", Array)
    Result := []
    if (Array.Count() > 0)
    {
        Result.SetCapacity(Array.Count())
        Result := Array_Reverse(Array_FoldR(Func("_Array_ScanR1Aux").Bind(Func)
                                           ,Result
                                           ,Array))
    }
    return Result
}

Array_MinBy(Func, Array)
{
    local
    Sig := "Array_MinBy(Func, Array)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_NonEmptyArrayArg(Sig, "Array", Array)
    return _Sinks_MinBy(Func, Array)
}

Array_MaxBy(Func, Array)
{
    local
    Sig := "Array_MaxBy(Func, Array)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_NonEmptyArrayArg(Sig, "Array", Array)
    return _Sinks_MaxBy(Func, Array)
}

Array_MinKBy(Func, K, Array)
{
    local
    Sig := "Array_MinKBy(Func, K, Array)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_NonNegIntegerArg(Sig, "K", K)
    _Validate_ArrayArg(Sig, "Array", Array)
    return _Sinks_MinKBy(Func, K, Array)
}

Array_MaxKBy(Func, K, Array)
{
    local
    Sig := "Array_MaxKBy(Func, K, Array)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_NonNegIntegerArg(Sig, "K", K)
    _Validate_ArrayArg(Sig, "Array", Array)
    return _Sinks_MaxKBy(Func, K, Array)
}

_Array_FilterAux(Pred, A, X)
{
    local
    if (Pred.Call(X))
    {
        A.Push(X)
    }
    return A
}

Array_Filter(Pred, Array)
{
    local
    Sig := "Array_Filter(Pred, Array)"
    _Validate_FuncArg(Sig, "Pred", Pred)
    _Validate_ArrayArg(Sig, "Array", Array)
    Result := Array_FoldL(Func("_Array_FilterAux").Bind(Pred), [], Array)
    Result.SetCapacity(0)
    return Result
}

Array_DedupBy(Func, Array)
{
    local
    global Dict
    Sig := "Array_DedupBy(Func, Array)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_ArrayArg(Sig, "Array", Array)
    return Array_Filter(Func("_DedupBy").Bind(new Dict(), Func), Array)
}

Array_Map(Func, Array)
{
    local
    Sig := "Array_Map(Func, Array)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_ArrayArg(Sig, "Array", Array)
    return Array_ZipWith(Func, Array)
}

Array_StructWith(Func, K, Array)
{
    local
    Sig := "Array_StructWith(Func, K, Array)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_NonNegIntegerArg(Sig, "K", K)
    _Validate_ArrayArg(Sig, "Array", Array)
    Result := []
    if (K != 0 and Array.Count() != 0)
    {
        Result.SetCapacity(Op_Mod(Array.Count(), K) == 0 ? Floor(Array.Count() / K)
                         : Ceil(Array.Count() / K))
        I := 1
        loop
        {
            Args := []
            Args.SetCapacity(K)
            J := Min(I + K - 1, Array.Count())
            loop
            {
                Args.Push(Array[I])
                ++I
            }
            until (I > J)
            Result.Push(Func.Call(Args*))
        }
        until (I > Array.Count())
    }
    return Result
}

Array_ZipWith(Func, Arrays*)
{
    local
    Sig := "Array_ZipWith(Func, Arrays*)"
    _Validate_FuncArg(Sig, "Func", Func)
    if (Arrays.Count() == 0)
    {
        throw Exception("Arity Defect", -1
                       ,Sig)
    }
    _Validate_ArrayArgs(Sig, Arrays)
    Count := Array_MinBy(Func("Array_Count"), Arrays).Count()
    Result := []
    Result.SetCapacity(Count)
    loop % Count
    {
        N := A_Index
        Args := []
        Args.SetCapacity(Arrays.Count())
        loop % Arrays.Count()
        {
            Args.Push(Arrays[A_Index][N])
        }
        Result.Push(Func.Call(Args*))
    }
    return Result
}

Array_ConcatZipWith(Func, Arrays*)
{
    local
    Sig := "Array_ConcatZipWith(Func, Arrays*)"
    _Validate_FuncArg(Sig, "Func", Func)
    if (Arrays.Count() == 0)
    {
        throw Exception("Arity Defect", -1
                       ,Sig)
    }
    _Validate_ArrayArgs(Sig, Arrays)
    Result := []
    loop % Array_MinBy(Func("Array_Count"), Arrays).Count()
    {
        N := A_Index
        Args := []
        Args.SetCapacity(Arrays.Count())
        loop % Arrays.Count()
        {
            Args.Push(Arrays[A_Index][N])
        }
        Result.Push(Func.Call(Args*)*)
    }
    Result.SetCapacity(0)
    return Result
}

Array_Reverse(Array)
{
    local
    Sig := "Array_Reverse(Array)"
    _Validate_ArrayArg(Sig, "Array", Array)
    Result := []
    Result.SetCapacity(Array.Count())
    return Array_FoldR(Func_Flip(Func("_Push")), Result, Array)
}

Array_Sort(Pred, Array)
{
    ; This is bottom-up merge sort.
    local
    Sig := "Array_Sort(Pred, Array)"
    _Validate_FuncArg(Sig, "Pred", Pred)
    _Validate_ArrayArg(Sig, "Array", Array)
    ; Always return a copy.
    Result := Array.Clone()
    if (Array.Count() > 1)
    {
        RunLength := 1
        Index     := 1
        WorkArray := []
        WorkArray.SetCapacity(Array.Count())
        while (RunLength < Array.Count())
        {
            while (Index <= Array.Count())
            {
                LeftFirst  := Index
                LeftLast   := Min(LeftFirst + RunLength - 1,  Array.Count())
                RightFirst := Min(LeftLast + 1,               Array.Count() + 1)
                RightLast  := Min(RightFirst + RunLength - 1, Array.Count())
                while (Index <= RightLast)
                {
                    if (    LeftFirst <= LeftLast
                        and (   RightFirst > RightLast
                             or Pred.Call(Result[LeftFirst], Result[RightFirst])))
                    {
                        WorkArray[Index] := Result[LeftFirst]
                        ++LeftFirst
                    }
                    else
                    {
                        WorkArray[Index] := Result[RightFirst]
                        ++RightFirst
                    }
                    ++Index
                }
            }
            RunLength *= 2
            Index     := 1
            Temp      := Result
            Result    := WorkArray
            WorkArray := Temp
        }
    }
    return Result
}

Array_GroupBy(Func, Array)
{
    local
    Sig := "Array_GroupBy(Func, Array)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_ArrayArg(Sig, "Array", Array)
    return Array_GroupByWMap(Func, Func("Func_Id"), Array)
}

Array_GroupByWMap(ByFunc, MapFunc, Array)
{
    local
    Sig := "Array_GroupByWMap(ByFunc, MapFunc, Array)"
    _Validate_FuncArg(Sig, "ByFunc", ByFunc)
    _Validate_FuncArg(Sig, "MapFunc", MapFunc)
    _Validate_ArrayArg(Sig, "Array", Array)
    return _Sinks_GroupByWMap(ByFunc, MapFunc, Array)
}

Array_GroupByWFold1Map(ByFunc, FoldFunc, MapFunc, Array)
{
    local
    Sig := "Array_GroupByWFold1Map(ByFunc, FoldFunc, MapFunc, Array)"
    _Validate_FuncArg(Sig, "ByFunc", ByFunc)
    _Validate_FuncArg(Sig, "FoldFunc", FoldFunc)
    _Validate_FuncArg(Sig, "MapFunc", MapFunc)
    _Validate_ArrayArg(Sig, "Array", Array)
    return _Sinks_GroupByWFold1Map(ByFunc, FoldFunc, MapFunc, Array)
}
