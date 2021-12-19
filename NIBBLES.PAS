Program Nibbles;

Uses Crt,MSGRAPH,Mouse;

Const
 MaxYZone=183;

 {Code de touche clavier renvoy‚e par ReadKey}
 kbNoKey=0;{Pas de touche}
 kbEsc=$001B;{Escape}
 kbUp=$4800;{Up}
 kbLeft=$4B00;{FlŠche de gauche (Left)}
 kbRight=$4D00;{FlŠche de droite (Right)}
 kbDn=$5000;{FlŠche du bas (Down)}
 kbHome=$4700;{Home}
 kbTab=$0F09;{Tabulation}
 kbEnd=$4F00;{End}
 kbEnter=$000D;{Enter}

Type
 CenterType=(__Left__,__Justified__,__Right__);

 RGB=Record
  R:Byte;                       { (R)ouge ((R)ed) }
  G:Byte;                       { (V)ert  ((G)reen) }
  B:Byte;                       { (B)leu  ((B)lue) }
 End;

Const PalYellow:Array[0..7]of RGB=(
 (R:$FC-70;G:$FC-70;B:$24-35),
 (R:$FC-60;G:$FC-60;B:$24-30),
 (R:$FC-50;G:$FC-50;B:$24-25),
 (R:$FC-40;G:$FC-40;B:$24-20),
 (R:$FC-30;G:$FC-30;B:$24-15),
 (R:$FC-20;G:$FC-20;B:$24-10),
 (R:$FC-10;G:$FC-10;B:$24-5),
 (R:$FC;G:$FC;B:$24));

Const PalRed:Array[0..7]of RGB=(
 (R:$FC-70;G:0;B:0),
 (R:$FC-60;G:0;B:0),
 (R:$FC-50;G:0;B:0),
 (R:$FC-40;G:0;B:0),
 (R:$FC-30;G:0;B:0),
 (R:$FC-20;G:0;B:0),
 (R:$FC-10;G:0;B:0),
 (R:$FC;G:0;B:0));

Const
 CurrText:Byte=0;

Var
 Speed:Integer;
 X,Y,RX,RY,PR:Array[1..2]of Integer;

Procedure WaitRetrace;Begin
 Delay(10*Speed);
End;

Function RGB2Color(R,G,B:Byte):LongInt;
Var
 Value:LongInt;
 X:RGB Absolute Value;
Begin
 Value:=0;
 X.R:=R shr 2;
 X.G:=G shr 2;
 X.B:=B shr 2;
 RGB2Color:=value;
End;

Function MaxByte(N,Max:Byte):Byte;Begin
 If(N<Max)Then MaxByte:=N+1
	  Else MaxByte:=0
End;

Function MinByte(N,Max:Byte):Byte;Begin
 If N>0Then MinByte:=N-1
       Else MinByte:=Max
End;

Function  Alpha(a,b:LongInt):LongInt;Begin
 If(a<=b)Then Alpha:=a
	 Else Alpha:=b;
End;

Procedure CloseCur;Begin
 _SetTextCursor($2000);
End;

Function CenterStr(S:String;Width:Byte):String;
Var
 I:Byte;
 Temp:String;
Begin
 Temp:='';
 For I:=1 to (Width-Length(S))shr 1 do Temp:=Temp+' ';
 Temp:=Temp+S;
 While Length(Temp)<Width do Temp:=Temp+' ';
 CenterStr:=Temp;
End;

Procedure PutMsg(X:Byte;Msg:String;Kr:Byte);Begin
 _SetTextPosition(24,X);
 _SetColor(Kr and $F);
 _OutText(Msg);
End;

Function pCenter(Len:Byte;Center:CenterType):Byte;
Begin
 Case(Center)of
  __Left__:pCenter:=0;
  __Justified__:pCenter:=(40-Len)shr 1;
  __Right__:pCenter:=40-Len;
 End;
End;

Procedure PutTxtCenter(Y:Byte;Center:CenterType;Msg:String;Attr:Byte);Begin
 _SetTextPosition(Y,pCenter(Length(Msg),Center));
 _SetColor(Attr and $F);
 _OutText(Msg);
End;

Function WordToStr(X:Word):String;
Var
 S:String;
Begin
 Str(X,S);
 WordToStr:=S
End;

Procedure Init;Begin
 X[1]:=Random(320);
 Y[1]:=Random(MaxYZone);
 Repeat
  X[2]:=Random(320);
  Y[2]:=Random(MaxYZone);
 Until Not((X[1]=X[2])and(Y[1]=Y[2]));
 RX[1]:=0;RY[1]:=-1;RX[2]:=0;RY[2]:=1;
 _SetBkColor(0);
 _ClearScreen(_GClearScreen);
 PutMsg(0,'Joueur 1: '+WordToStr(PR[1]),236);
 PutMsg(24,'Ordinateur: '+WordToStr(PR[2]),244);
End;

Const
 HomeY=8;
 Max=9;

Procedure PutBar(Y:Integer);Begin
 GotoXY(8,HomeY+Y);
 TextBackground($A);
 TextColor(0);
 Write(CenterStr(WordToStr(Y+1),24));
 ms_set_pos(0,Y*8);
End;

Procedure UndoBar(Y:Integer);Begin
 GotoXY(8,HomeY+Y);
 TextBackground(0);
 TextColor($9);
 Write(CenterStr(WordToStr(Y+1),24));
End;

Var D:Byte;

Procedure Show;Begin
 Case(D)of
  0:PutTxtCenter(2,__Justified__,'Vitesse',$B);
  8:PutTxtCenter(2,__Justified__,'Vitesse',$E);
 End;
 D:=(D+1)and 15;
End;

Procedure ChoiceSpeed;
Label 0;
Var
 XM,YM,K,Count:Word;
 J,Y,Wait,BM:Integer;
Begin
 If ms_init(BM)Then ms_set_vminmax(0,Max*8);
 Repeat
  Y:=0;YM:=0;BM:=0;
  If(_SetVideoMode(_TextC40)=0)Then;
  If _DisplayCursor(False)Then;
  For J:=0to(Max)do UndoBar(J);
  PutBar(Y);
  Wait:=0;
  Repeat
   Repeat
    WaitRetrace;
    Inc(Wait);
    If Wait=4Then Begin
     Show;
     Wait:=0;
    End;
    {If(ms_get_b($FFFF,Count,XM,YM)=0)Then;}
    {If(YM shr 3<>Y)Then Begin
     UndoBar(Y);
     Y:=YM shr 3;
	 If Y>Max Then Y:=Max;
     PutBar(Y);
    End;}
    If BM>0Then Goto 0;
   Until KeyPressed;
   K:=Byte(ReadKey);
   If K=0Then K:=K or (Byte(ReadKey)shl 8);
   Case(K)of
    kbHome:Begin
	 UndoBar(Y);
     Y:=0;
	 PutBar(Y);
    End;
    kbUp,kbLeft:Begin
     UndoBar(Y);
     Y:=MinByte(Y,Max);
	 PutBar(Y);
    End;
    kbDn,kbTab,kbRight:Begin
     UndoBar(Y);
     Y:=MaxByte(Y,Max);
	 PutBar(Y);
    End;
    kbEnd:Begin
     UndoBar(Y);
     Y:=Max;
     PutBar(Y);
    End;
    kbEnter:0:Begin
	 Speed:=9-Alpha(Y,Max-1);
	 Exit;
	End;
    kbEsc:Begin
	 Speed:=1;
	 Exit;
	End;
   End;
  Until False;
 Until False;
End;

Procedure Play;
Var K,J:Integer;
Begin
 FillChar(PR,SizeOf(PR),0);
 Speed:=1;
 ChoiceSpeed;
 If _SetVideoMode(_MRes256Color)=0 Then Begin
  WriteLn('Mode vidéo non supporté');
  Halt;
 End;
 For J:=0 to 7 do If _RemapPalette(236+J,RGB2Color(PalYellow[J].R,PalYellow[J].G,PalYellow[J].B))=0Then;
 For J:=0 to 7 do If _RemapPalette(244+J,RGB2Color(PalRed[J].R,PalRed[J].G,PalRed[J].B))=0Then;
 Init;
 Repeat
  Repeat
   If _GetPixel(X[1],Y[1])<>0Then Begin
    PutTxtCenter(12,__Justified__,'Vous avez fait l''impacte!',$C);
    {ClrKbd;}
    If ReadKey<>#0 Then;
    Inc(PR[2]);
    Init;
   End;
   If _GetPixel(X[2],Y[2])<>0Then Begin
    PutTxtCenter(12,__Justified__,'L''Ordinateur a fait l''impacte!',$C);
    {ClrKbd;}
    If ReadKey<>#0 Then;
    Inc(PR[1]);
    Init;
   End;
   For J:=1to 2do Begin
    _SetColor(228+(J shl 3)+CurrText);
    _SetPixel(X[J],Y[J]);
   End;
   WaitRetrace;
   CurrText:=(CurrText+1)and 7;
   If RX[2]<>0Then Begin
    If _GetPixel(X[2]+RX[2],Y[2])<>0Then Begin
     RX[2]:=0;
     If _GetPixel(X[2],Y[2]-1)=0Then RY[2]:=-1 Else RY[2]:=1;
    End;
   End
    Else
   If RY[2]<>0Then Begin
    If _GetPixel(X[2],Y[2]+RY[2])<>0Then Begin
     RY[2]:=0;
     If _GetPixel(X[2]-1,Y[2])=0Then RX[2]:=-1 Else RX[2]:=1;
    End;
   End;
   For J:=1to 2do Begin
    Inc(X[J],RX[J]);
	Inc(Y[J],RY[J]);
    If RX[J]<>0Then Begin
	 If X[J]=0Then X[J]:=319 Else
	 If X[J]=319Then X[J]:=0;
	End;
    If RY[J]<>0Then Begin
	 If Y[J]=0Then Y[J]:=MaxYZone Else
	 If Y[J]=MaxYZone Then Y[J]:=0;
	End;
   End;
  Until KeyPressed;
  K:=Byte(ReadKey);
  If K=0Then K:=K or (Byte(ReadKey)shl 8);
  If Chr(K)='2'Then K:=kbDn;
  If Chr(K)='4'Then K:=kbLeft;
  If Chr(K)='6'Then K:=kbRight;
  Case(K)of
   kbUp:If RY[1]=0Then Begin;RY[1]:=-1;RX[1]:=0;End;
   kbDn:If RY[1]=0Then Begin;RY[1]:=1;RX[1]:=0;End;
   kbLeft:If RX[1]=0Then Begin;RY[1]:=0;RX[1]:=-1;End;
   kbRight:If RX[1]=0Then Begin;RY[1]:=0;RX[1]:=1;End;
   kbEsc:HALT;
  End;
 Until FaLse;
End;

BEGIN
 Randomize;
 Play;
END.
