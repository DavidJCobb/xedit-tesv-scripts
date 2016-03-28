{
   For each selected object that has the specified Papyrus script attached, create a 
   property on that script with the specified name and assign it the specified Form 
   ID. (If the property already exists, it is set -- a duplicate is not added.)
   
   We do not validate the specified Form ID. We also don't check the new property name 
   against the script source, so it's possible to add invalid properties with this.

   Created by DavidJCobb.
}
Unit CobbSingleSetPapyrusForm;
Uses 'Skyrim - Papyrus Resource Library';
Uses 'CobbTES5EditUtil';

Var
   greSignatureAndID: TPerlRegEx;
   sScriptTarget: String;
   sNewPropertyName: String;
   iFormID: Integer;

Function Initialize: integer;
Var
   slResult: TStringList;
   eValue: IInterface;
   eFile: IInterface;
Begin
   greSignatureAndID := TPerlRegEx.Create;
   greSignatureAndID.Options := [preSingleLine];
   greSignatureAndID.RegEx := '^(\w\w\w\w) (\S+)$';
   greSignatureAndID.Study;
   //
   // Ask the user what to do.
   //
   slResult := PromptFor3Strings('Set Form property', 'Add property to what script?', 'Create a new object property named...', 'Enter the value of the new property as a Form ID, or as a signature, space, and Editor ID.');
   If slResult.Count = 0 Then Begin
      Result := 1;
      Exit;
   End Else Begin
      sScriptTarget := slResult[0];
      sNewPropertyName := slResult[1];
      Try
         iFormID := StrToInt('$' + slResult[2]);
      Except
         greSignatureAndID.Subject := slResult[2];
         greSignatureAndID.Start := 0;
	 If greSignatureAndID.MatchAgain Then Begin
	    eValue := GetRecordInAnyFileByEditorID(greSignatureAndID.Groups[1], greSignatureAndID.Groups[2]);
	    If Assigned(eValue) Then iFormID := FormID(eValue) Else Begin
	       AddMessage('The specified form does not exist.');
	       Result := 1;
	       Exit;
	    End;
	 End Else Begin
	    AddMessage('The specified value couldn''t be deciphered. Remember: if you''re specifying an Editor ID, you must prefix it with the signature (e.g. CONT) and a space.');
	    Result := 1;
	    Exit;
	 End;
      End;
   End;
End;

Function Process(e: IInterface) : Integer;
Begin
   If ElementType(e) = etMainRecord Then
      If ElementExists(e, 'VMAD') Then Begin
         SetFormPropertyOnScript(GetScript(e, sScriptTarget), sNewPropertyName, iFormID);
      End;
End;

End.