#Include Is.ahk

class _Type
{
    Property
    {
    }
}

Type(Value)
{
    local
    global _Type
    ; This should be updated when a new built-in type is added to AutoHotkey.
    static BoundFunc             := Func("Type").Bind("")
    static ComObjArrayEnumerator := ComObjArray(0x11, 1)._NewEnum()
    static ComObjectEnumerator   := ComObjCreate("Scripting.Dictionary")._NewEnum()
    static File                  := FileOpen(A_ScriptFullPath, "r")
    static Func                  := Func("Type")
    static ObjectEnumerator      := {}._NewEnum()
    static Property              := ObjRawGet(_Type, "Property")
    static RegExMatch, _         := RegExMatch("a" ,"O)a", RegExMatch)
    ; If you try to convert the above to expressions and get the addresses, the
    ; result is incorrect.
    static TypeFromAddress := {NumGet(&BoundFunc):             "BoundFunc"
                              ,NumGet(&ComObjArrayEnumerator): "ComObjArray.Enumerator"
                              ,NumGet(&ComObjectEnumerator):   "ComObject.Enumerator"
                              ,NumGet(&File):                  "File"
                              ,NumGet(&Func):                  "Func"
                              ,NumGet(&ObjectEnumerator):      "Object.Enumerator"
                              ,NumGet(&Property):              "Property"
                              ,NumGet(&RegExMatch):            "RegExMatch"}
    if (Is(Value, "object"))
    {
        if (TypeFromAddress.HasKey(NumGet(&Value)))
        {
            Result := TypeFromAddress[NumGet(&Value)]
        }
        else if (ComObjType(Value) != "")
        {
            if (ComObjType(Value) & 0x2000)
            {
                Result := "ComObjArray"
            }
            else if (ComObjType(Value) & 0x4000)
            {
                Result := "ComObjRef"
            }
            else if (    (ComObjType(Value) == 9 or ComObjType(Value) == 13)
                     and ComObjValue(Value) != 0)
            {
                Result := ComObjType(Value, "Class") != "" ? ComObjType(Value, "Class")
                        : "ComObject"
            }
            else
            {
                Result := "ComObj"
            }
        }
        else
        {
            ; This is complicated because it must avoid running meta-functions.
            Result := ObjHasKey(Value, "__Class") ? "Class" : ""
            try
            {
                CurrentObject := ObjGetBase(Value)
            }
            catch
            {
                CurrentObject := ""
            }
            while (Result == "" and CurrentObject != "")
            {
                try
                {
                    Result        := ObjRawGet(CurrentObject, "__Class")
                    CurrentObject := ObjGetBase(CurrentObject)
                }
                catch
                {
                    CurrentObject := ""
                }
            }
            Result := Result == "" ? "Object" : Result
        }
    }
    else
    {
        Result := Is(Value, "integer") ? "Integer"
                : Is(Value, "float")   ? "Float"
                : "String"
    }
    return Result
}
