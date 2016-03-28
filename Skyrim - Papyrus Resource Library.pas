{
   Resource library. WORK IN PROGRESS.
   
   PROPERTY TYPE VALUES:
    1 - Object (any forms or aliases)
    2 - String
    3 - Int32
    4 - Float
    5 - Bool
   11 - Array of Object
   12 - Array of String
   13 - Array of Int32
   14 - Array of Float
   15 - Array of Bool
}
Unit CobbPapyrus;

{Searches for and returns a script attached to a form.}
Function GetScript(aeForm: IInterface; asName: String): IInterface;
Var
   sElemName: String;
   eVMAD: IInterface;
   eScripts: IInterface;
   iCurrentScript: Integer;
   eCurrentScript: IInterface;
   sCurrentScript: String;
   eNewScript: IInterface;
Begin
   eVMAD := ElementBySignature(aeForm, 'VMAD');
   If Not Assigned(eVMAD) Then Exit;
   eScripts := ElementByPath(eVMAD, 'Data\Scripts');
   If Signature(aeForm) = 'QUST' Then eScripts := ElementByPath(eVMAD, 'Data\Quest VMAD\Scripts');
   For iCurrentScript := 0 To ElementCount(eScripts) - 1 Do Begin
      eCurrentScript := ElementByIndex(eScripts, iCurrentScript);
      If Name(eCurrentScript) = 'Script' Then Begin
         sCurrentScript := GetEditValue(ElementByName(eCurrentScript, 'scriptName'));
	 If sCurrentScript = asName Then Begin
	    Result := eCurrentScript;
	    Exit;
	 End;
      End;
   End;
End;

{Attaches a script to a form, but only if the form doesn't already have that script (or if the abRedundant argument is True).}
Function AttachScript(aeForm: IInterface; asName: String; abRedundant: Boolean): IInterface;
Var
   sElemName: String;
   eVMAD: IInterface;
   eScripts: IInterface;
   iCurrentScript: Integer;
   eCurrentScript: IInterface;
   sCurrentScript: String;
   eNewScript: IInterface;
Begin
   Result := GetScript(aeForm, asName);
   If Not Assigned(Result) Or abRedundant Then Begin
      Add(aeForm, 'VMAD', True);
      SetElementNativeValues(aeForm, 'VMAD\Version', 5);
      SetElementNativeValues(aeForm, 'VMAD\Object Format', 2);
      eVMAD := ElementBySignature(aeForm, 'VMAD');
      eScripts := ElementByPath(eVMAD, 'Data\Scripts');
      If Signature(aeForm) = 'QUST' Then eScripts := ElementByPath(eVMAD, 'Data\Quest VMAD\Scripts');
      eNewScript := ElementAssign(eScripts, HighInteger, nil, False);
      SetEditValue(ElementByName(eNewScript, 'scriptName'), asName);
      Result := eNewScript;
   End;
End;

{Removes all attached copies of a given script from a given form.}
Procedure RemoveScript(aeForm: IInterface; asName: String);
Var
   sElemName: String;
   eVMAD: IInterface;
   eScripts: IInterface;
   iCurrentScript: Integer;
   eCurrentScript: IInterface;
   sCurrentScript: String;
   eNewScript: IInterface;
   iScriptsToKillCount: Integer;
   elScriptsToKill: Array[0..512] of IInterface;
Begin
   eVMAD := ElementBySignature(aeForm, 'VMAD');
   If Not Assigned(eVMAD) Then Exit;
   eScripts := ElementByPath(eVMAD, 'Data\Scripts');
   If Signature(aeForm) = 'QUST' Then eScripts := ElementByPath(eVMAD, 'Data\Quest VMAD\Scripts');
   //
   iScriptsToKillCount := 0;
   //
   For iCurrentScript := 0 To ElementCount(eScripts) - 1 Do Begin
      eCurrentScript := ElementByIndex(eScripts, iCurrentScript);
      If Name(eCurrentScript) = 'Script' Then Begin
         sCurrentScript := GetEditValue(ElementByName(eCurrentScript, 'scriptName'));
	 If (sCurrentScript = asName) And (iScriptsToKillCount < 512) Then Begin
	    //
	    // Mark this script for removal.
	    //
	    elScriptsToKill[iScriptsToKillCount] := eCurrentScript;
	    iScriptsToKillCount := iScriptsToKillCount + 1;
	 End;
      End;
   End;
   //
   // Remove the found scripts.
   //
   For iCurrentScript := 0 To iScriptsToKillCount Do Begin
      Remove(elScriptsToKill[iCurrentScript]);
   End;
   //If iScriptsToKillCount > 0 Then AddMessage(Format('Removed %d copies of script %s from %s.', [iScriptsToKillCount, asName, Name(aeForm)]));
End;

{Returns the matching property node in the given script. Pass -1 as the type to select any type.}
Function GetPropertyFromScript(aeScript: IInterface; asPropertyName: String; aiPropertyType: Integer) : IInterface;
Var
   eProperties: IInterface;
   iCurrentProperty: Integer;
   eCurrentProperty: IInterface;
   sCurrentProperty: String;
   iCurrentPropertyType: Integer;
Begin
   eProperties := ElementByName(aeScript, 'Properties');
   For iCurrentProperty := 0 To ElementCount(eProperties) - 1 Do Begin
      eCurrentProperty := ElementByIndex(eProperties, iCurrentProperty);
      If Name(eCurrentProperty) = 'Property' Then Begin
         sCurrentProperty := GetEditValue(ElementByName(eCurrentProperty, 'propertyName'));
         iCurrentPropertyType := GetNativeValue(ElementByName(eCurrentProperty, 'Type'));
         If (sCurrentProperty = asPropertyName) And ((iCurrentPropertyType = aiPropertyType) Or (aiPropertyType = -1)) Then Begin
            Result := eCurrentProperty;
	    Exit;
         End;
      End;
   End;
End;

{Returns or creates a property on a script. Sets the out variable to True if the property had to be created.}
Function GetOrMakePropertyOnScript(aeScript: IInterface; asPropertyName: String; aiPropertyType: Integer; out abResult : Boolean) : IInterface;
Var
   eProperties: IInterface;
   iCurrentProperty: Integer;
   eCurrentProperty: IInterface;
   sCurrentProperty: String;
   iCurrentPropertyType: Integer;
Begin
   eProperties := ElementByName(aeScript, 'Properties');
   Result := GetPropertyFromScript(aeScript, asPropertyName, aiPropertyType);
   If Assigned(Result) Then Exit;
   abResult := True;
   //
   // Create the property if it does not exist. The immediate child nodes (propertyName 
   // and friends) will be created and managed by TES5Edit, more-or-less automatically; 
   // we'll just have to set their values.
   //
   eCurrentProperty := ElementAssign(eProperties, HighInteger, nil, False);
   SetEditValue(ElementByName(eCurrentProperty, 'propertyName'), asPropertyName);
   SetNativeValue(ElementByName(eCurrentProperty, 'Type'), aiPropertyType);
   SetNativeValue(ElementByName(eCurrentProperty, 'Flags'), 1); // "Edited"
   Result := eCurrentProperty;
End;

Procedure RenamePropertyOnScript(aeScript: IInterface; asPropertyName: String; asNewName: String);
Var
   eProperty: IInterface;
Begin
   eProperty := GetPropertyFromScript(aeScript, asPropertyName, -1);
   If Not Assigned(eProperty) Then Exit;
   SetEditValue(ElementByName(eProperty, 'propertyName'), asNewName);
End;

{$REGION 'Functions to set scalar script properties.'}
{Function for Type 1 (Form) properties. Accepts an integer FormID, a string FormID, or an element; these must be passed in as a Variant variable.}
Function SetFormPropertyOnScript(aeScript: IInterface; asPropertyName: String; avPropertyValue: Variant) : Boolean;
Var
   eProperties: IInterface;
   eTargetProperty: IInterface;
   bAlreadyExisted: Boolean;
   iFormID: Integer;
Begin
   Try
      iFormID := avPropertyValue;
   Except
      Try
         iFormID := StrToIntDef('$' + avPropertyValue, 0);
      Except
         iFormID := FormID(avPropertyValue);
      End;
   End;
   eProperties := ElementByName(aeScript, 'Properties');
   eTargetProperty := GetOrMakePropertyOnScript(aeScript, asPropertyName, 1, bAlreadyExisted);
   SetNativeValue(ElementByName(eTargetProperty, 'Flags'), 1); // "Edited"
   SetElementNativeValues(eTargetProperty, 'Value\Object Union\Object v2\FormID', iFormID);
   SetElementNativeValues(eTargetProperty, 'Value\Object Union\Object v2\Alias', -1);
   Result := Not bAlreadyExisted;
End;

{
   Function for Type 1 (Alias) properties. Accepts the quest as a variant, 
   and the ID of an alias in that quest.
}
Function SetAliasPropertyOnScript(aeScript: IInterface; asPropertyName: String; avPropertyQuest: Variant, aiAliasIndex: Integer = 0) : Boolean;
Var
   eProperties: IInterface;
   eTargetProperty: IInterface;
   bAlreadyExisted: Boolean;
   iQuestFormID: Integer;
Begin
   Try
      iQuestFormID := avPropertyQuest;
   Except
      Try
         iQuestFormID := StrToIntDef('$' + avPropertyQuest, 0);
      Except
         iQuestFormID := FormID(avPropertyQuest);
      End;
   End;
   eProperties := ElementByName(aeScript, 'Properties');
   eTargetProperty := GetOrMakePropertyOnScript(aeScript, asPropertyName, 1, bAlreadyExisted);
   SetNativeValue(ElementByName(eTargetProperty, 'Flags'), 1); // "Edited"
   SetElementNativeValues(eTargetProperty, 'Value\Object Union\Object v2\FormID', iQuestFormID);
   SetElementNativeValues(eTargetProperty, 'Value\Object Union\Object v2\Alias', aiAliasIndex);
   Result := Not bAlreadyExisted;
End;

{Function for Type 2 (String) properties.}
Function SetStringPropertyOnScript(aeScript: IInterface; asPropertyName: String; asPropertyValue: String) : Boolean;
Var
   eProperties: IInterface;
   eTargetProperty: IInterface;
   bAlreadyExisted: Boolean;
Begin
   eProperties := ElementByName(aeScript, 'Properties');
   eTargetProperty := GetOrMakePropertyOnScript(aeScript, asPropertyName, 2, bAlreadyExisted);
   SetNativeValue(ElementByName(eTargetProperty, 'Flags'), 1); // "Edited"
   SetEditValue(ElementByName(eTargetProperty, 'String'), asPropertyValue);
   Result := Not bAlreadyExisted;
End;

{Function for Type 3 (Int) properties.}
Function SetIntPropertyOnScript(aeScript: IInterface; asPropertyName: String; aiPropertyValue: Integer) : Boolean;
Var
   eProperties: IInterface;
   eTargetProperty: IInterface;
   bAlreadyExisted: Boolean;
Begin
   eProperties := ElementByName(aeScript, 'Properties');
   eTargetProperty := GetOrMakePropertyOnScript(aeScript, asPropertyName, 3, bAlreadyExisted);
   SetNativeValue(ElementByName(eTargetProperty, 'Flags'), 1); // "Edited"
   SetNativeValue(ElementByName(eTargetProperty, 'Int32'), aiPropertyValue);
   Result := Not bAlreadyExisted;
End;

{Function for Type 4 (Float) properties.}
Function SetFloatPropertyOnScript(aeScript: IInterface; asPropertyName: String; afPropertyValue: Float) : Boolean;
Var
   eProperties: IInterface;
   eTargetProperty: IInterface;
   bAlreadyExisted: Boolean;
Begin
   eProperties := ElementByName(aeScript, 'Properties');
   eTargetProperty := GetOrMakePropertyOnScript(aeScript, asPropertyName, 4, bAlreadyExisted);
   SetNativeValue(ElementByName(eTargetProperty, 'Flags'), 1); // "Edited"
   SetNativeValue(ElementByName(eTargetProperty, 'Float'), afPropertyValue);
   Result := Not bAlreadyExisted;
End;

{Function for Type 5 (Bool) properties.}
Function SetBoolPropertyOnScript(aeScript: IInterface; asPropertyName: String; abPropertyValue: Boolean) : Boolean;
Var
   eProperties: IInterface;
   eTargetProperty: IInterface;
   bAlreadyExisted: Boolean;
Begin
   eProperties := ElementByName(aeScript, 'Properties');
   eTargetProperty := GetOrMakePropertyOnScript(aeScript, asPropertyName, 5, bAlreadyExisted);
   SetNativeValue(ElementByName(eTargetProperty, 'Flags'), 1); // "Edited"
   SetNativeValue(ElementByName(eTargetProperty, 'Float'), abPropertyValue);
   Result := Not bAlreadyExisted;
End;
{$ENDREGION}

{$REGION 'Functions to set Form array script properties.'}
{Function for Type 11 (Form) properties. The values must be specified as a TStringList of FormIDs.}
Procedure SetFormArrayPropertyOnScript(aeScript: IInterface; asPropertyName: String; aslPropertyValues: TStringList);
Var
   eProperties: IInterface;
   eProperty: IInterface;
   eValues: IInterface;
   iIterator: Integer;
   eValue: IInterface;
   iValue: Integer;
   bThrowaway: Boolean;
Begin
   eProperties := ElementByName(aeScript, 'Properties');
   eProperty := GetOrMakePropertyOnScript(aeScript, asPropertyName, 11, bThrowaway);
   SetNativeValue(ElementByName(eProperty, 'Flags'), 1); // "Edited"
   eValues := ElementByIndex(ElementByName(eProperty, 'Value'), 0);
   For iIterator := 0 To aslPropertyValues.Count - 1 Do Begin
      iValue := StrToIntDef('$' + aslPropertyValues[iIterator], 0);
      eValue := ElementByIndex(eValues, iIterator);
      If Not Assigned(eValue) Then eValue := ElementAssign(eValues, HighInteger, nil, False);
      SetElementNativeValue(eValue, 'Object v2\FormID', iValue);
      SetElementNativeValue(eValue, 'Object v2\Alias', -1);
   End;
   If aslPropertyValues.Count < ElementCount(eValues) Then Begin
      iThrowaway := ElementCount(eValues) - 1;
      For iIterator := aslPropertyValues.Count To iThrowaway Do Begin
         Remove(ElementByIndex(eValues, aslPropertyValues.Count));
      End;
   End;
End;

{Function for Type 11 (Form) properties, to set an individual array element.}
Procedure SetFormArrayPropertyItemOnScript(aeScript: IInterface; asPropertyName: String; aiIndex: Integer; avValue: Variant);
Var
   eProperties: IInterface;
   eProperty: IInterface;
   eValues: IInterface;
   iIterator: Integer;
   eValue: IInterface;
   iValue: Integer;
   bThrowaway: Boolean;
Begin
   Try
      iValue := avValue;
   Except
      Try
         iValue := StrToIntDef('$' + avValue, 0);
      Except
         iValue := FormID(avValue);
      End;
   End;
   eProperties := ElementByName(aeScript, 'Properties');
   eProperty := GetOrMakePropertyOnScript(aeScript, asPropertyName, 11, bThrowaway);
   SetNativeValue(ElementByName(eProperty, 'Flags'), 1); // "Edited"
   eValues := ElementByIndex(ElementByName(eProperty, 'Value'), 0);
   For iIterator := 0 To aiIndex Do Begin
      eValue := ElementByIndex(eValues, iIterator);
      If Not Assigned(eValue) Then eValue := ElementAssign(eValues, HighInteger, nil, False);
      If iIterator = aiIndex Then Begin
         SetElementNativeValues(eValue, 'Object v2\FormID', iValue);
         SetElementNativeValues(eValue, 'Object v2\Alias', -1);
      End;
   End;
End;
{$ENDREGION}

{$REGION 'UNIMPLEMENTED - Functions to set Alias array script properties.'}
{$ENDREGION}

{$REGION 'Functions to set String array script properties.'}
{Function for Type 12 (String) properties. The values must be specified as a TStringList of FormIDs.}
Procedure SetStringArrayPropertyOnScript(aeScript: IInterface; asPropertyName: String; aslPropertyValues: TStringList);
Var
   eProperties: IInterface;
   eProperty: IInterface;
   eValues: IInterface;
   iIterator: Integer;
   eValue: IInterface;
   bThrowaway: Boolean;
Begin
   eProperties := ElementByName(aeScript, 'Properties');
   eProperty := GetOrMakePropertyOnScript(aeScript, asPropertyName, 12, bThrowaway);
   SetNativeValue(ElementByName(eProperty, 'Flags'), 1); // "Edited"
   eValues := ElementByIndex(ElementByName(eProperty, 'Value'), 0);
   For iIterator := 0 To aslPropertyValues.Count - 1 Do Begin
      eValue := ElementByIndex(eValues, iIterator);
      If Not Assigned(eValue) Then eValue := ElementAssign(eValues, HighInteger, nil, False);
      SetEditValue(eValue, aslPropertyValues[iIterator]);
   End;
   If aslPropertyValues.Count < ElementCount(eValues) Then Begin
      iThrowaway := ElementCount(eValues) - 1;
      For iIterator := aslPropertyValues.Count To iThrowaway Do Begin
         Remove(ElementByIndex(eValues, aslPropertyValues.Count));
      End;
   End;
End;

{Function for Type 12 (String) properties, to set an individual array element.}
Procedure SetStringArrayPropertyItemOnScript(aeScript: IInterface; asPropertyName: String; aiIndex: Integer; asValue: String);
Var
   eProperties: IInterface;
   eProperty: IInterface;
   eValues: IInterface;
   iIterator: Integer;
   eValue: IInterface;
   bThrowaway: Boolean;
Begin
   eProperties := ElementByName(aeScript, 'Properties');
   eProperty := GetOrMakePropertyOnScript(aeScript, asPropertyName, 12, bThrowaway);
   SetNativeValue(ElementByName(eProperty, 'Flags'), 1); // "Edited"
   eValues := ElementByIndex(ElementByName(eProperty, 'Value'), 0);
   For iIterator := 0 To aiIndex Do Begin
      eValue := ElementByIndex(eValues, iIterator);
      If Not Assigned(eValue) Then eValue := ElementAssign(eValues, HighInteger, nil, False);
      If iIterator = aiIndex Then Begin
         SetEditValue(eValue, asValue);
      End;
   End;
End;
{$ENDREGION}

{$REGION 'Functions to set Int array script properties.'}
{Function for Type 13 (Int) properties. The values must be specified as a TStringList.}
Procedure SetIntArrayPropertyOnScript(aeScript: IInterface; asPropertyName: String; aslPropertyValues: TStringList);
Var
   eProperties: IInterface;
   eProperty: IInterface;
   eValues: IInterface;
   iIterator: Integer;
   eValue: IInterface;
   iValue: Integer;
   bThrowaway: Boolean;
   iThrowaway: Integer;
Begin
   eProperties := ElementByName(aeScript, 'Properties');
   eProperty := GetOrMakePropertyOnScript(aeScript, asPropertyName, 13, bThrowaway);
   SetNativeValue(ElementByName(eProperty, 'Flags'), 1); // "Edited"
   eValues := ElementByIndex(ElementByName(eProperty, 'Value'), 0);
   For iIterator := 0 To aslPropertyValues.Count - 1 Do Begin
      iValue := StrToIntDef(aslPropertyValues[iIterator], 0);
      eValue := ElementByIndex(eValues, iIterator);
      If Not Assigned(eValue) Then eValue := ElementAssign(eValues, HighInteger, nil, False);
      SetNativeValue(eValue, iValue);
   End;
   If aslPropertyValues.Count < ElementCount(eValues) Then Begin
      iThrowaway := ElementCount(eValues) - 1;
      For iIterator := aslPropertyValues.Count To iThrowaway Do Begin
         Remove(ElementByIndex(eValues, aslPropertyValues.Count));
      End;
   End;
End;

{Function for Type 13 (Int) properties, to set an individual array element.}
Procedure SetIntArrayPropertyItemOnScript(aeScript: IInterface; asPropertyName: String; aiIndex: Integer; aiValue: Integer);
Var
   eProperties: IInterface;
   eProperty: IInterface;
   eValues: IInterface;
   iIterator: Integer;
   eValue: IInterface;
   iValue: Integer;
   bThrowaway: Boolean;
Begin
   eProperties := ElementByName(aeScript, 'Properties');
   eProperty := GetOrMakePropertyOnScript(aeScript, asPropertyName, 13, bThrowaway);
   SetNativeValue(ElementByName(eProperty, 'Flags'), 1); // "Edited"
   eValues := ElementByIndex(ElementByName(eProperty, 'Value'), 0);
   For iIterator := 0 To aiIndex Do Begin
      eValue := ElementByIndex(eValues, iIterator);
      If Not Assigned(eValue) Then eValue := ElementAssign(eValues, HighInteger, nil, False);
      If iIterator = aiIndex Then SetNativeValue(eValue, aiValue);
   End;
End;
{$ENDREGION}

{$REGION 'Functions to set Float array script properties.'}
{Function for Type 14 (Int) properties. The values must be specified as a TStringList.}
Procedure SetFloatArrayPropertyOnScript(aeScript: IInterface; asPropertyName: String; aslPropertyValues: TStringList);
Var
   eProperties: IInterface;
   eProperty: IInterface;
   eValues: IInterface;
   iIterator: Integer;
   eValue: IInterface;
   fValue: Float;
   bThrowaway: Boolean;
   iThrowaway: Integer;
Begin
   eProperties := ElementByName(aeScript, 'Properties');
   eProperty := GetOrMakePropertyOnScript(aeScript, asPropertyName, 14, bThrowaway);
   SetNativeValue(ElementByName(eProperty, 'Flags'), 1); // "Edited"
   eValues := ElementByIndex(ElementByName(eProperty, 'Value'), 0);
   For iIterator := 0 To aslPropertyValues.Count - 1 Do Begin
      fValue := StrToFloatDef(aslPropertyValues[iIterator], 0);
      eValue := ElementByIndex(eValues, iIterator);
      If Not Assigned(eValue) Then eValue := ElementAssign(eValues, HighInteger, nil, False);
      SetNativeValue(eValue, fValue);
   End;
   If aslPropertyValues.Count < ElementCount(eValues) Then Begin
      iThrowaway := ElementCount(eValues) - 1;
      For iIterator := aslPropertyValues.Count To iThrowaway Do Begin
         Remove(ElementByIndex(eValues, aslPropertyValues.Count));
      End;
   End;
End;

{Function for Type 14 (Int) properties, to set an individual array element.}
Procedure SetFloatArrayPropertyItemOnScript(aeScript: IInterface; asPropertyName: String; aiIndex: Integer; afValue: Float);
Var
   eProperties: IInterface;
   eProperty: IInterface;
   eValues: IInterface;
   iIterator: Integer;
   eValue: IInterface;
   bThrowaway: Boolean;
Begin
   eProperties := ElementByName(aeScript, 'Properties');
   eProperty := GetOrMakePropertyOnScript(aeScript, asPropertyName, 14, bThrowaway);
   SetNativeValue(ElementByName(eProperty, 'Flags'), 1); // "Edited"
   eValues := ElementByIndex(ElementByName(eProperty, 'Value'), 0);
   For iIterator := 0 To aiIndex Do Begin
      eValue := ElementByIndex(eValues, iIterator);
      If Not Assigned(eValue) Then eValue := ElementAssign(eValues, HighInteger, nil, False);
      If iIterator = aiIndex Then SetNativeValue(eValue, afValue);
   End;
End;
{$ENDREGION}

{$REGION 'UNIMPLEMENTED - Functions to set Boolean array script properties.'}
{$ENDREGION}


End.