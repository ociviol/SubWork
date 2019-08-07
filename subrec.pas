unit subrec;

{$MODE Delphi}

interface

uses LCLIntf, LCLType, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, Buttons, ExtCtrls,
  Menus;

type
  Trec = class(TObject)
  private
     s_hour, s_minute, s_second, s_msecond,
     e_hour, e_minute, e_second, e_msecond : integer;
  protected
    Findex : Integer;
    Fsubs  : Tstringlist;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure SubTimeStringToRec(tml : string);
    function  debTimeToString:string;
    function  ToString:string; reintroduce;
    function  endTimeToString:string;
    procedure IncreaseTime(decal : string);
    procedure DecreaseTime(decal : string);
    property  Index : integer read FIndex;
    property  Subs : TStringlist read FSubs;
  end;

  TsubFile = Class(TObject)
  private
    sublist : tstringlist;
    changed : boolean;
    function  GetObject(i:integer):Trec;
    function  GetCount:integer;
    function  GetRecPos(ind : integer):integer;
    function  GetRec(ind : integer):Trec;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Delete(ind : integer);
    procedure Renumber(ind : integer);
    function  LastIndex:integer;
    procedure Merge(fname, tm : string);
    function  LoadFromFile(fname : string):boolean;
    procedure SaveToFile(fname : string);
    procedure Clear;
    property  Count : integer read GetCount;
    property  Objects[Index: Integer]: Trec read GetObject;
    property  Rec[Index: Integer]: Trec read GetRec;
  End;

procedure ConvtTime(tm : string;var h,m,s,ms : integer);
function inttostr2(i, len : integer):string;

implementation

procedure ConvtTime(tm : string;var h,m,s,ms : integer);
begin
  try
    h:=strtoint(copy(tm,1,2));
  except
    h:=0;
  end;
  try
    m:=strtoint(copy(tm,4,2));
  except
    m:=0;
  end;
  try
    s:=strtoint(copy(tm,7,2));
  except
    s:=0;
  end;
  try
    ms:=strtoint(copy(tm,10,3));
  except
    ms:=0;
  end;
end;

function inttostr2(i, len : integer):string;
begin
  result:=inttostr(i);
  while(length(result)<len) do result:='0'+result;
end;

procedure Tsubfile.Merge(fname, tm : string);
var
  s : TsubFile;
  i : integer;
begin
  s := tsubfile.Create;
  s.LoadFromFile(fname);
  s.renumber(lastindex+1);
  //  merge
  for i:=0 to s.Count-1 do
  begin
    s.Objects[i].IncreaseTime(tm);
    sublist.AddObject(s.Objects[i].ToString, Tobject(s.Objects[i]));
  end;
  // prevent destroying of records
  s.sublist.Clear;
  s.Free;
end;

function TsubFile.LastIndex:integer;
var
  i : integer;
begin
  result := 0;
  for i := 0 to sublist.Count - 1 do
    if Trec(sublist.objects[i]).index > result then
      result := Trec(sublist.objects[i]).index;
end;

procedure TsubFile.Delete(ind : integer);
var
  r : Trec;
  i : integer;
begin
  r := GetRec(ind);
  i := GetRecPos(ind);
  r.Free;
  sublist.Delete(i);
end;

procedure TsubFile.Renumber(ind : integer);
var
  i : integer;
begin
  for i:=0 to sublist.count-1 do
  begin
    Objects[i].Findex := ind;
    inc(ind);
  end;
end;

function TsubFile.GetRecPos(ind : integer):integer;
var
  i : integer;
begin
  for i := 0 to sublist.Count - 1 do
    if Trec(sublist.Objects[i]).index = ind then
    begin
      result := i;
      exit;
    end;
  result:=-1;
end;

function TsubFile.GetRec(ind : integer):Trec;
var
  i : integer;
begin
  for i := 0 to sublist.Count - 1 do
    if Trec(sublist.Objects[i]).index = ind then
    begin
      result := Trec(sublist.Objects[i]);
      exit;
    end;
  result:=nil;
end;

function TsubFile.GetCount:integer;
begin
  result := sublist.count;
end;

procedure TsubFile.AfterConstruction;
begin
  inherited;
  sublist := tstringlist.Create;
end;

procedure TsubFile.BeforeDestruction;
begin
  Clear;
  sublist.free;
  inherited;
end;

procedure TsubFile.Clear;
var
  i : integer;
begin
  for i:=0 to sublist.count-1 do
    if assigned(sublist.Objects[i]) then
      Objects[i].Free;
end;

function TsubFile.GetObject(i:integer):Trec;
begin
  result:=Trec(SubList.objects[i]);
end;

procedure TsubFile.SaveToFile(fname : string);
var
  tmp : Tstringlist;
  i : integer;
  s : string;
  r : Trec;
  j: Integer;
begin
  tmp := Tstringlist.Create;
  for i:=0 to sublist.Count -1 do
  begin
    r := GetObject(i);
    // index
    s := inttostr(r.index);
    tmp.Add(s);
    // time
    s := r.debTimeToString + ' --> ' + r.endTimeToString;
    tmp.Add(s);
    // subs
    for j := 0 to r.subs.count - 1 do
    begin
      s := r.subs[j];
      if s<>'' then tmp.Add(s);
    end;
    // end line
    tmp.Add('');
  end;
  tmp.SaveToFile(fname);
  tmp.Free;
end;

{
 function IsUtf8Encoded(const s: AnsiString): boolean;
 begin
   Result := (s <> '') and (UTF8Decode(S) <> '');
 end;

 procedure DecodeFile;
 begin

 end;
}

function TsubFile.LoadFromFile(fname : string):boolean;
var
  tmp : Tstringlist;
  r : Trec;
  j,pos : integer;
begin
  tmp := Tstringlist.Create;
  tmp.loadfromfile(fname);
//  if IsUtf8Encoded(tmp[0]) then
//    DecodeFile;
  // backup
  tmp.SaveToFile(fname + '.bak');
  //
  sublist.Clear;

  j:=0;
  pos:=strtoint(tmp[j]);
  if(pos<>1) then
    MessageDlg('File does not start at ''1'' you should renumber !',
                mtinformation, [mbok], 0);

  try
    repeat
      if tmp[j]<>'' then
      begin
        r := Trec.Create;
        // sub index
        r.Findex := strtoint(tmp[j]);

        // sub time
        inc(j);
        r.SubTimeStringToRec(tmp[j]);
        // sub text
        repeat
          inc(j);
          r.subs.Add(tmp[j]);
        until ((length(tmp[j])=0) or (j>=tmp.count-1));
        // save object
        sublist.AddObject(r.Tostring, Tobject(r));
        //
      end;
      inc(j);
    until (j>=tmp.Count-1);
  finally
    tmp.Free;
    result:=true;
  end;
end;

// Trec implementation

procedure Trec.AfterConstruction;
begin
  inherited;
  Fsubs := Tstringlist.Create;
end;

procedure Trec.BeforeDestruction;
begin
  subs.Free;
  inherited;
end;

procedure Trec.IncreaseTime(decal : string);
var
  hd,md,sd,msd : integer;
begin
  ConvtTime(decal, hd, md, sd, msd);
  // milliseconds
  inc(s_msecond, msd);
  while (s_msecond>=1000) do begin inc(s_second);dec(s_msecond, 1000); end;
  // seconds
  inc(s_second, sd);
  while (s_second>=60) do begin inc(s_minute);dec(s_second, 60); end;
  // minutes
  inc(s_minute, md);
  while (s_minute>=60) do begin inc(s_hour);dec(s_minute, 60); end;
  inc(s_hour, hd);
  // end time
  // milliseconds
  inc(e_msecond, msd);
  while (e_msecond>=1000) do begin inc(e_second);dec(e_msecond, 1000); end;
  // seconds
  inc(e_second, sd);
  while (e_second>=60) do begin inc(e_minute);dec(e_second, 60); end;
  // minutes
  inc(e_minute, md);
  while (e_minute>=60) do begin inc(e_hour);dec(e_minute, 60); end;
  inc(e_hour, hd);
end;

procedure Trec.DecreaseTime(decal : string);
var
  hd,md,sd,msd : integer;
begin
  ConvtTime(decal, hd, md, sd, msd);
  // milliseconds
  dec(s_msecond, msd);
  while (s_msecond<0) do begin dec(s_second);inc(s_msecond, 1000); end;
  // seconds
  dec(s_second, sd);
  while (s_second<0) do begin dec(s_minute);inc(s_second, 60); end;
  // minutes
  dec(s_minute, md);
  while (s_minute<0) do begin dec(s_hour);inc(s_minute, 60);  end;
  dec(s_hour, hd);

  // end time
  // milliseconds
  dec(e_msecond, msd);
  while (e_msecond<0) do begin dec(e_second);inc(e_msecond, 1000); end;
  // seconds
  dec(e_second, sd);
  while (e_second<0) do begin dec(e_minute);inc(e_second, 60); end;
  // minutes
  dec(e_minute, md);
  while (e_minute<0) do begin dec(e_hour);inc(e_minute, 60); end;
  dec(e_hour, hd);
end;

procedure Trec.SubTimeStringToRec(tml : string);
var
  deb, fin : string;
begin
  deb := copy(tml, 1, 12);
  fin := copy(tml, 18, 12);
  ConvtTime(deb, s_hour, s_minute, s_second, s_msecond);
  ConvtTime(fin, e_hour, e_minute, e_second, e_msecond);
end;

function Trec.debTimeToString:string;
begin
  // build result
  result:=inttostr2(s_hour,2)+':'+
          inttostr2(s_minute,2)+':'+
          inttostr2(s_second,2)+','+
          inttostr2(s_msecond,3);
end;

function Trec.endTimeToString:string;
begin
  // build result
  result:=inttostr2(e_hour,2)+':'+
          inttostr2(e_minute,2)+':'+
          inttostr2(e_second,2)+','+
          inttostr2(e_msecond,3);
end;

function Trec.ToString:string;
var
  i : integer;
begin
  result := inttostr2(index, 5)+' | '+
            debTimeToString + ' --> ' +
            endTimeToString + ' | ';
  for i:=0 to subs.Count-1 do
    if subs[i] <> '' then
      result := result + '"' + subs[i] + '",';
  setlength(result, length(result)-1);
end;

end.
