unit Kinect2U;

interface

uses
  Windows, Kinect2DLL, Graphics, SysUtils, Classes;

type
  TByteTable = array[0..High(TDepthFrameData)] of Byte;

  TKinect2 = class(TObject)
  private
    ByteTable : TByteTable;

    FrameRateFrame : Integer;

    DepthData : PDepthFrameData;
    IRData    : PIRFrameData;
    ColorData : PColorFrameData;

    procedure BuildByteTable;

    procedure SetMinDepth(V:TDepthFrameData);
    procedure SetMaxDepth(V:TDepthFrameData);

  public
    FMinDepth : TDepthFrameData;
    FMaxDepth : TDepthFrameData;

    DepthBmp  : TBitmap;
    RGBOffset : Integer;

    DllLoaded : Boolean;
    Ready     : Boolean;

    FrameCount  : Integer;
    MeasuredFPS : Single;
    LastFrameRateTime : DWord;

    property MinDepth:TDepthFrameData read FMinDepth write SetMinDepth;
    property MaxDepth:TDepthFrameData read FMaxDepth write SetMaxDepth;

    constructor Create;
    destructor Destroy; override;

    function DLLVersion:String;

    procedure StartUp;
    procedure ShutDown;

// depth
    function  AbleToStartDepthStream:Boolean;
    function  AbleToGetDepthFrame:Boolean;
    procedure DoneDepth;

// IR
    function  AbleToStartIRStream:Boolean;
    function  AbleToGetIRFrame:Boolean;
    procedure DoneIR;

// color
    function  AbleToStartColorStream:Boolean;
    function  AbleToGetColorFrame:Boolean;
    procedure DoneColor;

// body
    function  AbleToStartBodyStream:Boolean;
    function  AbleToUpdateBody:Boolean;
    procedure DoneBody;

// multiframe
    function  AbleToStartMultiFrame:Boolean;
    function  AbleToUpdateMultiFrame:Boolean;
    procedure DoneMultiFrame;

    procedure DrawDepthBmp(Bmp:TBitmap);
    procedure DrawIRBmp(Bmp:TBitmap;Divisor:Integer);
    procedure DrawColorBmp(Bmp:TBitmap);

    procedure MeasureFrameRate;

    function DepthAtXY(X,Y:Integer):Integer;
  end;

var
  Kinect2 : TKinect2;

implementation

uses
  BmpUtils;

const
  FrameRateAverages  = 10;

constructor TKinect2.Create;
begin
  DepthBmp:=TBitmap.Create;
  DepthBmp.Width:=DEPTH_W;
  DepthBmp.Height:=DEPTH_H;
  DepthBmp.PixelFormat:=pf24Bit;
  ClearBmp(DepthBmp,clBlack);

  DllLoaded:=False;
  Ready:=False;

  FMinDepth:=1;
  FMaxDepth:=1000;
  BuildByteTable;

  RGBOffset:=0;

  FrameCount:=0;
  FrameRateFrame:=0;

  DepthData:=nil;
  IRData:=nil;
  ColorData:=nil;

  MeasuredFPS:=0;
  LastFrameRateTime:=GetTickCount;
end;

destructor TKinect2.Destroy;
begin
  if Assigned(DepthBmp) then DepthBmp.Free;
end;

function TKinect2.DLLVersion:String;
begin
  Result:=KinectVersionString;
end;

procedure TKinect2.StartUp;
begin
  if AbleToLoadKinectLibrary then begin
    DllLoaded:=True;
    Ready:=AbleToStartUpKinect2;
  end;
end;

procedure TKinect2.ShutDown;
begin
  if Ready then begin
    ShutDownKinect2;
    Ready:=False;
  end;

  UnloadKinectLibrary;
end;

procedure TKinect2.MeasureFrameRate;
var
  Time    : DWord;
  Elapsed : Single;
begin
  Inc(FrameCount);

// average it out a bit so it's readable
  if (FrameCount-FrameRateFrame)>=FrameRateAverages then begin
    Time:=GetTickCount;
    Elapsed:=(Time-LastFrameRateTime)/1000;
    if Elapsed=0 then MeasuredFPS:=999
    else MeasuredFPS:=FrameRateAverages/Elapsed;

    LastFrameRateTime:=Time;
    FrameRateFrame:=FrameCount;
  end;
end;

function TKinect2.AbleToStartDepthStream:Boolean;
begin
  Result:=AbleToStartDepth;
end;

function TKinect2.AbleToGetDepthFrame: Boolean;
begin
  DepthData:=GetDepthFrame;

  if Assigned(DepthData) then begin
    MeasureFrameRate;
    Result:=True;
  end
  else Result:=False;

// we need to call this either way
end;

procedure TKinect2.DoneDepth;
begin
  DoneDepthFrame;
end;

function TKinect2.AbleToStartIRStream:Boolean;
begin
  Result:=AbleToStartIR;
end;

function TKinect2.AbleToGetIRFrame: Boolean;
begin
  IRData:=GetIRFrame;

  if Assigned(IRData) then begin
    MeasureFrameRate;
    Result:=True;
  end
  else Result:=False;
end;

procedure TKinect2.DoneIR;
begin
  DoneIRFrame;
end;

function TKinect2.AbleToStartColorStream:Boolean;
begin
  Result:=AbleToStartColor;
end;

function TKinect2.AbleToGetColorFrame: Boolean;
begin
  ColorData:=GetColorFrame;

  if Assigned(ColorData) then begin
    MeasureFrameRate;
    Result:=True;
  end
  else Result:=False;
end;

procedure TKinect2.DoneColor;
begin
  DoneColorFrame;
end;

function TKinect2.AbleToStartMultiFrame:Boolean;
begin
  Result:=Kinect2DLL.AbleToStartMultiFrame;
end;

function TKinect2.AbleToUpdateMultiFrame: Boolean;
begin
  Result:=Kinect2DLL.AbleToUpdateMultiFrame;
  if Result then MeasureFrameRate;
end;

procedure TKinect2.DoneMultiFrame;
begin
  Kinect2DLL.DoneMultiFrame;
end;

function TKinect2.AbleToStartBodyStream:Boolean;
begin
  Result:=Kinect2DLL.AbleToStartBody;
end;

function TKinect2.AbleToUpdateBody:Boolean;
begin
  Result:=Kinect2DLL.AbleToUpdateBodyFrame;
  if Result then begin
    Kinect2DLL.DoneBodyFrame;
  end;
end;

procedure TKinect2.DoneBody;
begin
  Kinect2DLL.DoneBodyFrame;
end;

procedure TKinect2.SetMinDepth(V:TDepthFrameData);
begin
  FMinDepth:=V;
  BuildByteTable;
end;

procedure TKinect2.SetMaxDepth(V:TDepthFrameData);
begin
  FMaxDepth:=V;
  BuildByteTable;
end;

procedure TKinect2.BuildByteTable;
var
  I : TDepthFrameData;
  F : Single;
  V : Byte;
begin
  for I:=0 to High(TDepthFrameData) do begin
    if I<FMinDepth then V:=0
    else if I>FMaxDepth then V:=0
    else begin
      if FMaxDepth>FMinDepth then F:=(I-FMinDepth)/(FMaxDepth-FMinDepth)
      else F:=I-MinDepth; // whoopsies :)
      V:=Round(F*255);
    end;
    ByteTable[I]:=V;
  end;
end;

procedure TKinect2.DrawDepthBmp(Bmp:TBitmap);
var
  Data : PDepthFrameData;
  Line : PByteArray;
  X,Y  : Integer;
begin
  Data:=DepthData;
  for Y:=0 to DEPTH_H-1 do begin
    Line:=Bmp.ScanLine[Y];
    for X:=0 to DEPTH_W-1 do begin
      Line^[X*3+0]:=ByteTable[Data^];
      Line^[X*3+1]:=ByteTable[Data^];
      Line^[X*3+2]:=ByteTable[Data^];
      Inc(Data);
    end;
  end;
end;

procedure TKinect2.DrawIRBmp(Bmp:TBitmap;Divisor:Integer);
var
  Data : PIRFrameData;
  Line : PByteArray;
  X,Y  : Integer;
begin
  Data:=IRData;
  for Y:=0 to DEPTH_H-1 do begin
    Line:=Bmp.ScanLine[Y];
    for X:=0 to DEPTH_W-1 do begin
      Line^[X*3+0]:=0;
      Line^[X*3+1]:=((Data^ shr Divisor) and $FF);
      Line^[X*3+2]:=0;
      Inc(Data);
    end;
  end;
end;

procedure TKinect2.DrawColorBmp(Bmp:TBitmap);
var
  Data : PColorFrameData;
  Line : PByteArray;
  X,Y  : Integer;
  BPR  : Integer;
begin
  Assert(Bmp.PixelFormat=pf32Bit,'');

 // ColorData:=GetColorData;

  BPR:=COLOR_W*COLOR_BPP;
  Data:=ColorData;
  for Y:=0 to COLOR_H-1 do begin
    Line:=Bmp.ScanLine[Y];
    Move(Data^,Line^,BPR);
    Inc(Data,BPR);
  end;
end;

function TKinect2.DepthAtXY(X,Y:Integer):Integer;
var
  DepthPtr  : PWord;
  XM,Offset : Integer;
begin
  if Assigned(DepthData) then begin
    DepthPtr:=DepthData;

// X is mirrored
    XM:=(DEPTH_W-1)-X;

// find the offset
    Offset:=Y*DEPTH_W+X;//M;

// read the value - in mm - convert to metres
    Inc(DepthPtr,Offset);
    Result:=DepthPtr^;
  end
  else Result:=0;
end;

end.


