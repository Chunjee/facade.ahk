#include %A_LineFile%\..\Type.ahk

IsFuncObj(Value)
{
    local
    Result := false
    while (not Result and Value != "")
    {
        Type := Type(Value)
        Result := Type == "Func" or Type == "BoundFunc"
        try
        {
            ; Work around a defect causing BoundFuncs to execute when their Call
            ; property is read.
            Value := not Result ? Value.Call : ""  ; "" when Call does not exist
        }
        catch
        {
            Value := ""
        }
    }
    return Result
}
