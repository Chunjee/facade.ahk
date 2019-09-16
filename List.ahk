#Include Is.ahk
#Include _Validate.ahk
#Include _Sinks.ahk
#Include Array.ahk

class List
{
    ; This makes Is(Value, Type) work correctly for Lists.

    class Enumerator
    {
        __New(List)
        {
            local
            this._Index := 1
            this._List  := List
            return this
        }

        Next(byref Index, byref Value := "")
        {
            local
            if (not List_IsEmpty(this._List))
            {
                Index       := this._Index
                Value       := List_First(this._List)
                this._Index := this._Index + 1
                this._List  := List_Rest(this._List)
                Result      := true
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
        global List
        return new List.Enumerator(this)
    }
}

class LIST_NULL extends List
{
    ; This is the constant singleton empty List.
}

class List_Cons extends List
{
    __New(First, Rest)
    {
        local
        this._First := First
        this._Rest  := Rest
        return this
    }
}

List(Args*)
{
    local
    global LIST_NULL
    Sig := "List(Args*)"
    _Validate_Args(Sig, Args)
    return Array_FoldR(Func("List_Prepend"), LIST_NULL, Args)
}

List_Prepend(First, Rest)
{
    local
    global List_Cons
    Sig := "List_Prepend(First, Rest)"
    _Validate_ListArg(Sig, "Rest", Rest)
    return new List_Cons(First, Rest)
}

List_IsList(Value)
{
    local
    global List
    return Is(Value, List)
}

List_IsEmpty(Value)
{
    local
    global LIST_NULL
    return Value == LIST_NULL
}

List_First(List)
{
    local
    Sig := "List_First(List)"
    _Validate_NonEmptyListArg(Sig, "List", List)
    return List._First
}

List_Rest(List)
{
    local
    Sig := "List_Rest(List)"
    _Validate_NonEmptyListArg(Sig, "List", List)
    return List._Rest
}

List_ToArray(List)
{
    local
    Sig := "List_ToArray(List)"
    _Validate_ListArg(Sig, "List", List)
    return _Sinks_ToArray(List)
}
