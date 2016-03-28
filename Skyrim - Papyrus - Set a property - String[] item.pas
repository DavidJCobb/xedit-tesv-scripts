{
   For each selected object that has the specified Papyrus script attached, create a 
   property on that script with the specified name and assign it the specified string. 
   (If the property already exists, it is set -- a duplicate is not added.)
   
   We don't check the new property name against the script source, so it's possible 
   to add invalid properties with this.

   Created by DavidJCobb.
}
Unit CobbSingleSetPapyrusString;
Uses 'Skyrim - Papyrus Resource Library';
Uses 'CobbTES5EditUtil';

Var
   gsScriptName: String;
   gsPropertyName: String;
   giIndex: Integer;
   gsValue: String;

Function Initialize: integer;
Var
   sType: String;
   slLabels: TStringList;
   slResult: TStringList;
Begin
   sType := 'String[]';
   //
   // Ask the user what to do.
   //
   slLabels := TStringList.Create;
   slLabels.Add('Add property to what script?');
   slLabels.Add(sType + ' property name?');
   slLabels.Add('Index in the array?');
   slLabels.Add('Enter the value of the new property.');
   slResult := PromptForStrings('Set ' + sType + 'property', slLabels);
   If slResult.Count = 0 Then Begin
      Result := 1;
      Exit;
   End Else Begin
      gsScriptName := slResult[0];
      gsPropertyName := slResult[1];
      giIndex := StrToInt(Trim(slResult[2]));
      gsValue := slResult[3];
   End;
End;

Function Process(e: IInterface) : Integer;
Begin
   If ElementType(e) = etMainRecord Then
      If ElementExists(e, 'VMAD') Then Begin
         SetStringArrayPropertyItemOnScript(GetScript(e, gsScriptName), gsPropertyName, giIndex, gsValue);
      End;
End;

End.