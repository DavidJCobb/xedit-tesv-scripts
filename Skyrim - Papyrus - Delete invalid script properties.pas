{
   Finds and deletes invalid Papyrus properties defined on any of the selected 
   objects' attached scripts.
   
   Only deletes up to 512 invalid properties per run. If you have more than that 
   many invalid properties on a given script instance, then what the actual hell 
   are you doing, dude?
   
   Created by DavidJCobb.
}
unit CobbUnitDeleteInvalidPapyrusProperties;

var
   rePropRegex: TPerlRegEx;

Function Initialize: integer;
Begin
   rePropRegex := TPerlRegEx.Create;
   rePropRegex.Options := [preCaseLess, preMultiLine, preSingleLine];
   rePropRegex.RegEx := '^[\w\[\]]+\s+Property\s+(\w+)(.*?)$';
   rePropRegex.Study;
End;

Function ReadPropertiesFromScriptFile(aScriptName: String) : TStringList;
Var
   slProperties: TStringList;
   s: String;
Begin
   slProperties := TStringList.Create;
   Try
      slProperties.Clear;
      slProperties.LoadFromFile(DataPath + 'Scripts\Source\' + aScriptName + '.psc');
   Except End;
   rePropRegex.Subject := slProperties.Text;
   slProperties.Clear;
   While rePropRegex.MatchAgain Do Begin
      s := Trim(rePropRegex.Groups[2]);
      If s = '' Then Continue; // Property has [gs]etters.
      //If s[1] = '=' Then Continue; // Property has value.
      slProperties.Add(rePropRegex.Groups[1]);
   End;
   Result := slProperties
End;

Procedure ScanVMAD(e: IInterface);
Var
   sElemName: String;
   eVMAD: IInterface;
   eScripts: IInterface;
   iCurrentScript: Integer;
   eCurrentScript: IInterface;
   sCurrentScript: String;
   slPropertiesFromFile: TStringList;
   eProperties: IInterface;
   elPropertiesToKill: Array[0..512] of IInterface;
   iPropertiesToKillCount: Integer;
   iCurrentProperty: Integer;
   eCurrentProperty: IInterface;
   sCurrentProperty: String;
   iTemporary: Integer;
   sTemporary: String; // DEBUG
Begin
   sElemName := Name(e);
   eVMAD := ElementBySignature(e, 'VMAD');
   eScripts := ElementByPath(eVMAD, 'Data\Scripts');
   If Assigned(eScripts) = False Then Begin
      eScripts := ElementByPath(eVMAD, 'Data\Quest VMAD\Scripts');
   End;
   //AddMessage(Format('DEBUG: Scanning %s.', [sElemName]));
   For iCurrentScript := 0 To ElementCount(eScripts) - 1 Do Begin
      eCurrentScript := ElementByIndex(eScripts, iCurrentScript);
      //AddMessage('DEBUG: Found script node.');
      If Name(eCurrentScript) = 'Script' Then Begin
         //AddMessage(Format('DEBUG: Found script on %s.', [sElemName]));
         //
	 // Processing a single script...
	 //
	 sCurrentScript := GetEditValue(ElementByName(eCurrentScript, 'scriptName'));
	 //
	 // Read the script file and find its properties.
	 //
	 slPropertiesFromFile := ReadPropertiesFromScriptFile(sCurrentScript);
	 //
	 // Now, let's compare it against the properties that are actually defined on this object.
	 //
         eProperties := ElementByName(eCurrentScript, 'Properties');
	 iPropertiesToKillCount := 0;
	 For iCurrentProperty := 0 To ElementCount(eProperties) - 1 Do Begin
	    eCurrentProperty := ElementByIndex(eProperties, iCurrentProperty);
	    If Name(eCurrentProperty) = 'Property' Then Begin
	       sCurrentProperty := GetEditValue(ElementByName(eCurrentProperty, 'propertyName'));
	       If sCurrentProperty <> '' Then Begin
	          iTemporary := slPropertiesFromFile.IndexOf(sCurrentProperty);
	       End Else Begin
	          iTemporary := -1;
	       End;
	       If iTemporary = -1 Then Begin
	          //
		  // This property is invalid. We'll store its path so we can remove it 
		  // once we're out of the loop. (If we remove it in the loop, we'll end 
		  // up skipping elements -- and no, we can't update the iterator variable, 
		  // because online docs say that Pascal craps its pants when you do that.)
		  // 
		  AddMessage(Format('%s \ %s \ %s property IS INVALID and will be removed.', [sElemName, sCurrentScript, sCurrentProperty]));
		  If iPropertiesToKillCount < 512 Then Begin
		     elPropertiesToKill[iPropertiesToKillCount] := eCurrentProperty;
		     iPropertiesToKillCount := iPropertiesToKillCount + 1;
		  End;
	       End Else Begin
	          //
		  // FOR TESTING ONLY.
		  //
	          //AddMessage(Format('%s \ %s \ %s property is valid.', [sElemName, sCurrentScript, sCurrentProperty]))
	       End;
	    End;
	 End;
	 For iCurrentProperty := 0 To iPropertiesToKillCount - 1 Do Begin
	    Remove(elPropertiesToKill[iCurrentProperty]);
	 End;
	 //
	 // Done processing a single script.
	 //
      End;
   End;
End;

Function Process(e: IInterface) : Integer;
Begin
   If ElementType(e) = etMainRecord Then
      If ElementExists(e, 'VMAD') Then Begin
         ScanVMAD(e);
      End;
End;

End.