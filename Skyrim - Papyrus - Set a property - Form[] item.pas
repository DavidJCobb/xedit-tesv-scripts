{
   Set one item in a Papyrus Form[] property.
}
Unit CobbSingleSetPapyrusForm;
Uses 'Skyrim - Papyrus Resource Library';
Uses 'CobbTES5EditUtil';

Var
   greSignatureAndID: TPerlRegEx;
   sScriptTarget: String;
   sNewPropertyName: String;
   iPropertyIndex: Integer;
   iFormID: Integer;

Function Initialize: integer;
Var
   slLabels: TStringList;
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
   slLabels := TStringList.Create;
   slLabels.Add('Add property to what script?');
   slLabels.Add('Form[] property name?');
   slLabels.Add('Index in the array?');
   slLabels.Add('Enter the value of the new property as a Form ID, or as a signature, space, and Editor ID.');
   slResult := PromptForStrings('Set Form property', slLabels);
   If slResult.Count = 0 Then Begin
      Result := 1;
      Exit;
   End Else Begin
      sScriptTarget := slResult[0];
      sNewPropertyName := slResult[1];
      iPropertyIndex := StrToInt(Trim(slResult[2]));
      Try
         iFormID := StrToInt('$' + slResult[3]);
      Except
         greSignatureAndID.Subject := slResult[3];
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
         SetFormArrayPropertyItemOnScript(GetScript(e, sScriptTarget), sNewPropertyName, iPropertyIndex, iFormID);
      End;
End;

End.