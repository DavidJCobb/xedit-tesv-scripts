{
   For each selected object that has the specified Papyrus script attached, create a 
   property on that script with the specified name and assign it the specified int. 
   (If the property already exists, it is set -- a duplicate is not added.)
   
   We don't check the new property name against the script source, so it's possible 
   to add invalid properties with this.

   Created by DavidJCobb.
}
Unit CobbSingleSetPapyrusInt;
Uses 'Skyrim - Papyrus Resource Library';
Uses 'CobbTES5EditUtil';

Var
   gsScriptName: String;
   gsPropertyName: String;
   giValue: Integer;

Function Initialize: integer;
Var
   slResult: TStringList;
Begin
   //
   // Ask the user what to do.
   //
   slResult := PromptFor3Strings('Set Int property', 'Add property to what script?', 'Create a new int property named...', 'Enter the value of the new property.');
   If slResult.Count = 0 Then Begin
      Result := 1;
      Exit;
   End Else Begin
      gsScriptName := slResult[0];
      gsPropertyName := slResult[1];
      Try
         giValue := StrToInt(Trim(slResult[2]));
      Except
         AddMessage('The value you entered isn''t an integer.');
         Result := 1;
	 Exit;
      End;
   End;
End;

Function Process(e: IInterface) : Integer;
Begin
   If ElementType(e) = etMainRecord Then
      If ElementExists(e, 'VMAD') Then Begin
         SetIntPropertyOnScript(GetScript(e, gsScriptName), gsPropertyName, giValue);
      End;
End;

End.