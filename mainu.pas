unit MainU;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ComCtrls, Grids, StdCtrls,contnrs,math;

const
  D_deelfactortest = 1;

type
  Tactiesoort= (asWandelen,asHardlopen);

  TAktie = class
  private
   FActieSoort: tActieSoort;
   FMinuten: integer;
   FVerstreken: boolean;
    function GetSeconden: integer;
  public
    property Seconden: integer read GetSeconden;
    property Actiesoort: tActieSoort read FActieSoort write FActiesoort;
    property Minuten: integer read Fminuten write Fminuten;
    property Verstreken: boolean read  fVerstreken write fVerstreken;
  end;

  TAktieLijst = class (Tobjectlist);


  TLoopSchema = class
  private
   fWeeknr: integer;
   FDagnr: integer;
    fgedaan: boolean;
    function GetTotaalTijd: integer;
    procedure setgedaan(const Value: boolean);
  public
   Kolomen: TStringlist;
   Aktielijst: TAktieLijst;
   StrSchema: string;

   procedure VulKolomen;
   property Weeknr: Integer read Fweeknr  write Fweeknr;
   property DagNr: Integer read FDagNr write FDagnr;
   property TotaalTijd: integer read GetTotaalTijd;
   property Gedaan: boolean read fgedaan write setgedaan;
   constructor create;
   destructor destroy; override;
  end;



  TLoopSchemaLijst = class(Tobjectlist)
  private
   fBestand: TStringList;
    function getKolCount: integer;
  public
   property kolCount: integer read getKolCount;
   property Bestand: TStringList read fBestand write fBestand;
   procedure InlezenBestand;
   procedure schrijfweg;
   constructor create;
   destructor destroy; override;
  end;

  { TmainFRM }

  TmainFRM = class(TForm)
    Button1: TButton;
    Image1: TImage;
    Image2: TImage;
    ImageList1: TImageList;
    lblverstreken: TLabel;
    lbltijd: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    pbAktie: TProgressBar;
    pball: TProgressBar;
    StringGrid1: TStringGrid;
    tmr: TTimer;
    ToggleBox1: TToggleBox;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Panel3Click(Sender: TObject);
    procedure tmrTimer(Sender: TObject);
    procedure ToggleBox1Change(Sender: TObject);
  private

    FActie: TAktie;
    fHuidigSchema: TLoopSchema;
    FActieNo: integer;
    FPauze: boolean;
    procedure setHuidigSchema(const Value: TLoopSchema);
    procedure setActie(const Value: TAktie);
    procedure SetActieNo(const Value: integer);
    procedure setPauze(const Value: boolean);
  public
    Rij: integer;
    LoopSchemaLijst : TLoopSchemaLijst;
    StartSchematijd: tDateTime;
    StartActieTijd: tdatetime;
    PauzeTijd: TDatetime;
    function DubbleToSeconds(const DTijd: double): integer;
    function SecondsToDubble(const seconds: integer):double;
    property Pauze: boolean read FPauze write setPauze;
    property ActieNo : integer read FActieNo write SetActieNo;
    property HuidigSchema: TLoopSchema read fHuidigSchema write setHuidigSchema;
    property Actie : TAktie read FActie Write setActie;
    procedure SetPic(const Actiesoort: Tactiesoort);
    function BepaalHuidigSchema: TLoopSchema;
    procedure ShowinGrit;
  end;

var
  mainFRM: TmainFRM;

implementation

{$R *.lfm}


function FT_GetTokenAt(const cString: string; const cSeperator: Char; const nAt: Integer): string;
var
  nI               : Integer;                    {teller}
  nJ               : Integer;                    {teller}
begin
  Result := '';
  nI     := 0;
  nJ     := 1;
  while (nI <= nAt) and (nJ <= Length(cString)) do
  begin
    if cString[nJ] = cSeperator then
       Inc(nI)
    else
    begin
      if nI = nAt then
       Result := Result + cString[nJ];
    end;
    Inc(nJ);
  end; {while}
end; {FT_GetTokenAt}


constructor TLoopSchema.Create;
begin
  inherited;
  Aktielijst := Taktielijst.Create;
  Aktielijst.OwnsObjects := true;
  kolomen := TStringlist.Create;
end;


destructor TLoopSchema.Destroy;
begin
  aktielijst.free;
  kolomen.Free;
  inherited;
end;

procedure TmainFRM.setHuidigSchema(const Value: TLoopSchema);
begin
  Caption := 'Loopschema Week: ' + IntToStr(Value.Weeknr) + ' dag: ' + IntToStr(Value.dagnr);
  fHuidigschema := Value;
  lbltijd.caption := IntTostr(Value.TotaalTijd);
  pball.max :=  Value.TotaalTijd * 60 ;
end;


procedure TmainFRM.setPauze(const Value: boolean);
begin
  FPauze := Value;
  if Value  then
  begin
     tmr.Enabled := false;
     PauzeTijd := Now;
     Image2.Visible := true;
  end
  else
  begin
     StartSchematijd  :=  StartSchematijd + (now-PauzeTijd);
     StartActieTijd := StartActieTijd + (now-PauzeTijd);
     Image2.Visible := false;
     tmr.Enabled := true;
  end;
end;

function TLoopSchema.GetTotaalTijd: integer;
var
  I: Integer;
begin
  result := 0;
  for I := 0 to Aktielijst.Count-1 do
  begin
    result :=  result + TAktie(Aktielijst[i]).Minuten;
  end;

end;

procedure TLoopSchemaLijst.schrijfweg;
var
  I: Integer;
begin
  bestand.clear;
  for I := 0 to count-1 do
  begin
    Bestand.Add(TLoopSchema(self[i]).StrSchema);
  end;
  bestand.SaveToFile(ChangeFileExt(ParamStr(0), '.csv'));
end;

procedure TLoopSchema.setgedaan(const Value: boolean);
begin

  if (Value and not fgedaan) then
     StrSchema := StringReplace(StrSchema,';N;',';OK;',[]);
  fgedaan := Value;
end;

procedure TLoopSchema.VulKolomen;
Var I:integer;
begin
  kolomen.Clear;
  Kolomen.Add('Week ' + IntToStr(weeknr));
  Kolomen.Add('Dag ' + IntToStr(dagnr));
  if gedaan then
    Kolomen.Add('OK')
  else
    Kolomen.Add('N');
  For i := 0 to Aktielijst.Count-1 do
  begin
   if TAktie(AktieLijst[i]).Actiesoort = asWandelen then
     Kolomen.Add(Inttostr(TAktie(Aktielijst[i]).Minuten) + ' W' )
   else
     Kolomen.Add(Inttostr(TAktie(Aktielijst[i]).Minuten) + ' H' );
  end;

end;

procedure TLoopSchemaLijst.InlezenBestand;
var ls : TLoopSchema;
     Doorgaan: Boolean;
     tekennr,i: Integer;
     actstr,strweek:string;
     actie: TAktie;
begin
  Fbestand.LoadFromFile(ChangeFileExt(ParamStr(0), '.csv'));
  for i := 0 to  fBestand.Count -1 do
  begin
    Doorgaan := True;
    tekennr := 2;
    ls := TLoopSchema.Create;
    strweek :=  FT_GetTokenAt(Fbestand[I],';',0);
    // strweek := '1';
   // ls.Weeknr := StrToInt(FT_GetTokenAt(Fbestand[I],';',0));
     ls.Weeknr := StrToInt(strweek);
    ls.dagnr := StrToInt(FT_GetTokenAt(Fbestand[I],';',1));
    ls.Fgedaan := (FT_GetTokenAt(Fbestand[I],';',2) = 'OK');
    ls.StrSchema := Fbestand[I];
    while Doorgaan do
    begin
       Inc(tekennr);
       actstr :=  FT_GetTokenAt(Fbestand[I],';',tekennr);
       Doorgaan := ((FT_GetTokenAt(actstr,':',0) = 'H') or (FT_GetTokenAt(actstr,':',0) = 'W'));
       if Doorgaan  then
       begin
         actie := TAktie.Create;
         if (FT_GetTokenAt(actstr,':',0) = 'H') then
           actie.Actiesoort := asHardlopen
         else
          actie.Actiesoort := asWandelen;
        actie.minuten := StrToIntDef(FT_GetTokenAt(actstr,':',1),0);
        ls.Aktielijst.add(actie);
       end;
    end;

    ls.VulKolomen;
    Add(ls);
  end;
end;


constructor TLoopSchemaLijst.create;
begin
   inherited;
   Fbestand := TStringList.Create;
end;

destructor TLoopSchemaLijst.Destroy;
begin
   Fbestand.Free;
   inherited;
end;


function TLoopSchemaLijst.getKolCount: integer;
var
  I: Integer;
begin
  result := 0;
  for I := 0 to Count-1 do
  begin
    result := max(result, TLoopSchema(self[i]).Aktielijst.Count);
  end;
  result := result + 2;
end;


function TmainFRM.BepaalHuidigSchema: TLoopSchema;
var
  I: Integer;
begin
  result := nil;
  for I := 0 to LoopSchemaLijst.Count-1 do
  begin
    if not TLoopSchema(LoopSchemaLijst[i]).Gedaan then
    begin
       result := TLoopSchema(LoopSchemaLijst[i]);
       rij := i;
       exit;
    end;
  end;

end;

procedure TmainFRM.Button1Click(Sender: TObject);

begin
  StartSchematijd:= now;
  StartActieTijd:= now;
  tmr.Enabled := true;
  Actie := TAktie(HuidigSchema.Aktielijst[0]);
  button1.Enabled :=  false;
end;

procedure TmainFRM.ToggleBox1Change(Sender: TObject);
begin
  Pauze := not Pauze;
end;



function TmainFRM.DubbleToSeconds(const DTijd: double): integer;
begin
  result := Round((DTijd *24*60*60));
end;

procedure TmainFRM.FormCreate(Sender: TObject);
begin
  fpauze := false;
  LoopSchemaLijst :=  TLoopSchemaLijst.Create;
  LoopSchemaLijst.OwnsObjects := true;
  LoopSchemaLijst.InlezenBestand;
  Actieno := 0;
end;

function TmainFRM.SecondsToDubble(const seconds: integer):double;
begin
  result := (seconds /(24*60*60));
end;

procedure TmainFRM.FormDestroy(Sender: TObject);
begin
  LoopSchemaLijst.Free;
end;

procedure TmainFRM.FormShow(Sender: TObject);
begin
  ShowinGrit;
  HuidigSchema := BepaalHuidigSchema;

end;

procedure TmainFRM.Panel3Click(Sender: TObject);
begin

end;

procedure TmainFRM.SetPic(const Actiesoort: Tactiesoort);
var PicNr:integer;
   //  sizer:  TsizeF;
begin
  if Actiesoort = asWandelen then
    PicNr := 0
  else
    Picnr := 1;
 { sizer:=  TsizeF.Create(0,0);
  sizer.Width := 170;
  sizer.Height := 170; }
 // Image1.Picture := ImageList1.im[1];..piBitmap(sizer, Picnr);
end;

procedure TmainFRM.setActie(const Value: TAktie);
begin
  FActie := Value;
  StartActieTijd := now;
  setPic(FActie.Actiesoort);
  pbAktie.Max := FActie.Seconden;

end;

procedure TmainFRM.SetActieNo(const Value: integer);
begin
  FActieNo := Value;
  StringGrid1.Cells[FActieNo+3 ,rij];
end;

procedure TmainFRM.ShowinGrit;
 var  I,J :integer;
     //  stc   : TStringColumn;
begin
  StringGrid1.RowCount :=  LoopSchemaLijst.Count ;
  {for I := 0 to LoopSchemaLijst.kolCount do
  begin
    stc := TStringColumn.Create(StringGrid1);
    if i = 0 then
      Stc.Width := 55
    else
       Stc.Width := 40;
    StringGrid1.AddObject(stc);
  end;}
  for i := 0 to LoopSchemaLijst.Count -1 do
  begin
    for J := 0 to Tloopschema( LoopSchemaLijst[i]).Kolomen.Count-1 do
      StringGrid1.Cells[J , i]  := TLoopschema( LoopSchemaLijst[i]).Kolomen[J];
  end;
end;

procedure TmainFRM.tmrTimer(Sender: TObject);
var
  VerstrekenSec : integer;
   ActieSec: integer;
begin
  VerstrekenSec :=  DubbleToSeconds(now - StartSchematijd) *  D_deelfactortest;
  pbAll.Position :=  VerstrekenSec;
  lblverstreken.caption:= inttostr(round(VerstrekenSec/60));
  ActieSec := DubbleToSeconds (now - StartActieTijd) *  D_deelfactortest;
 { if   ActieSec + 0.5 >  (Actie.Seconden)  then
  begin
     beep(600,400);

  end;}
  if   ActieSec >  (Actie.Seconden)  then
  begin
    {windows.beep(800,1000);   }
    ActieNo := ActieNo + 1;
    if actieno < HuidigSchema.Aktielijst.Count then
      Actie := Taktie (HuidigSchema.Aktielijst[ActieNo])
    else
    begin
      tmr.Enabled := false;
      HuidigSchema.Gedaan := true;
      StringGrid1.Cells[2 ,rij] := 'OK';
      LoopSchemaLijst.schrijfweg;
      ShowMessage('Yesss!, klaar');
     end;
  end
  else
   pbAktie.Position := ActieSec;
end;

{ TAktie }

function TAktie.GetSeconden: integer;
begin
  result := Round((minuten * 60));
end;

end.



