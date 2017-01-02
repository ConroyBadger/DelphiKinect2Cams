object MainFrm: TMainFrm
  Left = 0
  Top = 0
  Caption = 'Kinect2 Cameras'
  ClientHeight = 486
  ClientWidth = 533
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  OnCreate = FormCreate
  OnKeyPress = FormKeyPress
  PixelsPerInch = 96
  TextHeight = 13
  object PaintBox: TPaintBox
    Left = 10
    Top = 33
    Width = 512
    Height = 424
  end
  object Label1: TLabel
    Left = 126
    Top = 10
    Width = 20
    Height = 13
    Caption = 'Min:'
  end
  object Label2: TLabel
    Left = 217
    Top = 10
    Width = 24
    Height = 13
    Caption = 'Max:'
  end
  object DepthLbl: TLabel
    AlignWithMargins = True
    Left = 57
    Top = 3
    Width = 60
    Height = 25
    Alignment = taCenter
    AutoSize = False
    Caption = '--.--'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 467
    Width = 533
    Height = 19
    Panels = <
      item
        Width = 200
      end
      item
        Width = 150
      end
      item
        Width = 50
      end>
    ExplicitTop = 287
    ExplicitWidth = 340
  end
  object DepthRB: TRadioButton
    Left = 8
    Top = 8
    Width = 49
    Height = 17
    Caption = 'Depth'
    TabOrder = 1
    OnClick = DepthRBClick
  end
  object IrRB: TRadioButton
    Left = 304
    Top = 8
    Width = 98
    Height = 17
    Caption = 'IR -> Divisor ='
    TabOrder = 2
    OnClick = IrRBClick
  end
  object ColorRB: TRadioButton
    Left = 463
    Top = 8
    Width = 57
    Height = 17
    Caption = 'Color'
    TabOrder = 3
    OnClick = ColorRBClick
  end
  object IrDivisorEdit: TSpinEdit
    Left = 400
    Top = 6
    Width = 48
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 4
    Value = 6
  end
  object MinDEdit: TSpinEdit
    Left = 152
    Top = 6
    Width = 48
    Height = 22
    MaxValue = 4096
    MinValue = 0
    TabOrder = 5
    Value = 1
    OnChange = MinDEditChange
  end
  object MaxDEdit: TSpinEdit
    Left = 243
    Top = 6
    Width = 48
    Height = 22
    MaxValue = 4096
    MinValue = 0
    TabOrder = 6
    Value = 1
    OnChange = MaxDEditChange
  end
  object Timer: TTimer
    Enabled = False
    Interval = 20
    OnTimer = TimerTimer
    Left = 32
    Top = 32
  end
end
