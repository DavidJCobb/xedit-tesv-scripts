{
   Resource library for TES5Edit scripting.
}
Unit CobbTES5EditUtil;

{$REGION 'Delphi syntax helpers'}
{
   Copies the contents of aslB into aslA.
}
Procedure MergeTLists(aslA: TList; aslB: TList);
Var
   iIterator: Integer;
Begin
   For iIterator := 0 To aslB.Count - 1 Do Begin
      If aslA.IndexOf(aslB[iIterator]) = -1 Then aslA.Add(aslB[iIterator]);
   End;
End;
Procedure MergeTStringLists(aslA: TStringList; aslB: TStringList);
Var
   iIterator: Integer;
Begin
   For iIterator := 0 To aslB.Count - 1 Do Begin
      If aslA.IndexOf(aslB[iIterator]) = -1 Then aslA.Add(aslB[iIterator]);
   End;
End;
{$ENDREGION}

{$REGION 'General shorthands for working with files, forms, and the like.'}
{Returns a file by name (which should include the file extension).}
Function GetFileByName(asFileName: String): IInterface;
Var
   iIterator: Integer;
   eCurrentFile: IInterface;
Begin
   For iIterator := 0 To FileCount Do Begin
      eCurrentFile := FileByIndex(iIterator);
      If GetFileName(eCurrentFile) = asFileName Then Begin
         Result := eCurrentFile;
	 Exit;
      End;
   End;
End;

{Given a file, signature (e.g. NPC_), and editor ID, returns the desired Form.
This function is not performant. Cache its result whenever you can.}
Function GetRecordByEditorID(aeFile: IInterface; asSignature: String; asEditorID: String): IInterface;
Begin
   Result := MainRecordByEditorID(GroupBySignature(aeFile, asSignature), asEditorID);
End;

Function GetRecordInAnyFileByEditorID(asSignature: String; asEditorID: String): IInterface;
Var
   iIterator: Integer;
   eCurrentFile: IInterface;
Begin
   For iIterator := 0 To FileCount Do Begin
      eCurrentFile := FileByIndex(iIterator);
      Result := MainRecordByEditorID(GroupBySignature(eCurrentFile, asSignature), asEditorID);
      If Assigned(Result) Then Exit;
   End;
   Result := nil;
End;

Function GetRecordInAnyFileByFormID(aiEditorID: String): IInterface;
Var
   iIterator: Integer;
   eCurrentFile: IInterface;
Begin
   For iIterator := 0 To FileCount Do Begin
      eCurrentFile := FileByIndex(iIterator);
      Result := RecordByFormID(eCurrentFile, aiEditorID, False);
      If Assigned(Result) Then Exit;
   End;
   Result := nil;
End;

{Shorthand to create a form with a given signature and editor ID.}
Function CreateForm(aeFile: IInterface; asSignature: String; asEditorID: String): IInterface;
Begin
   Result := Add(GroupBySignature(aeFile, asSignature), asSignature, True);
   SetElementEditValues(Result, 'EDID', asEditorID);
End;
{$ENDREGION}

{$REGION 'Functions for working with generic Forms'}
Function GetFormModel(aeForm: IInterface): String;
Begin
   Result := GetElementEditValues(aeForm, 'Model\MODL');
End;

Procedure SetFormModel(aeForm: IInterface; asModelPath: String);
Begin
   Add(aeForm, 'Model', True);
   SetElementEditValues(aeForm, 'Model\MODL', asModelPath);
End;

Function GetFormName(aeForm: IInterface): String;
Begin
   Result := GetElementEditValues(aeForm, 'FULL');
End;

Procedure SetFormName(aeForm: IInterface; asName: String);
Begin
   SetElementEditValues(aeForm, 'FULL', asName);
End;
{$ENDREGION}

{$REGION 'Functions for working with Containers'}
{
   Returns the number of aeItemBase in aeContainer.
}
Function ContainerCountOfItem(aeContainer: IInterface; aeItemBase: IInterface) : Integer;
Var
   iIterator: Integer;
   eItems: IInterface;
   eItemRecord: IInterface;
   iItemRecord: Integer;
Begin
   Result := 0;
   If Not Assigned(aeContainer) Or Not Assigned(aeItemBase) Then Exit;
   If Signature(aeContainer) <> 'CONT' Then Exit;
   eItems := ElementByName(aeContainer, 'Items');
   If Not Assigned(eItems) Then Exit;
   For iIterator := 0 To ElementCount(eItems) - 1 Do Begin
      eItemRecord := ElementBySignature(ElementByIndex(eItems, iIterator), 'CNTO');
      iItemRecord := GetElementNativeValues(eItemRecord, 'Item');
      If iItemRecord = FormID(aeItemBase) Then Begin
         Result := GetElementNativeValues(eItemRecord, 'Count');
	 Exit;
      End;
   End;
End;

{
   Checks if any ObjectReferences of a given container are merchant chests.
}
Function ContainerIsMerchantChest(aeContainer: IInterface): Boolean;
Var
   iIterator: Integer;
   eReference: IInterface;
   iIterator2: Integer;
   eFaction: IInterface;
   iMerchantChest: IInterface;
Begin
   Result := False;
   For iIterator := 0 To ReferencedByCount(aeContainer) - 1 Do Begin
      eReference := ReferencedByIndex(aeContainer, iIterator);
      If Signature(eReference) <> 'REFR' Then Continue;
      If GetElementNativeValues(eReference, 'NAME') <> FOrmID(aeContainer) Then Continue;
      //
      // eReference is a placed instance (ObjectReference) of aeContainer.
      //
      For iIterator2 := 0 To ReferencedByCount(eReference) - 1 Do Begin
         eFaction := ReferencedByIndex(eReference, iIterator2);
	 If Signature(eFaction) <> 'FACT' Then Continue;
	 If ((1 Shl 14) And GetElementNativeValues(eFaction, 'DATA\Flags')) = 0 Then Continue;
	 //
	 // eFaction is a Faction with the Vendor flag set.
	 //
	 iMerchantChest := GetElementNativeValues(eFaction, 'VENC');
	 If iMerchantChest = FormID(eReference) Then Begin
	    Result := True;
	    Exit;
	 End;
      End;
   End;
End;

{
   Returns a list of all Container forms that contain this item, and all 
   Container forms that contain a LeveledItem that contains (directly or 
   indirectly) this item.
}
Function GetContainersWithItem(aeItemBase: IInterface): TList;
Var
   iIterator: Integer;
   eContainer: IInterface;
Begin
   Result := TList.Create;
   For iIterator := 0 To ReferencedByCount(aeItemBase) - 1 Do Begin
      eContainer := ReferencedByIndex(aeItemBase, iIterator);
      If Signature(eContainer) = 'LVLI' Then Begin
         MergeTLists(Result, GetContainersWithItem(eContainer));
      End;
      If Signature(eContainer) = 'CONT' Then Begin
         Result.Add(TObject(eContainer));
      End;
   End;
End;
{$ENDREGION}

{$REGION 'Functions for working with FormLists'}
Procedure FormListAddForm(aeFormList: IInterface; avForm: Variant);
Var
   iFormID: Integer;
   eLNAM: IInterface;
   eEntry: IInterface;
Begin
   Try
      iFormID := avForm;
   Except
      Try
         iFormID := StrToIntDef('$' + avForm, 0);
      Except
         iFormID := FormID(avForm);
      End;
   End;
   eLNAM := ElementBySignature(aeFormList, 'VMAD');
   If Not Assigned(eLNAM) Then eLNAM := Add(aeFormList, 'LNAM', True);
   eEntry := ElementAssign(eLNAM, HighInteger, nil, False);
   SetNativeValue(eEntry, iFormID);
End;

Function FormListIndexOf(aeFormList: IInterface; avForm: Variant): Integer;
Var
   iFormID: Integer;
   eLNAM: IInterface;
   eEntry: IInterface;
   iIterator: Integer;
Begin
   Result := -1;
   Try
      iFormID := avForm;
   Except
      Try
         iFormID := StrToIntDef('$' + avForm, 0);
      Except
         iFormID := FormID(avForm);
      End;
   End;
   eLNAM := ElementBySignature(aeFormList, 'VMAD');
   If Not Assigned(eLNAM) Then Exit;
   For iIterator := 0 To ElementCount(eLNAM) - 1 Do Begin
      eEntry := ElementByIndex(eLNAM, iIterator);
      If GetNativeValue(eEntry) = iFormID Then Begin
         Result := iIterator;
	 Exit;
      End;
   End;
End;

Procedure FormListAddFormUnique(aeFormList: IInterface; avForm: Variant);
Begin
   If FormListIndexOf(aeFormList, avForm) = -1 Then FormListAddForm(aeFormList, avForm);
End;
{$ENDREGION}

{$REGION 'Functions for working with Furniture'}
{Returns a Marker element within a Furniture's Markers collection}
Function GetFurnitureMarker(aeFurniture: IInterface; aiIndex: Integer): IInterface;
Var
   eMarkers: IInterface;
   iIterator: Integer;
   eMarker: IInterface;
Begin
   Result := nil;
   eMarkers := ElementByName(aeFurniture, 'Markers');
   For iIterator := 0 To ElementCount(eMarkers) - 1 Do Begin
      eMarker := ElementByIndex(eMarkers, iIterator);
      If GetElementNativeValues(eMarker, 'ENAM') = aiIndex Then Begin
         Result := eMarker;
	 Exit;
      End;
   End;
End;

Function GetOrMakeFurnitureMarker(aeFurniture: IInterface; aiIndex: Integer): IInterface;
Var
   eMarkers: IInterface;
   eMarker: IInterface;
Begin
   Add(aeFurniture, 'Markers', True);
   Result := GetFurnitureMarker(aeFurniture, aiIndex);
   If Assigned(Result) Then Add(Result, 'NAM0', True);
   If Not Assigned(Result) Then Begin
      //Add(aeFurniture, 'Markers', True);
      eMarkers := ElementByName(aeFurniture, 'Markers');
      eMarker := ElementAssign(eMarkers, HighInteger, nil, False);
      SetNativeValue(ElementBySignature(eMarker, 'ENAM'), aiIndex);
      Add(eMarker, 'NAM0', True);
   End;
End;

Function GetFurnitureEntryPoints(aeFurniture: IInterface; aiIndex: Integer): Integer;
Begin
   Result := GetElementNativeValues(ElementByIndex(ElementByName(aeFurniture, 'Marker Entry Points'), aiIndex), 'Entry Points');
End;

Function CountFurnitureMarkers(aeFurniture: IInterface): Integer;
Begin
   Result := ElementCount(ElementByName(aeFurniture, 'Marker Entry Points'));
End;

{
   aiEntry is a bitmask representing the entry points to disallow:
    1 Front
    2 Back
    4 Right
    8 Left
   16 Up
}
Procedure SetFurnitureBlockedEntryPoints(aeFurniture: IInterface; aiIndex: Integer; aiEntry: Integer);
Var
   eMarker: IInterface;
   eChild: IInterface;
   iSupported: Integer;
Begin
   iSupported := GetFurnitureEntryPoints(aeFurniture, aiIndex);
   eMarker := GetOrMakeFurnitureMarker(aeFurniture, aiIndex);
   eMarker := GetFurnitureMarker(aeFurniture, aiIndex); // xEdit APIs are totally broken... -_-
   SetElementNativeValues(eMarker, 'NAM0\Disabled Points', (aiEntry And iSupported));
End;

Procedure SetFurnitureMarkerState(asFurniture: IInterface; aiIndex: Integer; abState: Boolean);
var
   eMNAM: IInterface;
   iOldValue: LongWord;
   iBitValue: LongWord;
   iNewValue: LongWord;
Begin
   eMNAM := ElementBySignature(asFurniture, 'MNAM');
   iOldValue := GetNativeValue(eMNAM);
   iBitValue := 1 Shl aiIndex;
   If abState Then iNewValue := iOldValue Or iBitValue;
   If Not abState Then iNewValue := iOldValue And Not iBitValue;
   SetNativeValue(eMNAM, iNewValue);
End;
{$ENDREGION}

{$REGION 'Functions for working with Keywords'}
Function HasKeyword(aeForm: IInterface; aeKeyword: IInterface): Boolean;
Var
   eKeywords: IInterface;
   iIterator: Integer;
Begin
   Result := False;
   eKeywords := ElementBySignature(aeForm, 'KWDA');
   If Not Assigned(eKeywords) Then Exit;
   For iIterator := 0 To ElementCount(eKeywords) - 1 Do Begin
      If GetNativeValue(ElementByIndex(eKeywords, iIterator)) = FormID(aeKeyword) Then Begin
         Result := True;
	 Exit;
      End;
   End;
End;

Procedure AddKeyword(aeForm: IInterface; aeKeyword: IInterface);
Var
   eKeywords: IInterface;
   eNewKeyword: IInterface;
Begin
   If Not HasKeyword(aeForm, aeKeyword) Then Begin
      eKeywords := ElementBySignature(aeForm, 'KWDA');
      If Not Assigned(eKeywords) Then eKeywords := Add(aeForm, 'KWDA', True);
      If ElementCount(eKeywords) = 1 And GetNativeValue(ElementByIndex(eKeywords, 0)) = 0 Then Begin
         //
         // If the CK wrote a null KWDA record, reuse it.
         //
         SetNativeValue(ElementByIndex(eKeywords, 0), FormID(aeKeyword));
      End Else Begin
         //
         // Otherwise, add a new keyword.
         //
         eNewKeyword := ElementAssign(eKeywords, HighInteger, nil, False);
	 If Not Assigned(eNewKeyword) Then Exit; // Can't add keyword to this record.
	 SetNativeValue(eNewKeyword, FormID(aeKeyword));
      End;
      //
      // Update keyword count value.
      //
      If Not ElementExists(aeForm, 'KSIZ') Then Add(aeForm, 'KSIZ', True);
      SetElementNativeValues(aeForm, 'KSIZ', ElementCount(eKeywords));
   End;
End;
{$ENDREGION}

{$REGION 'UI utility helpers'}
{
   Helper method: given a UI control and a string, finds any descendant 
   control whose Name is equal to the string.
}
Function FindControlByName(auiBase: TObject; asName: String) : TObject;
Var
   iIterator: Integer;
   sTemporary: String;
Begin
   Result := nil;
   For iIterator := 0 To auiBase.ComponentCount - 1 Do Begin
      Try
         sTemporary := auiBase.Components[iIterator].Name;
	 If sTemporary = asName Then Begin
	    Result := auiBase.Components[iIterator];
	    Exit;
	 End;
      Finally
      End;
   End;
   For iIterator := 0 To auiBase.ControlCount - 1 Do Begin
      Try
         sTemporary := auiBase.Controls[iIterator].Name;
	 If sTemporary = asName Then Begin
	    Result := auiBase.Controls[iIterator];
	    Exit;
	 End;
      Finally
      End;
   End;
   If Result = nil Then AddMessage('Failed to find UI control named ' + asName);
End;
{$ENDREGION}

{
   A rewrite of the native InputQuery that actually accommodates long prompt strings.
}
{$REGION 'PromptForString(asTitle, asLabel, out asValue) // a more robust InputQuery'}
Function PromptForString(asTitle: String; asLabel: String; var asValue: String): Boolean;
Var
   uiDialog: TForm;
   uiDialogContent: TObject;
   uiDialogContentPanel: TPanel;
   iDialogHeight: Integer;
   iDialogPaddingX: Integer;
   iDialogPaddingY: Integer;
   uiLabel: TLabel;
   uiInput: TEdit;
   uiButtonOkay: TButton;
   uiButtonCancel: TButton;
   iButtonWidth: Integer;
   iMaxWidth: Integer;
   iTemporary: Integer;
Begin
   iDialogPaddingX := 16;
   iDialogPaddingY :=  8;
   uiDialog := TForm.Create(nil);
   Result := False;
   Try
      uiDialog.Caption := asTitle;
      uiDialog.Position := poScreenCenter;
      uiDialogContentPanel := TPanel.Create(uiDialog);
      uiDialogContentPanel.Parent := uiDialog;
      uiDialogContentPanel.BevelOuter := bvNone;
      uiDialogContentPanel.Align := alTop;
      uiDialogContentPanel.Alignment := taLeftJustify;
      uiDialogContentPanel.Height := 400;
      //
      uiLabel := TLabel.Create(uiDialog);
      uiLabel.Parent := uiDialogContentPanel;
      uiLabel.Left := iDialogPaddingX;
      uiLabel.Top := iDialogPaddingY;
      uiLabel.WordWrap := True;
      uiLabel.Constraints.MinWidth := 250;
      uiLabel.Constraints.MaxWidth := 600;
      uiLabel.Constraints.MaxHeight := 9000;
      uiLabel.Caption := asLabel;
      //
      uiInput := TEdit.Create(uiDialog);
      uiInput.Parent := uiDialogContentPanel;
      uiInput.Left := iDialogPaddingX;
      uiInput.Top := uiLabel.Top + uiLabel.Height + iDialogPaddingY;
      uiInput.Text := '';
      //
      uiButtonOkay := TButton.Create(uiDialog);
      uiButtonOkay.Parent := uiDialogContentPanel;
      uiButtonOkay.Caption := 'OK';
      uiButtonOkay.Default := True;
      uiButtonOkay.ModalResult := mrOk;
      uiButtonOkay.Top := uiInput.Top + uiInput.Height + iDialogPaddingY;
      uiButtonCancel := TButton.Create(uiDialog);
      uiButtonCancel.Parent := uiDialogContentPanel;
      uiButtonCancel.Caption := 'Cancel';
      uiButtonCancel.ModalResult := mrCancel;
      uiButtonCancel.Top := uiButtonOkay.Top;
      //
      // Finalize container dimensions, and center the buttons.
      //
      uiDialogContentPanel.Height := uiButtonCancel.Top + uiButtonCancel.Height + iDialogPaddingY;
      uiDialog.ClientHeight := uiDialogContentPanel.Height;
      iButtonWidth := uiButtonOkay.Width + iDialogPaddingX + uiButtonCancel.Width;
      iMaxWidth := Max(uiLabel.Width, uiInput.Width);
      uiLabel.Width := iMaxWidth;
      uiInput.Width := iMaxWidth;
      uiButtonOkay.Left := (iMaxWidth - iButtonWidth) / 2 + iDialogPaddingX;
      uiButtonCancel.Left := uiButtonOkay.Left + uiButtonOkay.Width + iDialogPaddingX;
      uiDialog.ClientWidth := iMaxWidth + (iDialogPaddingX * 2);
      uiDialogContentPanel.Width := uiDialog.ClientWidth;
      //
      // Show the dialog and act on the result.
      //
      If uiDialog.ShowModal = mrOk Then Begin
	 asValue := uiInput.Text;
         Result := True;
      End;
   Finally
      uiDialog.Free;
   End;
End;
{$ENDREGION}

{
   Prompt for two strings using a dialog box; you can specify labels for each 
   string.
}
{$REGION 'PromptFor2Strings(asTitle, asLabel1, asLabel2)'}
Function PromptFor2Strings(asTitle: String; asLabel1: String; asLabel2: String): TStringList;
Var
   slLabels: TStringList;
Begin

   slLabels := TStringList.Create;
   slLabels.Add(asLabel1);
   slLabels.Add(asLabel2);
   Result := PromptForStrings(asTitle, slLabels);
End;
{$ENDREGION}

{
   Prompt for three strings using a dialog box; you can specify labels for each 
   string.
}
{$REGION 'PromptFor3Strings(asTitle, asLabel1, asLabel2, asLabel3)'}
Function PromptFor3Strings(asTitle: String; asLabel1: String; asLabel2: String; asLabel3: String): TStringList;
Var
   slLabels: TStringList;
Begin

   slLabels := TStringList.Create;
   slLabels.Add(asLabel1);
   slLabels.Add(asLabel2);
   slLabels.Add(asLabel3);
   Result := PromptForStrings(asTitle, slLabels);
End;
{$ENDREGION}

{
   Prompt for up to ten strings using a dialog box; you can specify labels for 
   each string.
}
{$REGION 'PromptForStrings(asTitle, aslLabels)'}
Function PromptForStrings(asTitle: String; aslLabels: TStringList): TStringList;
Var
   iStringCount: Integer;
   uiDialog: TForm;
   uiDialogContent: TObject;
   uiDialogContentPanel: TPanel;
   iDialogHeight: Integer;
   iDialogPaddingX: Integer;
   iDialogPaddingY: Integer;
   sLabels: Array[0..9] of String;
   iCurrentY: Integer;
   uiLabels: Array[0..9] of TLabel;
   uiInputs: Array[0..9] of TEdit;
   iLabelWidth: Integer;
   iInputWidth: Integer;
   uiButtonOkay: TButton;
   uiButtonCancel: TButton;
   iButtonWidth: Integer;
   iMaxWidth: Integer;
   iIterator: Integer;
Begin
   iStringCount := Min(aslLabels.Count - 1, 9);
   iDialogPaddingX := 16;
   iDialogPaddingY :=  8;
   Result := TStringList.Create;
   uiDialog := TForm.Create(nil);
   Try
      uiDialog.Caption := asTitle;
      uiDialog.Position := poScreenCenter;
      uiDialogContentPanel := TPanel.Create(uiDialog);
      uiDialogContentPanel.Parent := uiDialog;
      uiDialogContentPanel.BevelOuter := bvNone;
      uiDialogContentPanel.Align := alTop;
      uiDialogContentPanel.Alignment := taLeftJustify;
      uiDialogContentPanel.Height := 400;
      //
      iCurrentY := iDialogPaddingY;
      For iIterator := 0 To iStringCount Do Begin
         uiLabels[iIterator] := TLabel.Create(uiDialog);
         uiLabels[iIterator].Parent := uiDialogContentPanel;
         uiLabels[iIterator].Left := iDialogPaddingX;
         uiLabels[iIterator].Top := iCurrentY;
         uiLabels[iIterator].WordWrap := True;
         uiLabels[iIterator].Constraints.MinWidth := 250;
         uiLabels[iIterator].Constraints.MaxWidth := 600;
         uiLabels[iIterator].Constraints.MaxHeight := 9000;
         uiLabels[iIterator].Caption := aslLabels[iIterator];
	 //
         uiInputs[iIterator] := TEdit.Create(uiDialog);
         uiInputs[iIterator].Parent := uiDialogContentPanel;
         uiInputs[iIterator].Left := iDialogPaddingX;
         uiInputs[iIterator].Top := uiLabels[iIterator].Top + uiLabels[iIterator].Height + iDialogPaddingY;
         uiInputs[iIterator].Text := '';
	 //
	 iCurrentY := uiInputs[iIterator].Top + uiInputs[iIterator].Height + iDialogPaddingY;
      End;
      //
      uiButtonOkay := TButton.Create(uiDialog);
      uiButtonOkay.Parent := uiDialogContentPanel;
      uiButtonOkay.Caption := 'OK';
      uiButtonOkay.Default := True;
      uiButtonOkay.ModalResult := mrOk;
      uiButtonOkay.Top := uiInputs[iStringCount].Top + uiInputs[iStringCount].Height + iDialogPaddingY;
      uiButtonCancel := TButton.Create(uiDialog);
      uiButtonCancel.Parent := uiDialogContentPanel;
      uiButtonCancel.Caption := 'Cancel';
      uiButtonCancel.ModalResult := mrCancel;
      uiButtonCancel.Top := uiButtonOkay.Top;
      //
      // Finalize container dimensions, and center the buttons.
      //
      iLabelWidth := 0;
      iInputWidth := 0;
      For iIterator := 0 To iStringCount Do Begin
         iLabelWidth := Max(iLabelWidth, uiLabels[iIterator].Width);
         iInputWidth := Max(iInputWidth, uiInputs[iIterator].Width);
      End;
      uiDialogContentPanel.Height := uiButtonCancel.Top + uiButtonCancel.Height + iDialogPaddingY;
      uiDialog.ClientHeight := uiDialogContentPanel.Height;
      iButtonWidth := uiButtonOkay.Width + iDialogPaddingX + uiButtonCancel.Width;
      iMaxWidth := Max(Max(iLabelWidth, iInputWidth), iButtonWidth);
      For iIterator := 0 To iStringCount Do Begin
         uiLabels[iIterator].Width := iMaxWidth;
         uiInputs[iIterator].Width := iMaxWidth;
      End;
      uiButtonOkay.Left := (iMaxWidth - iButtonWidth) / 2 + iDialogPaddingX;
      uiButtonCancel.Left := uiButtonOkay.Left + uiButtonOkay.Width + iDialogPaddingX;
      uiDialog.ClientWidth := iMaxWidth + (iDialogPaddingX * 2);
      uiDialogContentPanel.Width := uiDialog.ClientWidth;
      //
      // Show the dialog and act on the result.
      //
      If uiDialog.ShowModal = mrOk Then Begin
         For iIterator := 0 To iStringCount Do Result.Add(uiInputs[iIterator].Text);
      End;
   Finally
      uiDialog.Free;
   End;
End;
{$ENDREGION}

{$REGION 'PromptForEnum(asTitle, asLabel, aslOptions, out aiValue)'}
Function PromptForEnum(asTitle: String; asLabel: String; aslOptions: TStringList; var aiValue: Integer): Boolean;
Var
   uiDialog: TForm;
   uiDialogContent: TObject;
   uiDialogContentPanel: TPanel;
   iDialogHeight: Integer;
   iDialogPaddingX: Integer;
   iDialogPaddingY: Integer;
   uiLabel: TLabel;
   uiInput: TComboBox;
   uiButtonOkay: TButton;
   uiButtonCancel: TButton;
   iButtonWidth: Integer;
   iMaxWidth: Integer;
   iTemporary: Integer;
Begin
   iDialogPaddingX := 16;
   iDialogPaddingY :=  8;
   uiDialog := TForm.Create(nil);
   Result := False;
   Try
      uiDialog.Caption := asTitle;
      uiDialog.Position := poScreenCenter;
      uiDialogContentPanel := TPanel.Create(uiDialog);
      uiDialogContentPanel.Parent := uiDialog;
      uiDialogContentPanel.BevelOuter := bvNone;
      uiDialogContentPanel.Align := alTop;
      uiDialogContentPanel.Alignment := taLeftJustify;
      uiDialogContentPanel.Height := 400;
      //
      uiLabel := TLabel.Create(uiDialog);
      uiLabel.Parent := uiDialogContentPanel;
      uiLabel.Left := iDialogPaddingX;
      uiLabel.Top := iDialogPaddingY;
      uiLabel.WordWrap := True;
      uiLabel.Constraints.MinWidth := 250;
      uiLabel.Constraints.MaxWidth := 600;
      uiLabel.Constraints.MaxHeight := 9000;
      uiLabel.Caption := asLabel;
      //
      uiInput := TComboBox.Create(uiDialog);
      uiInput.Parent := uiDialogContentPanel;
      uiInput.Style := csDropDownList;
      uiInput.Left := iDialogPaddingX;
      uiInput.Top := uiLabel.Top + uiLabel.Height + iDialogPaddingY;
      uiInput.Items.Clear;
      For iTemporary := 0 To aslOptions.Count - 1 Do Begin
         uiInput.Items.Add(aslOptions[iTemporary]);
      End;
      uiInput.ItemIndex := 0;
      //
      uiButtonOkay := TButton.Create(uiDialog);
      uiButtonOkay.Parent := uiDialogContentPanel;
      uiButtonOkay.Caption := 'OK';
      uiButtonOkay.Default := True;
      uiButtonOkay.ModalResult := mrOk;
      uiButtonOkay.Top := uiInput.Top + uiInput.Height + iDialogPaddingY;
      uiButtonCancel := TButton.Create(uiDialog);
      uiButtonCancel.Parent := uiDialogContentPanel;
      uiButtonCancel.Caption := 'Cancel';
      uiButtonCancel.ModalResult := mrCancel;
      uiButtonCancel.Top := uiButtonOkay.Top;
      //
      // Finalize container dimensions, and center the buttons.
      //
      uiDialogContentPanel.Height := uiButtonCancel.Top + uiButtonCancel.Height + iDialogPaddingY;
      uiDialog.ClientHeight := uiDialogContentPanel.Height;
      iButtonWidth := uiButtonOkay.Width + iDialogPaddingX + uiButtonCancel.Width;
      iMaxWidth := Max(uiLabel.Width, uiInput.Width);
      uiLabel.Width := iMaxWidth;
      uiInput.Width := iMaxWidth;
      uiButtonOkay.Left := (iMaxWidth - iButtonWidth) / 2 + iDialogPaddingX;
      uiButtonCancel.Left := uiButtonOkay.Left + uiButtonOkay.Width + iDialogPaddingX;
      uiDialog.ClientWidth := iMaxWidth + (iDialogPaddingX * 2);
      uiDialogContentPanel.Width := uiDialog.ClientWidth;
      //
      // Show the dialog and act on the result.
      //
      If uiDialog.ShowModal = mrOk Then Begin
	 aiValue := uiInput.ItemIndex;
         Result := True;
      End;
   Finally
      uiDialog.Free;
   End;
End;
{$ENDREGION}

{
   Shows a Yes/No box with the specified labels, and returns a boolean indicating 
   how the user closed the box.
}
{$REGION 'UIConfirm(asTitle, asText, asYes, asNo)'}
Function UIConfirm(asTitle: String; asText: String; asYes: String = 'Yes'; asNo: String = 'No'): Boolean;
Var
   uiDialog: TForm;
   uiContainer: TPanel;
   uiLabel: TLabel;
   uiButtonYes: TButton;
   uiButtonNo: TButton;
   iDialogPaddingX: Integer;
   iDialogPaddingY: Integer;
   iButtonWidth: Integer;
   iMaxWidth: Integer;
Begin
   iDialogPaddingX := 16;
   iDialogPaddingY := 8;
   Result := False;
   uiDialog := TForm.Create(nil);
   Try
      uiDialog.Caption := asTitle;
      uiDialog.Position := poScreenCenter;
      uiContainer := TPanel.Create(uiDialog);
      uiContainer.Parent := uiDialog;
      uiContainer.BevelOuter := bvNone;
      uiContainer.Align := alTop;
      uiContainer.Alignment := taLeftJustify;
      uiContainer.Height := 400;
      uiLabel := TLabel.Create(uiDialog);
      uiLabel.Parent := uiContainer;
      uiLabel.Left := iDialogPaddingX;
      uiLabel.Top := iDialogPaddingY;
      uiLabel.Caption := asText;
      uiButtonYes := TButton.Create(uiDialog);
      uiButtonYes.Parent := uiContainer;
      uiButtonYes.Caption := asYes;
      uiButtonYes.ModalResult := mrOk;
      uiButtonNo := TButton.Create(uiDialog);
      uiButtonNo.Parent := uiContainer;
      uiButtonNo.Caption := asNo;
      uiButtonNo.ModalResult := mrCancel;
      //
      // Finalize dimensions.
      //
      uiButtonYes.Top := uiLabel.Top + uiLabel.Height + iDialogPaddingY;
      uiButtonNo.Top := uiButtonYes.Top;
      //
      iButtonWidth := uiButtonYes.Width + 16 + uiButtonNo.Width;
      iMaxWidth := Max(uiLabel.Width, iButtonWidth);
      uiDialog.ClientWidth := iMaxWidth + iDialogPaddingX * 2;
      uiContainer.Height := uiButtonYes.Top + uiButtonYes.Height + iDialogPaddingY;
      uiDialog.ClientHeight := uiContainer.Height;
      uiButtonYes.Left := (iMaxWidth - iButtonWidth) / 2 + iDialogPaddingX;
      uiButtonNo.Left := uiButtonYes.Left + uiButtonYes.Width + 16;
      //
      // Show the dialog and act on the result.
      //
      Result := False;
      If uiDialog.ShowModal = mrOk Then Result := True;
   Finally
      uiDialog.Free;
   End;
End;
{$ENDREGION}

End.