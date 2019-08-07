unit Edit;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TEditFrm = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  EditFrm: TEditFrm;

implementation

{$R *.lfm}

end.
