[Setup]
AppName=InvoiceApp
AppVersion=1.0.0
DefaultDirName={pf}\InvoiceApp
DefaultGroupName=InvoiceApp
OutputDir=Output
OutputBaseFilename=InvoiceAppSetup
Compression=lzma
SolidCompression=yes

[Files]
Source: "build\windows\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\InvoiceApp"; Filename: "{app}\invoiceapp.exe"
Name: "{commondesktop}\InvoiceApp"; Filename: "{app}\invoiceapp.exe"
