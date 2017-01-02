unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Samples.Spin, AprSpin;

type
  TMainFrm = class(TForm)
    StatusBar: TStatusBar;
    PaintBox: TPaintBox;
    Timer: TTimer;
    DepthRB: TRadioButton;
    IrRB: TRadioButton;
    ColorRB: TRadioButton;
    IrDivisorEdit: TSpinEdit;
    Label1: TLabel;
    MinDEdit: TSpinEdit;
    Label2: TLabel;
    MaxDEdit: TSpinEdit;
    DepthLbl: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure VersionBtnClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure DepthRBClick(Sender: TObject);
    procedure IrRBClick(Sender: TObject);
    procedure ColorRBClick(Sender: TObject);
    procedure MinDEditChange(Sender: TObject);
    procedure MaxDEditChange(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);

  private
    Bmp : TBitmap;
    ColorBmp : TBitmap;
    procedure SetSize;
    function MetreStr(MM: Integer): String;
    procedure ShowMouseDepth;

  public

  end;

var
  MainFrm: TMainFrm;

implementation

{$R *.dfm}

uses
  Kinect2DLL, Kinect2U, BmpUtils;

procedure TMainFrm.FormCreate(Sender: TObject);
begin
  Bmp:=TBitmap.Create;
  Bmp.PixelFormat:=pf24Bit;
  SetSize;

  ColorBmp:=TBitmap.Create;
  ColorBmp.PixelFormat:=pf32Bit;
  ColorBmp.Width:=COLOR_W;
  ColorBmp.Height:=COLOR_H;

  Kinect2:=TKinect2.Create;

  if FileExists(FullDLLName) then begin
    Kinect2.StartUp;
    Kinect2.AbleToStartMultiframe;
    if Kinect2.DllLoaded then begin
      StatusBar.Panels[0].Text:='Library version #'+Kinect2.DLLVersion+' loaded';
      if Kinect2.Ready then begin
        StatusBar.Panels[1].Text:='Kinect ready';

// enable what we have
        DepthRB.Enabled:=Kinect2.AbleToStartDepthStream;
        IrRB.Enabled:=Kinect2.AbleToStartIRStream;
        ColorRB.Enabled:=Kinect2.AbleToStartColorStream;

// select an enabled one
        if DepthRB.Enabled then DepthRB.Checked:=True
        else if IrRB.Enabled then IrRB.Checked:=True
        else if ColorRB.Enabled then ColorRB.Checked:=True;

        if DepthRB.Enabled or IrRB.Enabled or ColorRB.Enabled then begin
          StatusBar.Panels[2].Text:='Started OK';
          Timer.Enabled:=True;
        end
        else StatusBar.Panels[2].Text:='Not started';
      end
      else StatusBar.Panels[1].Text:='Kinect not ready';
    end
    else StatusBar.Panels[0].Text:='Library not loaded';
  end
  else StatusBar.Panels[0].Text:=FullDLLName+' not found';

  MinDEdit.Value:=Kinect2.MinDepth;
  MaxDEdit.Value:=Kinect2.MaxDepth;
end;

procedure TMainFrm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=#13 then Perform(WM_NEXTDLGCTL,0,0);
end;

procedure TMainFrm.IrRBClick(Sender: TObject);
begin
  SetSize;
end;

procedure TMainFrm.ColorRBClick(Sender: TObject);
begin
  SetSize;
end;

procedure TMainFrm.DepthRBClick(Sender: TObject);
begin
  SetSize;
end;

procedure TMainFrm.SetSize;
var
  W,H : Integer;
begin
  if DepthRB.Checked then begin
    W:=DEPTH_W;
    H:=DEPTH_H;
  end
  else if IrRB.Checked then begin
    W:=IR_W;
    H:=IR_H;
  end
  else begin
    W:=COLOR_W;
    H:=COLOR_H;
  end;

  PaintBox.Width:=W;
  PaintBox.Height:=H;

  ClientWidth:=W;
  ClientHeight:=PaintBox.Top+PaintBox.Height+StatusBar.Height;

  Bmp.Width:=W;
  Bmp.Height:=H;

  Left:=(Screen.Width-W) div 2;
  Top:=(Screen.Height-H) div 2;
end;

procedure TMainFrm.MinDEditChange(Sender: TObject);
begin
  Kinect2.MinDepth:=MinDEdit.Value;
end;

procedure TMainFrm.MaxDEditChange(Sender: TObject);
begin
  Kinect2.MaxDepth:=MaxDEdit.Value;
end;

procedure TMainFrm.TimerTimer(Sender: TObject);
begin
// depth
  if DepthRB.Checked then begin
    if Kinect2.AbleToGetDepthFrame then begin
      Kinect2.DrawDepthBmp(Bmp);
      ShowMouseDepth;
      Kinect2.DoneDepth;
      ShowFrameRateOnBmp(Bmp,Kinect2.MeasuredFPS);
      PaintBox.Canvas.Draw(0,0,Bmp);
    end;
  end

// IR
  else if IrRB.Checked then begin
    if Kinect2.AbleToGetIrFrame then begin
      Kinect2.DrawIrBmp(Bmp,Round(IrDivisorEdit.Value));
      Kinect2.DoneIR;
      ShowFrameRateOnBmp(Bmp,Kinect2.MeasuredFPS);
      PaintBox.Canvas.Draw(0,0,Bmp);
    end;
  end

// color
  else if Kinect2.AbleToGetColorFrame then begin
    Kinect2.DrawColorBmp(ColorBmp);
    Kinect2.DoneColor;
    ShowFrameRateOnBmp(ColorBmp,Kinect2.MeasuredFPS);
    PaintBox.Canvas.Draw(0,0,ColorBmp);
  end;
end;

procedure TMainFrm.VersionBtnClick(Sender: TObject);
begin
  Caption:=KinectVersionString;
end;

function TMainFrm.MetreStr(MM:Integer):String;
begin
  Result:=FloatToStrF(MM/1000,ffFixed,9,2);
end;

procedure TMainFrm.ShowMouseDepth;
var
  MousePt    : TPoint;
  PixelColor : TColor;
  XF,YF      : Single;
begin
  GetCursorPos(MousePt);
  MousePt:=PaintBox.ScreenToClient(MousePt);
  if (MousePt.X>=0) and (MousePt.X<DEPTH_W) and
     (MousePt.Y>=0) and (MousePt.Y<DEPTH_H) then
  begin
    DepthLbl.Caption:=MetreStr(Kinect2.DepthAtXY(MousePt.X,MousePt.Y));
  end
  else DepthLbl.Caption:='--.--';
end;

end.
