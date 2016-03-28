{
   For each selected object that has the specified Papyrus script attached, create a 
   property on that script with the specified name and assign it the specified float 
   array. (If the property already exists, it is set -- a duplicate is not added.)
   
   We don't check the new property name against the script source, so it's possible 
   to add invalid properties with this.

   Created by DavidJCobb.
}
Unit CobbSingleSetPapyrusFloatArray;
Uses 'Skyrim - Papyrus Resource Library';
Uses 'CobbTES5EditUtil';

var
   sScriptTarget: String;
   sNewPropertyName: String;
   slNewPropertyValues: TStringList;

Function Initialize: integer;
Var
   sNewPropertyValue: String;
   slResult: TStringList;
Begin
   //
   // Ask the user what to do.
   //
   slResult := PromptFor3Strings('Set Float[] property', 'Add property to what script?', 'Create a new float array property named...', 'Enter the value of the new property as a list of comma-separated floats. No spaces, please.');
   If slResult.Count = 0 Then Begin
      Result := 1;
      Exit;
   End Else Begin
      sScriptTarget := slResult[0];
      sNewPropertyName := slResult[1];
      sNewPropertyValue := slResult[2];
   End;
   slNewPropertyValues := TStringList.Create;
   slNewPropertyValues.Delimiter := ',';
   slNewPropertyValues.StrictDelimiter := True;
   slNewPropertyValues.DelimitedText := sNewPropertyValue;
End;

Function Process(e: IInterface) : Integer;
Begin
   If ElementType(e) = etMainRecord Then
      If ElementExists(e, 'VMAD') Then
         SetFloatArrayPropertyOnScript(GetScript(e, sScriptTarget), sNewPropertyName, slNewPropertyValues);
End;

End.