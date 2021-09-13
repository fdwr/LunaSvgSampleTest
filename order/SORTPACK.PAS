{=============================================}
{                                             }
{ James L. Allison                            }
{ Neptune Systems                             }
{ 1703 Neptune Lane                           }
{ Houston, Texas  77062                       }
{ USA                                         }
{ http://users.aol.com/neptunesys             }
{ Comments welcome                            }
{                                             }
{ Released to public domain.                  }
{ Apr 13, 1998                                }
{                                             }
{=============================================}
unit Sortpack;
interface
{
  This is a version of the sort package that does not know or care where
  the data is stored.  This is often used for an in-place file sort,
  where Interchange and Less_Than usually have to read and write
  blocks from a disk.
}

type
Interchange = procedure (I, J: Integer);  {Swap two elements}

{  Less_Than is a user defined function that determines the
   order of the sort.  It may be as simple or complex as
   necessary to give the desired order.  In particular it
   can use any field in a record as the sort key, or use
   more than one key.
   }
Less_Than  = function  (I, J: Integer): Boolean;
{
  Example:

  function Compare(I, J: Integer): Boolean;
    begin
      Result := Val[I] < Val[J];
    end;

  procedure Swap(I, J: Integer);
  var
    Temp: Integer;
    begin
      Temp := Val[I];
      Val[I] := Val[J];
      Val[J] := Temp;
    end;

    Shellsort(Swap, Compare, N);
}

{ The range on i, j is [0..N-1] where N is the item count.  That is,
  the first index is assumed to be zero.  These know nothing
  about the size or type of items being sorted.  This information
  is contained entirely in the two imported procedures.
  }

{  ShellSort: Almost as fast as QuickSort, but without recursion.
   Can be used where fixed size is required (spacecraft, submarine, etc.)
   May cause thrashing in a virtual memory system where the array will
   not quite fit in real memory.
   }
procedure Shellsort(                {Timing: N log N}
            Swap: Interchange;      {procedure to swap two items}
            Compare: Less_Than;     {function to compare two items}
            N: Integer              {total number of items}
            );

{  BubbleSort: The only time to use this is when the array is almost
   in order, with only a couple of items out of place. BubbleSort is
   a special purpose method, and should never be used for general
   purpose sorting.  Stick to ShellSort or QuickSort.
   }
procedure Bubblesort(               {Timing: N * N}
            Swap: Interchange;      {procedure to swap two items}
            Compare: Less_Than;     {function to compare two items}
            N: Integer              {total number of items}
            );

{ The only reason to ever use this is that it is so simple that
  you can code it in line from memory. OK for a few dozen items.
}
procedure Loopsort(                 {Timing: N * N}
            Swap: Interchange;      {procedure to swap two items}
            Compare: Less_Than;     {function to compare two items}
            N: Integer              {total number of items}
            );

{ QuickSort is the most popular general purpose high speed sort. It may
  be the fastest for an array about which you know nothing. It behaves
  well in virtual memory because of the fairly smoothe way it accesses
  the data. The only drawback seems to be that it cannot be used where
  fixed size is required.
}
type
  Setpivot = procedure(Left, Right: Integer);  {save a value as pivot}
  Comparepivot = function(I: Integer): Integer; {compare Ith value to saved pivot}
{
  Example:

  var
    Pval: Integer;

  procedure Pivot(Left, Right: Integer);
    begin
      (*  There is some debate about how to pick the pivot value.
          This just takes the middle one. *)
      Pval := Val[(Left + Right) div 2];
    end;

  function Compivot(I: Integer): Integer;
    begin
      Result := Val[I] - Pval;
    end;

  Quicksort(Pivot, Compivot, Swap, 0, N - 1);
}
procedure Quicksort(                {Timing: N log N}
            Pivot: Setpivot;        {save a value as pivot}
            Compare: Comparepivot;  {compare Ith value to saved pivot}
            Swap: Interchange;      {procedure to swap two items}
            Left, Right: Integer);  {bounds of sort interval}

{For testing, card games, etc.}
procedure Shuffle(                  {Timing: N}
            Swap: Interchange;      {procedure to swap two items}
            N: Integer              {total number of items}
            );

(*----------------------------------------------------------------------------*)
implementation
(*----------------------------------------------------------------------------*)
procedure Shellsort(                {Timing: N log N}
            Swap: Interchange;      {procedure to swap two items}
            Compare: Less_Than;     {function to compare two items}
            N: Integer              {total number of items}
            );
var
  Gap, I, J: Integer;

  begin
    Gap := N div 2;
    while Gap > 0 do
    begin
      I := Gap;
      while I < N do
      begin
        J := I - Gap;
        while (J >= 0) and (Compare(J + Gap, J)) do
        begin
          Swap(J, J + Gap);
          Dec(J, Gap);
        end;
        Inc(I);
      end;
      Gap := Gap div 2;
    end;
  end;

(*----------------------------------------------------------------------------*)
procedure Bubblesort(               {Timing: N * N}
            Swap: Interchange;      {procedure to swap two items}
            Compare: Less_Than;     {function to compare two items}
            N: Integer              {total number of items}
            );
var
  J: Integer;
  Finished: Boolean;
  begin
    repeat
      Finished := True;
      for J := 0 to N - 2 do
      if Compare(J + 1, J) then
      begin
        Finished := False;
        Swap(J, J + 1);
      end;
      Dec(N);
    until Finished;
  end;
(*----------------------------------------------------------------------------*)
procedure Loopsort(                 {Timing: N * N}
            Swap: Interchange;      {procedure to swap two items}
            Compare: Less_Than;     {function to compare two items}
            N: Integer              {total number of items}
            );
var
  I, J: Integer;
  begin
    for I := 0 to N - 1 do
    for J := I + 1 to N - 1 do
    if Compare(J, I) then Swap(I, J);
  end;
(*----------------------------------------------------------------------------*)
procedure Quicksort(                {Timing: N log N}
            Pivot: Setpivot;        {save a value as pivot}
            Compare: Comparepivot;  {compare Ith value to saved pivot}
            Swap: Interchange;      {procedure to swap two items}
            Left, Right: Integer);  {bounds of sort interval}
var
  P, Q: Integer;
  begin
    if Left >= Right then exit;
    P := Left;
    Q := Right;
    Pivot(Left, Right);

    while P < Q do
    begin
      while Compare(P) < 0 do Inc(P);
      while Compare(Q) > 0 do Dec(Q);
      if P > Q then break;
      Swap(P, Q);
      Inc(P); Dec(Q);
    end;

    Quicksort(Pivot, Compare, Swap, Left, Q);
    Quicksort(Pivot, Compare, Swap, P, Right);
  end;

(*----------------------------------------------------------------------------*)
procedure Shuffle(                  {Timing: N}
            Swap: Interchange;      {procedure to swap two items}
            N: Integer              {total number of items}
            );
var
  I, J: Integer;

  begin
    for I := 0 to N - 1 do
    begin
      J := Random(N);
      if I <> J then Swap(I, J);
    end;
  end;
(*----------------------------------------------------------------------------*)
(*
 Included here as a comment, just to document the method.

 Philosophical point: Distributionsort is a true SORTING method,
 while the others are ORDERING methods.  Most people do not make
 a distinction, because once you have done one, the other is
 usually trivial. By SORTING I mean gathering items into groups based
 on similarity of an attribute; student grade cards are bundled by
 department. By ORDERING I mean putting items in line with order
 determined by value of an attribute; student cards are in a file
 cabinet ORDERED on social security number.

 When the postman places a letter in your mailbox he is SORTING
 by address. He usually ORDERS by address before he starts, to make
 the SORTING easier.

 One more point, then I'll shut up. Only computer people use the word SORT
 to mean ORDER. When a customer tells a data base programmer that he wants
 to SORT by department, he usually means SELECT, not ORDER. A lot of
 confusion can be avoided by hearing SELECT when he says SORT. How I
 learned this should be obvious without going into the miserable details.

procedure Distributionsort( {Timing: N} N: Integer);
{  This is a real screamer, but it takes a lot of space,
   and is hard to package for inclusion in a library.

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
      Inc(Start[Save[I]]);
    end;

  end;
*)
end.
