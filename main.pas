unit main;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, Buttons, ExtCtrls,
  Menus, Inifiles, Spin, ComCtrls, Edit, Subrec;

type
  TForm1 = class(TForm)
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    ListBox1: TListBox;
    SaveDialog1: TSaveDialog;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    N1: TMenuItem;
    About1: TMenuItem;
    Exit1: TMenuItem;
    Renumber1: TMenuItem;
    N2: TMenuItem;
    Panel3: TPanel;
    Panel2: TPanel;
    Label1: TLabel;
    GroupBox2: TGroupBox;
    Label3: TLabel;
    Label4: TLabel;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    GroupBox1: TGroupBox;
    Label2: TLabel;
    TowardEnd: TRadioButton;
    TowardTop: TRadioButton;
    Edit2: TEdit;
    SpinH: TSpinEdit;
    SpinM: TSpinEdit;
    SpinS: TSpinEdit;
    StatusBar1: TStatusBar;
    Append1: TMenuItem;
    SpinMs: TSpinEdit;
    ProgressBar1: TProgressBar;
    Edit3: TMenuItem;
    Delete1: TMenuItem;
    Modify1: TMenuItem;
    Open1: TMenuItem;
    Save1: TMenuItem;
    Save2: TMenuItem;
    N3: TMenuItem;
    ApplyBtn: TButton;
    procedure ApplyBtnClick(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
    procedure Renumber1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SpinChange(Sender: TObject);
    procedure OnHint(sender : Tobject);
    procedure Append1Click(Sender: TObject);
    procedure Delete1Click(Sender: TObject);
    procedure Save1Click(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure Save2Click(Sender: TObject);
    procedure Panel3Resize(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
  private
    ini : Tinifile;
    Sub : TsubFile;
    { Private declarations }
    procedure LoadFile(fname : string);
    function GoToNumber(n : integer):integer;
    procedure LoadInterface;
    procedure Changed;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

procedure Tform1.Changed;
begin
  Save1.Enabled := true;
  Save2.Enabled := true;
end;

procedure TForm1.Save1Click(Sender: TObject);
begin
  SaveDialog1.FileName := label1.caption;
  if SaveDialog1.Execute then
  begin
    Label1.Caption := SaveDialog1.FileName;
    Save2Click(self);
  end;
end;

procedure TForm1.Save2Click(Sender: TObject);
begin
  if length(label1.Caption)>0 then
    Sub.SaveToFile(label1.Caption)
  else
    Save1Click(self);
end;

function TForm1.GoToNumber(n : integer):integer;
var
  i : integer;
begin
  result := -1;
  for i:=0 to listbox1.count-1 do
  begin
    if (Sub.Objects[i].index=n) then
     begin
       result:=i;
       exit;
     end;
  end;
end;

procedure Tform1.LoadInterface;
var
  j : integer;
begin
  Listbox1.clear;
  ComboBox1.Clear;
  ComboBox2.Clear;

  for j:=0 to Sub.Count-1 do
  begin
    ComboBox1.Items.Add(inttostr(Sub.Objects[j].index));
    ComboBox2.Items.Add(inttostr(Sub.Objects[j].index));
    // fill the listbox
    Listbox1.Items.Add(Sub.Objects[j].ToString);
  end;

  if(ComboBox1.Items.Count > 1) then
  begin
    ComboBox1.ItemIndex := 0;
    ComboBox2.ItemIndex := ComboBox2.Items.Count - 1;
  end;
end;

procedure TForm1.LoadFile(fname : string);
begin
  Sub.loadfromfile(fname);

  LoadInterface;
  label1.Caption := fname;
end;

procedure TForm1.Append1Click(Sender: TObject);
var
  tm : string;
begin
  if (opendialog1.Execute) then
  begin
    tm := sub.Rec[sub.lastindex].endTimeToString;
    tm := inputbox('Merge at (time:length of first part of movie) ?','Choose time :', tm);
    if tm<>'00:00:00,000' then
    begin
      sub.Merge(opendialog1.FileName, tm);
      LoadInterface;
      Changed;
    end;
  end;
end;

procedure TForm1.ApplyBtnClick(Sender: TObject);
var
  r : Trec;
  i,j : integer;
  s : string;
begin
  ProgressBar1.Visible := true;
  ProgressBar1.Min := 1;
  ProgressBar1.Max := strtoint(combobox2.Text)-strtoint(combobox1.Text);
  ProgressBar1.Position := 1;

  for i:=strtoint(combobox1.Text) to strtoint(combobox2.Text) do
  begin
    r := Sub.Rec[i];
    if (assigned(r)) then
    begin
      if TowardEnd.Checked then
        r.IncreaseTime(Edit2.Text)
      else
        r.DecreaseTime(Edit2.Text);
      //
      j:=GotoNumber(i);
      s := r.ToString;
      ListBox1.Items[j] := s;
    end;
    ProgressBar1.StepIt;
    Application.ProcessMessages;
  end;

  ProgressBar1.Visible := false;
  Changed;
end;

procedure TForm1.Delete1Click(Sender: TObject);
var
  i, ind : integer;
begin
  i := Listbox1.ItemIndex;

  ind := Sub.Objects[i].index;
  Sub.Delete(ind);
  LoadInterface;
  Changed;
end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.ListBox1DblClick(Sender: TObject);
var
  i : integer;
begin
  i := ListBox1.ItemIndex;
  if(i<0) then exit;

  with TeditFrm.Create(Application) do
  try
    Memo1.Lines.Assign(Sub.Objects[i].subs);
    if ShowModal=MrOk then
    begin
      Sub.Objects[i].subs.assign(Memo1.Lines);
      ListBox1.Items[i] := Sub.Objects[i].Tostring;
    end;
  finally
    Free;
  end;
end;

procedure TForm1.Renumber1Click(Sender: TObject);
var
  num : integer;
begin
  num := strtoint(inputbox('Renumber from ?','Choose number to renumber from :', '1'));
  if num>0 then
  begin
    Sub.Renumber(num);
    LoadInterface;
    Changed;
  end;
end;

procedure TForm1.About1Click(Sender: TObject);
begin
  MessageDlg('Simple subwork (c) Ollivier Civiol 2006', MTINFORMATION, [MBOK], 0);
end;

procedure TForm1.OnHint(sender : Tobject);
begin
  StatusBar1.SimpleText := Application.Hint;
end;

procedure TForm1.Open1Click(Sender: TObject);
begin
  if opendialog1.Execute then
  begin
    ComboBox1.Clear;
    ComboBox2.Clear;
    //
    Listbox1.Clear;
    LoadFile(OpenDialog1.FileName);
    ApplyBtn.Enabled := ListBox1.Items.count>0;
    Save1.Enabled := false;
    Save2.Enabled := false;
    //
    label1.Caption := OpenDialog1.Filename;
  end;
end;

procedure TForm1.Panel3Resize(Sender: TObject);
begin
  if Panel3.Width>Panel2.Width then
    panel2.Left := (panel3.Width-panel2.width) div 2
  else
    panel2.Left := 0;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  s : string;
begin
  Sub := TsubFile.Create;


  Application.OnHint := OnHint;
  //
  s := copy(application.exename , 1, length(application.exename)-3);
  ini := Tinifile.Create(s+'ini');
  //
  left  := ini.ReadInteger('Size', 'left' , left);
  top   := ini.ReadInteger('Size', 'top' , top);
  width := ini.ReadInteger('Size', 'width' , width);
  height:= ini.ReadInteger('Size', 'height' , height);
  //
  OpenDialog1.InitialDir := ini.ReadString('Open/Save', 'Initialdir', '');

  if ParamCount>0 then
   begin
     s := ParamStr(1);
     LoadFile(s);
   end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  ini.writeInteger('Size', 'left' , left);
  ini.writeInteger('Size', 'top' , top);
  ini.writeInteger('Size', 'width' , width);
  ini.writeInteger('Size', 'height' , height);
  //
  OpenDialog1.InitialDir := ExtractFilePath(Opendialog1.FileName);
  ini.WriteString('Open/Save', 'Initialdir', OpenDialog1.InitialDir);
  //
  ini.Free;
  sub.Free;
end;

procedure TForm1.SpinChange(Sender: TObject);
var
  h,m,s,ms : string;
begin
  h := SpinH.Text;
  m := SpinM.Text;
  s := SpinS.Text;
  ms := SpinMs.Text;
  //
  if(length(h)<2) then h := '0'+h;
  if(length(m)<2) then m := '0'+m;
  if(length(s)<2) then s := '0'+s;
  while(length(ms)<3) do ms := '0'+ms;
  //
  edit2.Text := h+':'+m+':'+s+','+ms;
end;

procedure TForm1.ListBox1Click(Sender: TObject);
begin
   if listbox1.ItemIndex >= 0 then
    combobox1.ItemIndex := listbox1.ItemIndex;
end;

end.
