#include %A_LineFile%\..\Is.ahk
#include %A_LineFile%\..\_Validate.ahk
#include %A_LineFile%\..\Op.ahk
#include %A_LineFile%\..\Func.ahk
#include %A_LineFile%\..\_Push.ahk
#include %A_LineFile%\..\_Dict.ahk
#include %A_LineFile%\..\_DedupBy.ahk
#include %A_LineFile%\..\_Sinks.ahk
#include %A_LineFile%\..\Array.ahk

;-------------------------------------------------------------------------------
; Sources

class Stream
{
    ; This makes Is(Value, Type) work correctly for Streams.

    Bind(Args*)
    {
        local
        return this
    }

    Call()
    {
        local
        return this
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

    class Enumerator
    {
        __New(Stream)
        {
            local
            this._Index  := 1
            this._Stream := Stream
            return this
        }

        Next(byref Index, byref Value := "")
        {
            local
            if (not Stream_IsEmpty(this._Stream))
            {
                Index        := this._Index
                Value        := Stream_First(this._Stream)
                this._Index  := this._Index + 1
                this._Stream := Stream_Rest(this._Stream)
                Result       := true
            }
            else
            {
                Result := false
            }
            return Result
        }
    }

    _NewEnum()
    {
        local
        global Stream
        return new Stream.Enumerator(this)
    }
}

class STREAM_NULL extends Stream
{
    ; This is the constant singleton empty Stream.
}

class Stream_Memo extends Stream
{
    ; This is defined as a Stream type because that is how it is normally used,
    ; but it is also used to memoize functions that are not Streams.  This, like
    ; its use of mutation for caching, should not be observable externally.
    ;
    ; Note that STREAM_NULL and Stream_Cons cells are self-evaluating forms.

    __New(Func)
    {
        local
        this._Reified := false
        this._Place   := Func
        return this
    }

    Call()
    {
        local
        if (this._Reified)
        {
            Result := this._Place
        }
        else
        {
            Result        := this._Place.Call()
            this._Reified := true
            this._Place   := Result
        }
        return Result
    }
}

class Stream_Cons extends Stream
{
    __New(First, Rest)
    {
        local
        global Stream_Memo
        this._First := new Stream_Memo(First)
        this._Rest  := new Stream_Memo(Rest)
        return this
    }
}

Stream(Args*)
{
    local
    global STREAM_NULL
    Sig := "Stream(Args*)"
    _Validate_Args(Sig, Args)
    return Array_FoldR(Func("Stream_Prepend"), STREAM_NULL, Args)
}

Stream_Prepend(First, Rest)
{
    local
    global Stream_Cons
    Sig := "Stream_Prepend(First, Rest)"
    _Validate_StreamArg(Sig, "Rest", Rest)
    return new Stream_Cons(Func_Const(First), Rest)
}

_Stream_UnfoldFirstAux(MapFunc, Init)
{
    local
    return MapFunc.Call(Init)
}

_Stream_UnfoldRestAux(MapFunc, Pred, GenFunc, Init)
{
    local
    return _Stream_UnfoldAux(MapFunc, Pred, GenFunc, GenFunc.Call(Init))
}

_Stream_UnfoldAux(MapFunc, Pred, GenFunc, Init)
{
    local
    global Stream_Cons
    return Pred.Call(Init) ? new Stream_Cons(Func("_Stream_UnfoldFirstAux")
                                                 .Bind(MapFunc, Init)
                                            ,Func("_Stream_UnfoldRestAux")
                                                 .Bind(MapFunc, Pred, GenFunc, Init))
         : Stream()
}

Stream_Unfold(MapFunc, Pred, GenFunc, Init)
{
    local
    global Stream_Memo
    Sig := "Stream_Unfold(MapFunc, Pred, GenFunc, Init)"
    _Validate_FuncArg(Sig, "MapFunc", MapFunc)
    _Validate_FuncArg(Sig, "Pred", Pred)
    _Validate_FuncArg(Sig, "GenFunc", GenFunc)
    return new Stream_Memo(Func("_Stream_UnfoldAux")
                               .Bind(MapFunc, Pred, GenFunc, Init))
}

Stream_Gen(Func, Init)
{
    local
    Sig := "Stream_Gen(Func, Init)"
    _Validate_FuncArg(Sig, "Func", Func)
    return Stream_Unfold(Func("Func_Id"), Func_Const(true), Func, Init)
}

Stream_From(Start, Step := 1)
{
    local
    Sig := "Stream_From(Start [, Step])"
    _Validate_NumberArg(Sig, "Start", Start)
    _Validate_NonZeroIntegerArg(Sig, "Step", Step)
    return Stream_Gen(Func("Op_Add").Bind(Step), Is(Step, "float") ? Op_Float(Start) : Start)
}

Stream_Range(Start, Stop, Step := 1)
{
    local
    Sig := "Stream_Range(Start, Stop [, Step])"
    _Validate_NumberArg(Sig, "Start", Start)
    _Validate_NumberArg(Sig, "Stop", Stop)
    _Validate_NonZeroIntegerArg(Sig, "Step", Step)
    return Start < Stop and Step < 0 ? Stream()
         : Start > Stop and Step > 0 ? Stream()
         : Stream_TakeWhile(Start < Stop ? Func("Op_Gt").Bind(Stop) : Func("Op_Lt").Bind(Stop)
                           ,Stream_From(Is(Stop, "float") ? Op_Float(Start) : Start, Step))
}

_Stream_CycleRestAux(I, Array)
{
    local
    return _Stream_CycleAux(Op_Mod(I + 1, Array.Count()), Array)
}

_Stream_CycleAux(I, Array)
{
    local
    global Stream_Cons
    return new Stream_Cons(Func("Array_Get")
                               .Bind(I, Array)
                          ,Func("_Stream_CycleRestAux")
                               .Bind(I, Array))
}

Stream_Cycle(Array)
{
    local
    global Stream_Memo
    Sig := "Stream_Cycle(Array)"
    _Validate_ArrayArg(Sig, "Array", Array)
    return Array.Count() == 0 ? Stream()
         : new Stream_Memo(Func("_Stream_CycleAux")
                          .Bind(0, Array))
}

_Stream_PermFirstAux(Indices, K, Array)
{
    local
    return Stream_ToArray(Stream_Map(Func_Flip(Func("Array_Get")).Bind(Array)
                                    ,Stream_Map(Func_Flip(Func("Array_Get")).Bind(Indices)
                                               ,Stream_Range(0, K))))
}

_Stream_PermRestAux(Cycles, Indices, K, Array)
{
    ; This algorithm is derived from Python's itertools.permutations(p [, r]).
    ; It is not the same.  itertools.permutations(p [, r]) is a generator.  This
    ; is a function.  I have been unable to find an algorithm elsewhere that
    ; computes permutations in lexicographic order, where the length of the
    ; permutations are not necessarily the same as the length of the sequence to
    ; permute.  I found it difficult to reverse engineer, so I will explain how
    ; it works to the best of my ability.
    ;
    ; The basic idea is like counting up, like an odometer, in a strange number
    ; system.  The digits come, in order, from the sequence to permute.  This is
    ; permutations without repetition, so a digit that appears in a more
    ; significant place cannot appear in a less significant place.  When you
    ; read phrases like "least-" or "most significant", "place", and "rolling
    ; over", remember this context.
    ;
    ; The algorithm accepts the preceding Cycles and Indices Arrays and computes
    ; the current Cycles and Indices Arrays.  The Cycles Array counts down for
    ; each node like an odometer counts up, but unlike an odometer, less
    ; significant places have less digits to account for there being no
    ; repetition.  It is used to compute the current Indices Array and to
    ; determine when the Stream should terminate.  The Indices Array contains
    ; indices into the Array that contains the sequence to permute.  It is used
    ; (specifically, the leading K elements of it are used) to compute the
    ; current permutation.
    ;
    ; The algorithm obviously only computes permutations because indices are
    ; only rearranged, not recomputed (i.e. the algorithm cannot introduce
    ; duplicate indices).  How it does this is less obvious.  When places in
    ; Cycles roll over, it triggers left rotations in Indices.  A single swap in
    ; Indices is always performed after the potential left rotations.  The
    ; rotations restore digits to lexicographical order.  This makes it possible
    ; for a negated value from Cycles to locate the correct index to swap with.
    ;
    ; Be aware that this algorithm has been altered to work with 1-based indices
    ; internally (the Indices Array itself contains 0-based indices) because it
    ; must use indices in lvalues!
    local
    ; We cannot mutate Indices because it is retained by our "first" closures.
    Indices := Indices.Clone()
    ; Initialize I to the least significant (rightmost) place.
    I := K
    ; Decrement the cycles of the least significant place.
    Cycles[I] -= 1
    ; Handle places rolling over.
    while (I > 0 and Cycles[I] == 0)
    {
        ; Reset the cycles of this place.
        Cycles[I] := Array.Count() - (I - 1)
        ; Rotate left the indices from I to the last 1 place.
        Temp := Indices.RemoveAt(I)
        Indices.Push(Temp)
        ; Point I to the next most significant place.
        --I
        ; If possible, decrement the cycles of the next most significant place.
        if (I > 0)
        {
            Cycles[I] -= 1
        }
    }
    if (I > 0)
    {
        ; I is this place and J is the number of cycles remaining in this place.
        J := Cycles[I]
        ; Swap I's and -J's respective indices.
        Temp                             := Indices[I]
        Indices[I]                       := Indices[Array.Count() - (J - 1)]
        Indices[Array.Count() - (J - 1)] := Temp
        ; Return a permutation.
        Result := _Stream_PermAux(Cycles, Indices, K, Array)
    }
    else
    {
        ; There are no more permutations to return.
        Result := Stream()
    }
    return Result
}

_Stream_PermAux(Cycles, Indices, K, Array)
{
    local
    global Stream_Cons
    return new Stream_Cons(Func("_Stream_PermFirstAux")
                               .Bind(Indices, K, Array)
                          ,Func("_Stream_PermRestAux")
                               .Bind(Cycles, Indices, K, Array))
}

Stream_Perm(K, Array)
{
    local
    global Stream_Memo
    Sig := "Stream_Perm(K, Array)"
    _Validate_NonNegIntegerArg(Sig, "K", K)
    _Validate_ArrayArg(Sig, "Array", Array)
    return K == 0            ? Stream([])
         : K > Array.Count() ? Stream()
         : new Stream_Memo(Func("_Stream_PermAux")
                               .Bind(Stream_ToArray(Stream_Range(Array.Count(), Array.Count() - K, -1))
                                    ,Stream_ToArray(Stream_Range(0, Array.Count()))
                                    ,K
                                    ,Array))
}

Stream_PermWRep(K, Array)
{
    local
    Sig := "Stream_PermWRep(K, Array)"
    _Validate_NonNegIntegerArg(Sig, "K", K)
    _Validate_ArrayArg(Sig, "Array", Array)
    return Stream_CartProd(Stream_ToArray(Stream_Take(K, Stream_Cycle([Array])))*)
}

_Stream_CombRestAux(Indices, Array)
{
    local
    Indices := Indices.Clone()
    I := Indices.Count()
    ; Find the least significant place that can be incremented without causing
    ; it or any less significant places to exceed Array bounds.
    while (I > 0 and Indices[I] + 1 > Array.Count() - 1 - Indices.Count() + I)
    {
        --I
    }
    if (I > 0)
    {
        ; Increment that place.
        Indices[I] := Indices[I] + 1
        ; Overwrite any less significant places with increments following the
        ; new value.
        for _, I in Stream_Range(I + 1, Indices.Count() + 1)
        {
            Indices[I] := Indices[I - 1] + 1
        }
        Result := _Stream_CombAux(Indices, Array)
    }
    else
    {
        Result := Stream()
    }
    return Result
}

_Stream_CombAux(Indices, Array)
{
    local
    global Stream_Cons
    return new Stream_Cons(Func("Array_Map")
                               .Bind(Func_Flip(Func("Array_Get")).Bind(Array), Indices)
                          ,Func("_Stream_CombRestAux")
                               .Bind(Indices, Array))
}

Stream_Comb(K, Array)
{
    local
    global Stream_Memo
    Sig := "Stream_Comb(K, Array)"
    _Validate_NonNegIntegerArg(Sig, "K", K)
    _Validate_ArrayArg(Sig, "Array", Array)
    return K == 0            ? Stream([])
         : K > Array.Count() ? Stream()
         : new Stream_Memo(Func("_Stream_CombAux")
                               .Bind(Stream_ToArray(Stream_Range(0, K))
                                    ,Array))
}

_Stream_CombWRepRestAux(Indices, Array)
{
    local
    Indices := Indices.Clone()
    I := Indices.Count()
    ; Find the least significant place that can be incremented without causing
    ; it to exceed Array bounds.
    while (I > 0 and Indices[I] + 1 > Array.Count() - 1)
    {
        --I
    }
    if (I > 0)
    {
        ; Increment that place.
        Indices[I] := Indices[I] + 1
        ; Overwrite any less significant places with the new value.
        for _, I in Stream_Range(I + 1, Indices.Count() + 1)
        {
            Indices[I] := Indices[I - 1]
        }
        Result := _Stream_CombWRepAux(Indices, Array)
    }
    else
    {
        Result := Stream()
    }
    return Result
}

_Stream_CombWRepAux(Indices, Array)
{
    local
    global Stream_Cons
    return new Stream_Cons(Func("Array_Map")
                               .Bind(Func_Flip(Func("Array_Get")).Bind(Array), Indices)
                          ,Func("_Stream_CombWRepRestAux")
                               .Bind(Indices, Array))
}

Stream_CombWRep(K, Array)
{
    local
    global Stream_Memo
    Sig := "Stream_CombWRep(K, Array)"
    _Validate_NonNegIntegerArg(Sig, "K", K)
    _Validate_ArrayArg(Sig, "Array", Array)
    return K == 0            ? Stream([])
         : K > Array.Count() ? Stream()
         : new Stream_Memo(Func("_Stream_CombWRepAux")
                               .Bind(Stream_ToArray(Stream_Take(K, Stream_Cycle([0])))
                                    ,Array))
}

Stream_PowerSet(Array)
{
    local
    Sig := "Stream_PowerSet(Array)"
    _Validate_ArrayArg(Sig, "Array", Array)
    return Stream_ConcatZipWith(Func_Flip(Func("Stream_Comb")).Bind(Array)
                               ,Stream_Range(0, Array.Count() + 1))
}

_Stream_CartProdRestAux(Indices, Arrays)
{
    ; Count up like an odometer--an odometer that can have different digits for
    ; each place.
    local
    Indices := Indices.Clone()
    I := Indices.Count()
    Indices[I] += 1
    while (I > 0 and Indices[I] > Arrays[I].Count() - 1)
    {
        Indices[I] := 0
        --I
        if (I > 0)
        {
            Indices[I] += 1
        }
    }
    if (I > 0)
    {
        Result := _Stream_CartProdAux(Indices, Arrays)
    }
    else
    {
        Result := Stream()
    }
    return Result
}

_Stream_CartProdAux(Indices, Arrays)
{
    local
    global Stream_Cons
    return new Stream_Cons(Func("Array_ZipWith")
                               .Bind(Func("Array_Get"), Indices, Arrays)
                          ,Func("_Stream_CartProdRestAux")
                               .Bind(Indices, Arrays))
}

Stream_CartProd(Arrays*)
{
    local
    global Stream_Memo
    Sig := "Stream_CartProd(Arrays*)"
    _Validate_ArrayArgs(Sig, Arrays)
    return Arrays.Count() == 0                                                         ? Stream([])
         : Array_Exists(Func_Comp(Func("Op_Eq").Bind(0), Func("Array_Count")), Arrays) ? Stream()
         : new Stream_Memo(Func("_Stream_CartProdAux")
                               .Bind(Stream_ToArray(Stream_Take(Arrays.Count(), Stream_Cycle([0])))
                                    ,Arrays))
}


;-------------------------------------------------------------------------------
; Flows

_Stream_TakeAux(K, Stream)
{
    local
    global Stream_Cons
    return K == 0 or Stream_IsEmpty(Stream) ? Stream()
         : new Stream_Cons(Func("Stream_First")
                               .Bind(Stream)
                          ,Func("_Stream_TakeAux")
                               .Bind(K - 1, Stream_Rest(Stream)))
}

Stream_Take(K, Stream)
{
    local
    global Stream_Memo
    Sig := "Stream_Take(K, Stream)"
    _Validate_NonNegIntegerArg(Sig, "K", K)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return new Stream_Memo(Func("_Stream_TakeAux")
                               .Bind(K, Stream))
}

_Stream_TakeWhileAux(Pred, Stream)
{
    local
    global Stream_Cons
    return Stream_IsEmpty(Stream) ? Stream()
         : Pred.Call(Stream_First(Stream)) ? new Stream_Cons(Func("Stream_First")
                                                                 .Bind(Stream)
                                                            ,Func("_Stream_TakeWhileAux")
                                                                 .Bind(Pred, Stream_Rest(Stream)))
                                           : Stream()
}

Stream_TakeWhile(Pred, Stream)
{
    local
    global Stream_Memo
    Sig := "Stream_TakeWhile(Pred, Stream)"
    _Validate_FuncArg(Sig, "Pred", Pred)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return new Stream_Memo(Func("_Stream_TakeWhileAux")
                               .Bind(Pred, Stream))
}

_Stream_DropAux(K, Stream)
{
    local
    while (K != 0 and not Stream_IsEmpty(Stream))
    {
        --K
        Stream := Stream_Rest(Stream)
    }
    return Stream.Call()
}

Stream_Drop(K, Stream)
{
    local
    global Stream_Memo
    Sig := "Stream_Drop(K, Stream)"
    _Validate_NonNegIntegerArg(Sig, "K", K)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return new Stream_Memo(Func("_Stream_DropAux")
                               .Bind(K, Stream))
}

_Stream_DropWhileAux(Pred, Stream)
{
    local
    while (not Stream_IsEmpty(Stream) and Pred.Call(Stream_First(Stream)))
    {
        Stream := Stream_Rest(Stream)
    }
    return Stream.Call()
}

Stream_DropWhile(Pred, Stream)
{
    local
    global Stream_Memo
    Sig := "Stream_DropWhile(Pred, Stream)"
    _Validate_FuncArg(Sig, "Pred", Pred)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return new Stream_Memo(Func("_Stream_DropWhileAux")
                               .Bind(Pred, Stream))
}

_Stream_ConcatAux(Streams)
{
    local
    global Stream_Cons
    loop
    {
        Stream := Streams.Pop()
    }
    until (not Stream_IsEmpty(Stream) or Streams.Count() == 0)
    return Stream_IsEmpty(Stream) ? Stream()
         : new Stream_Cons(Func("Stream_First")
                               .Bind(Stream)
                          ,Func("_Stream_ConcatAux")
                               .Bind(_Push(Streams, Stream_Rest(Stream))))
}

Stream_Concat(Streams*)
{
    local
    global Stream_Memo
    Sig := "Stream_Concat(Streams*)"
    _Validate_StreamArgs(Sig, Streams)
    return Streams.Count() == 0 ? Stream()
         : Streams.Count() == 1 ? Streams[1]
         : new Stream_Memo(Func("_Stream_ConcatAux")
                               .Bind(Array_Reverse(Streams)))
}

_Stream_FlattenAux(Stack, Stream)
{
    local
    global Stream_Cons
    Result := Stream()
    while (    Stream_IsEmpty(Result)
           and (not Stream_IsEmpty(Stream) or Stack.Count() != 0))
    {
        if (Stream_IsEmpty(Stream))
        {
            Stream := Stack.Pop()
        }
        else
        {
            if (Stream_IsStream(Stream_First(Stream)))
            {
                if (Stream_IsEmpty(Stream_First(Stream)))
                {
                    Stream := Stream_Rest(Stream)
                }
                else
                {
                    Stack.Push(Stream_Rest(Stream))
                    Stream := Stream_First(Stream)
                }
            }
            else
            {
                Result := new Stream_Cons(Func("Stream_First")
                                              .Bind(Stream)
                                         ,Func("_Stream_FlattenAux")
                                              .Bind(Stack, Stream_Rest(Stream)))
            }
        }
    }
    return Result
}

Stream_Flatten(Stream)
{
    local
    global Stream_Memo
    Sig := "Stream_Flatten(Stream)"
    _Validate_StreamArg(Sig, "Stream", Stream)
    return new Stream_Memo(Func("_Stream_FlattenAux")
                               .Bind([], Stream))
}

_Stream_ScanAux(Func, A, Stream)
{
    local
    global Stream_Cons
    if (Stream_IsEmpty(Stream))
    {
        Result := Stream()
    }
    else
    {
        A := Func.Call(A, Stream_First(Stream))
        Result := new Stream_Cons(Func_Const(A)
                                 ,Func("_Stream_ScanAux")
                                      .Bind(Func, A, Stream_Rest(Stream)))
    }
    return Result
}

Stream_Scan(Func, Init, Stream)
{
    local
    global Stream_Memo
    Sig := "Stream_Scan(Func, Init, Stream)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return Stream_Prepend(Init
                         ,new Stream_Memo(Func("_Stream_ScanAux")
                                              .Bind(Func, Init, Stream)))
}

_Stream_Scan1Aux(Func, Stream)
{
    local
    return Stream_IsEmpty(Stream) ? Stream()
         : Stream_Scan(Func, Stream_First(Stream), Stream_Rest(Stream)).Call()
}

Stream_Scan1(Func, Stream)
{
    local
    global Stream_Memo
    Sig := "Stream_Scan1(Func, Stream)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return new Stream_Memo(Func("_Stream_Scan1Aux")
                               .Bind(Func, Stream))
}

_Stream_FilterAux(Pred, Stream)
{
    local
    global Stream_Cons
    Result := ""
    loop
    {
        if (Stream_IsEmpty(Stream))
        {
            Result := Stream()
        }
        else if (Pred.Call(Stream_First(Stream)))
        {
            Result := new Stream_Cons(Func("Stream_First")
                                          .Bind(Stream)
                                     ,Func("_Stream_FilterAux")
                                          .Bind(Pred, Stream_Rest(Stream)))
        }
        else
        {
            Stream := Stream_Rest(Stream)
        }
    }
    until (Result != "")
    return Result
}

Stream_Filter(Pred, Stream)
{
    local
    global Stream_Memo
    Sig := "Stream_Filter(Pred, Stream)"
    _Validate_FuncArg(Sig, "Pred", Pred)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return new Stream_Memo(Func("_Stream_FilterAux")
                               .Bind(Pred, Stream))
}

Stream_DedupBy(Func, Stream)
{
    local
    global Dict
    Sig := "Stream_DedupBy(Func, Stream)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return Stream_Filter(Func("_DedupBy").Bind(new Dict(), Func), Stream)
}

Stream_Map(Func, Stream)
{
    local
    Sig := "Stream_Map(Func, Stream)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return Stream_ZipWith(Func, Stream)
}

_Stream_StructWithFirstAux(Func, K, Stream)
{
    local
    return Func.Call(Stream_ToArray(Stream_Take(K, Stream))*)
}

_Stream_StructWithAux(Func, K, Stream)
{
    local
    global Stream_Cons
    return Stream_IsEmpty(Stream) ? Stream()
         : new Stream_Cons(Func("_Stream_StructWithFirstAux")
                               .Bind(Func, K, Stream)
                          ,Func("_Stream_StructWithAux")
                               .Bind(Func, K, Stream_Drop(K, Stream)))
}

Stream_StructWith(Func, K, Stream)
{
    local
    global Stream_Memo
    Sig := "Stream_StructWith(Func, K, Stream)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_NonNegIntegerArg(Sig, "K", K)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return K == 0 ? Stream()
         : new Stream_Memo(Func("_Stream_StructWithAux")
                               .Bind(Func, K, Stream))
}

_Stream_ZipWithFirstAux(Func, Streams)
{
    local
    return Func.Call(Array_Map(Func("Stream_First"), Streams)*)
}

_Stream_ZipWithAux(Func, Streams)
{
    local
    global Stream_Cons
    return Array_Exists(Func("Stream_IsEmpty"), Streams) ? Stream()
         : new Stream_Cons(Func("_Stream_ZipWithFirstAux")
                               .Bind(Func, Streams)
                          ,Func("_Stream_ZipWithAux")
                               .Bind(Func, Array_Map(Func("Stream_Rest"), Streams)))
}

Stream_ZipWith(Func, Streams*)
{
    local
    global Stream_Memo
    Sig := "Stream_ZipWith(Func, Streams*)"
    _Validate_FuncArg(Sig, "Func", Func)
    if (Streams.Count() == 0)
    {
        throw Exception("Arity Defect", -1
                       ,Sig)
    }
    _Validate_StreamArgs(Sig, Streams)
    return new Stream_Memo(Func("_Stream_ZipWithAux")
                               .Bind(Func, Streams))
}

_Stream_ConcatZipWithAux(Output, Func, Streams)
{
    local
    global Stream_Cons
    while (    Stream_IsEmpty(Output)
           and not Array_Exists(Func("Stream_IsEmpty"), Streams))
    {
        Output  := Func.Call(Array_Map(Func("Stream_First"), Streams)*)
        Streams := Array_Map(Func("Stream_Rest"), Streams)
    }
    return Stream_IsEmpty(Output) ? Stream()
         : new Stream_Cons(Func("Stream_First")
                               .Bind(Output)
                          ,Func("_Stream_ConcatZipWithAux")
                               .Bind(Stream_Rest(Output), Func, Streams))
}

Stream_ConcatZipWith(Func, Streams*)
{
    local
    global Stream_Memo
    Sig := "Stream_ConcatZipWith(Func, Streams*)"
    _Validate_FuncArg(Sig, "Func", Func)
    if (Streams.Count() == 0)
    {
        throw Exception("Arity Defect", -1
                       ,Sig)
    }
    _Validate_StreamArgs(Sig, Streams)
    return new Stream_Memo(Func("_Stream_ConcatZipWithAux")
                               .Bind(Stream(), Func, Streams))
}


;-------------------------------------------------------------------------------
; Recognizers, Accessors, and Sinks

Stream_IsStream(Value)
{
    local
    global Stream
    return Is(Value, Stream)
}

Stream_IsEmpty(Value)
{
    local
    global STREAM_NULL
    return Stream_IsStream(Value) and Value.Call() == STREAM_NULL
}

Stream_First(Stream)
{
    local
    Sig := "Stream_First(Stream)"
    _Validate_NonEmptyStreamArg(Sig, "Stream", Stream)
    return Stream.Call()._First.Call()
}

Stream_Rest(Stream)
{
    local
    Sig := "Stream_Rest(Stream)"
    _Validate_NonEmptyStreamArg(Sig, "Stream", Stream)
    return Stream.Call()._Rest
}

Stream_Count(Stream)
{
    local
    Sig := "Stream_Count(Stream)"
    _Validate_StreamArg(Sig, "Stream", Stream)
    return _Sinks_Count(Stream)
}

Stream_All(Pred, Stream)
{
    local
    Sig := "Stream_All(Pred, Stream)"
    _Validate_FuncArg(Sig, "Pred", Pred)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return _Sinks_All(Pred, Stream)
}

Stream_Exists(Pred, Stream)
{
    local
    Sig := "Stream_Exists(Pred, Stream)"
    _Validate_FuncArg(Sig, "Pred", Pred)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return _Sinks_Exists(Pred, Stream)
}

Stream_Fold(Func, Init, Stream)
{
    local
    Sig := "Stream_Fold(Func, Init, Stream)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_StreamArg(Sig, "Stream", Stream)
    A := Init
    while (not Stream_IsEmpty(Stream))
    {
        A      := Func.Call(A, Stream_First(Stream))
        Stream := Stream_Rest(Stream)
    }
    return A
}

Stream_Fold1(Func, Stream)
{
    local
    Sig := "Stream_Fold1(Func, Stream)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_NonEmptyStreamArg(Sig, "Stream", Stream)
    return Stream_Fold(Func, Stream_First(Stream), Stream_Rest(Stream))
}

Stream_MinBy(Func, Stream)
{
    local
    Sig := "Stream_MinBy(Func, Stream)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_NonEmptyStreamArg(Sig, "Stream", Stream)
    return _Sinks_MinBy(Func, Stream)
}

Stream_MaxBy(Func, Stream)
{
    local
    Sig := "Stream_MaxBy(Func, Stream)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_NonEmptyStreamArg(Sig, "Stream", Stream)
    return _Sinks_MaxBy(Func, Stream)
}

Stream_MinKBy(Func, K, Stream)
{
    local
    Sig := "Stream_MinKBy(Func, K, Stream)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_NonNegIntegerArg(Sig, "K", K)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return _Sinks_MinKBy(Func, K, Stream)
}

Stream_MaxKBy(Func, K, Stream)
{
    local
    Sig := "Stream_MaxKBy(Func, K, Stream)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_NonNegIntegerArg(Sig, "K", K)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return _Sinks_MaxKBy(Func, K, Stream)
}

Stream_ToArray(Stream)
{
    local
    Sig := "Stream_ToArray(Stream)"
    _Validate_StreamArg(Sig, "Stream", Stream)
    return _Sinks_ToArray(Stream)
}

Stream_GroupBy(Func, Stream)
{
    local
    Sig := "Stream_GroupBy(Func, Stream)"
    _Validate_FuncArg(Sig, "Func", Func)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return Stream_GroupByWMap(Func, Func("Func_Id"), Stream)
}

Stream_GroupByWMap(ByFunc, MapFunc, Stream)
{
    local
    Sig := "Stream_GroupByWMap(ByFunc, MapFunc, Stream)"
    _Validate_FuncArg(Sig, "ByFunc", ByFunc)
    _Validate_FuncArg(Sig, "MapFunc", MapFunc)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return _Sinks_GroupByWMap(ByFunc, MapFunc, Stream)
}

Stream_GroupByWFold1Map(ByFunc, FoldFunc, MapFunc, Stream)
{
    local
    Sig := "Stream_GroupByWFold1Map(ByFunc, FoldFunc, MapFunc, Stream)"
    _Validate_FuncArg(Sig, "ByFunc", ByFunc)
    _Validate_FuncArg(Sig, "FoldFunc", FoldFunc)
    _Validate_FuncArg(Sig, "MapFunc", MapFunc)
    _Validate_StreamArg(Sig, "Stream", Stream)
    return _Sinks_GroupByWFold1Map(ByFunc, FoldFunc, MapFunc, Stream)
}
