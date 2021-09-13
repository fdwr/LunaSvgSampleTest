unit Winsort;
  
interface
  
  uses
  Sysutils, Wintypes, Winprocs, Messages, Classes, Graphics, Controls, 
  Forms, Dialogs, Stdctrls, Extctrls, Menus; 
  
type
  Tform1 = class(Tform)
    Control: Tpanel; 
    Method: Tradiogroup; 
    Scramble: Tbutton; 
    Sort: Tbutton; 
    Mainmenu1: Tmainmenu; 
    About1: Tmenuitem; 
    Sortdemo1: Tmenuitem;
    Paintframe: Tbevel; 
    Randomize: Tcheckbox;
    procedure Formcreate(Sender: Tobject); 
    procedure Scrambleclick(Sender: Tobject); 
    procedure Sortclick(Sender: Tobject); 
    procedure Formpaint(Sender: Tobject);
    procedure FormDblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Showbar(N: Integer); 
  end; 
  
var
  Form1: Tform1; 
  
(*----------------------------------------------------------------------------*)
implementation
  
  {$R *.DFM}
  uses
  Sortpack; 
const
  Maxbars = 300;
  Offset = 1; 
  Right = 1; 
  Lowerws = 5; 
  Upperws = 10; 
var
  Nbars: Integer;
  Barwidth: Integer; 
  Maxval: Integer; 
  Val: array[0 .. Maxbars - 1]of Byte; 
  
(*----------------------------------------------------------------------------*)
procedure Tform1.Showbar(N: Integer); 
var
  X1, Y1, X2, Y2: Integer; 
  begin
    X1 := Paintframe.Left + (N + Offset) * Barwidth; 
    Y1 := Paintframe.Height - Lowerws; 
    X2 := X1 + Barwidth - 1; 
    Y2 := Y1 - Val[N]; 
    Canvas.Pen.Color := Color;
    Canvas.Moveto(X1, 0); 
    Canvas.Lineto(X1, Clientheight); 
    Canvas.Pen.Color := Clblack; 
    Canvas.Moveto(X1, Y1);
    Canvas.Lineto(X1, Y2); 
  end; 
  
(*----------------------------------------------------------------------------*)
procedure Tform1.Formcreate(Sender: Tobject); 
  begin
    Maxval := Paintframe.Height - Upperws - Lowerws; 
    if Maxval > 255 then Maxval := 255; 
    Canvas.Pen.Width := 1;
    Barwidth := 2; 
    Nbars := Paintframe.Width div Barwidth;
  end; 
  
(*----------------------------------------------------------------------------*)
procedure Tform1.Scrambleclick(Sender: Tobject);
var
  I: Integer;
  begin
    if not Randomize.Checked then Randseed := 1234567;   {so we always have the same array}
    for I := 0 to Nbars - 1 do
    begin
      Val[I] := Random(Maxval);
      Showbar(I);
    end;
  end;
(*----------------------------------------------------------------------------*)
procedure Tform1.Formpaint(Sender: Tobject);
  begin
    Scrambleclick(Sender);
  end;

(*----------------------------------------------------------------------------*)
function Compare(I, J: Integer): Boolean;
  begin
    Result := Val[I] < Val[J];
  end;
(*----------------------------------------------------------------------------*)
procedure Swap(I, J: Integer);
var
  Temp: Integer;
  begin
    Temp := Val[I];
    Val[I] := Val[J];
    Val[J] := Temp;
    Form1.Showbar(I);
    Form1.Showbar(J);
  end;

var Pval: Integer;
(*----------------------------------------------------------------------------*)
procedure Pivot(Left, Right: Integer);
  begin
    (*  There is some debate about how to pick the pivot value.
        This just takes the middle one. *)
    Pval := Val[(Left + Right) div 2];
  end;
(*----------------------------------------------------------------------------*)
function Compivot(I: Integer): Integer;
  begin
    Result := Val[I] - Pval;
  end;
(*----------------------------------------------------------------------------*)
procedure Distributionsort( {Timing: N} N: Integer);
{  This is a real screamer, but it takes a lot of space,
   and is hard to package for inclusion in a library.
   (This is why it is in line in this demo)

   It requires prior knowledge of how the array and keys are structured.
   It is only feasible where there are a small number of possible keys,
   and you know in advance what the possible values are. In this example,
   there are only 256 different values.

   It works well, for example, where the key is sex, department
   or state.  It would be a disaster if the keys were name or
   phone number.

   The strategy is to copy the array into a save area, and count
   the number of each key present.  The original array is then
   marked off into bins of the appropriate size.  After that, the
   records are copied (like dealing cards) into the proper bin.  }
var
  Bins, Start: array[Byte] of Integer;
  I, Pos: Integer;
  Save: array[0 .. Maxbars - 1] of Integer;
  begin
    for I := 0 to 255 do Bins[I] := 0;
    Start := Bins;

    for I := 0 to N - 1 do           {copy array to scratch area}
    begin
      Save[I] := Val[I];
      Inc (Bins[Val[I]]);            {count the number of each key value}
    end;

    Pos := 0;
    for I := 1 to 255 do
    begin
      Inc(Pos, Bins[I - 1]);         {compute the start position of each bin}
      Start[I] := Pos;
    end;

    for I := 0 to N - 1 do           {deal the saved array back to the original}
    begin
      Val[Start[Save[I]]] := Save[I];
      Form1.Showbar(Start[Save[I]]);
      Inc(Start[Save[I]]);
    end;

  end;

(*----------------------------------------------------------------------------*)
procedure TForm1.FormDblClick(Sender: TObject);
begin
  Shuffle(Swap,nbars-1);
end;
(*----------------------------------------------------------------------------*)
procedure Tform1.Sortclick(Sender: Tobject);
  begin
    case Method.Itemindex of
      {loop}
      0: Loopsort(Swap, Compare, Nbars);
      {bubble}
      1: Bubblesort(Swap, Compare, Nbars);
      {shell}
      2: Shellsort(Swap, Compare, Nbars);
      {quick}
      3: Quicksort(Pivot, Compivot, Swap, 0, Nbars - 1);
      {distribution}
      4: Distributionsort(Nbars);
    end;
  end;


end.
