Is(Value, Type)
{
    local
    static Types := {"integer": ""
                    ,"float":   ""
                    ,"number":  ""
                    ,"digit":   ""
                    ,"xdigit":  ""
                    ,"alpha":   ""
                    ,"upper":   ""
                    ,"lower":   ""
                    ,"alnum":   ""
                    ,"space":   ""
                    ,"time":    ""}
    Result := false
    if (Types.HasKey(Type))
    {
        ; AutoHotkey v1 correctly classifies -Inf, Inf, and NaN as Float values.
        ; AutoHotkey v2 currently does not.
        if Value is %Type%
        {
            Result := true
        }
        ; Work around a defect causing Inf and NaN to be classified as
        ; lowercase.  AutoHotkey v2 currently has the same defect.
        VarSetCapacity(Inf, 8)
        NumPut(0x7FF0000000000000, Inf,, "UInt64")
        Inf := NumGet(Inf,, "Double")
        if (        (Value == Inf or Value != Value)
            and not (Type = "number" or Type = "float"))
        {
            Result := false
        }
    }
    else if (Type = "object")
    {
        Result := IsObject(Value)
    }
    else
    {
        try
        {
            CurrentObject := ObjGetBase(Value)
        }
        catch
        {
            CurrentObject := ""
        }
        while (not Result and CurrentObject != "")
        {
            try
            {
                Result        := CurrentObject == Type
                CurrentObject := ObjGetBase(CurrentObject)
            }
            catch
            {
                CurrentObject := ""
            }
        }
    }
    return Result
}
