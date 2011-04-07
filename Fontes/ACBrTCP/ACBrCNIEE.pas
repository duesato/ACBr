unit ACBrCNIEE;

interface

uses
  {$IFDEF MSWINDOWS} windows, wininet, {$ENDIF}
  Contnrs, Messages, SysUtils, Variants, Classes, httpsend,
  ACBrUtil, ACBrSocket;

type
  EACBrCNIEE = class(Exception);

  TACBrCNIEEExporta = (exCSV, exDSV);

  TRegistro = packed record
    Marca        : string[2];
    Modelo       : string[2];
    Versao       : string[2];
    Tipo         : string[10];
    MarcaDescr   : string[30];
    ModeloDescr  : string[30];
    VersaoSB     : string[20];
    QtLacreSL    : Integer;
    QTLacreFab   : Integer;
    MFD          : string[3];
    LacreMFD     : string[3];
    AtoAprovacao : string[25];
    AtoRegistroMG: string[25];
    FormatoNumero: string[20];
  end;

  TACBrCNIEERegistro = class
  private
    FDescrModelo: String;
    FCodCodModelo: String;
    FAtoAprovacao: String;
    FVersao: String;
    FQtLacresFab: Integer;
    FQtLacresSL: Integer;
    FTemLacreMFD: String;
    FDescrMarca: String;
    FAtoRegistro: String;
    FTemMFD: String;
    FCodMarca: String;
    FCodCodVersao: String;
    FFormatoNumFabricacao: String;
    FTipoECF: String;
  public
    property CodMarca: String read FCodMarca write FCodMarca;
    property CodCodModelo: String read FCodCodModelo write FCodCodModelo;
    property CodCodVersao: String read FCodCodVersao write FCodCodVersao;
    property TipoECF: String read FTipoECF write FTipoECF;
    property DescrMarca: String read FDescrMarca write FDescrMarca;
    property DescrModelo: String read FDescrModelo write FDescrModelo;
    property Versao: String read FVersao write FVersao;
    property TemMFD: String read FTemMFD write FTemMFD;
    property TemLacreMFD: String read FTemLacreMFD write FTemLacreMFD;
    property AtoAprovacao: String read FAtoAprovacao write FAtoAprovacao;
    property AtoRegistro: String read FAtoRegistro write FAtoRegistro;
    property FormatoNumFabricacao: String read FFormatoNumFabricacao write FFormatoNumFabricacao;
    property QtLacresSL: Integer read FQtLacresSL write FQtLacresSL;
    property QtLacresFab: Integer read FQtLacresFab write FQtLacresFab;
  end;

  TACBrCNIEERegistros = class(TObjectList)
  private
    function GetItem(Index: integer): TACBrCNIEERegistro;
    procedure SetItem(Index: integer; const Value: TACBrCNIEERegistro);
  public
    function New: TACBrCNIEERegistro;
    property Items[Index: integer]: TACBrCNIEERegistro read GetItem write SetItem; default;
  end;

  TACBrCNIEE = class(TACBrHTTP)
  private
    FHTTPSend: THTTPSend;
    FArquivo: String;
    FURLDownload: String;
    FCadastros: TACBrCNIEERegistros;
    procedure ExportarCSV(const AArquivo: String);
    procedure ExportarDSV(const AArquivo: String);
  public
    destructor Destroy; override;
    constructor Create(AOwner: TComponent); override;

    function DownloadTabela: Boolean;
    function AbrirTabela: Boolean;
    procedure LerConfiguracoesProxy;
    procedure Exportar(const AArquivo: String; ATipo: TACBrCNIEEExporta);
  published
    property Arquivo: String read FArquivo write FArquivo;
    property URLDownload: String read FURLDownload write FURLDownload;
    property Cadastros: TACBrCNIEERegistros read FCadastros;
  end;

implementation

{ TACBrCNIEERegistros }

function TACBrCNIEERegistros.GetItem(Index: integer): TACBrCNIEERegistro;
begin
  Result := TACBrCNIEERegistro(inherited Items[Index]);
end;

function TACBrCNIEERegistros.New: TACBrCNIEERegistro;
begin
  Result := TACBrCNIEERegistro.Create;
  Add(Result);
end;

procedure TACBrCNIEERegistros.SetItem(Index: integer;
  const Value: TACBrCNIEERegistro);
begin
  Put(Index, Value);
end;

{ TACBrCNIEE }

constructor TACBrCNIEE.Create(AOwner: TComponent);
begin
  inherited;

  FHTTPSend    := THTTPSend.Create;
  FCadastros   := TACBrCNIEERegistros.Create;
  FURLDownload := 'http://www.fazenda.mg.gov.br/empresas/ecf/files/Tabela_CNIEE.bin';

  FHTTPSend.ProxyHost := ProxyHost;
  FHTTPSend.ProxyPort := ProxyPort;
  FHTTPSend.ProxyUser := ProxyUser;
  FHTTPSend.ProxyPass := ProxyPass;
end;

destructor TACBrCNIEE.Destroy;
begin
  FCadastros.Free;
  FHTTPSend.Free;
  inherited;
end;

procedure TACBrCNIEE.LerConfiguracoesProxy;
{$IFDEF MSWINDOWS}
var
  Len: DWORD;
  i, j: Integer;

  Server, Port, User, Password: String;

  function GetProxyServer: String;
  var
     ProxyInfo: PInternetProxyInfo;
  begin
     Result := '';
     Len    := 0;
     if not InternetQueryOption(nil, INTERNET_OPTION_PROXY, nil, Len) then
     begin
        if GetLastError = ERROR_INSUFFICIENT_BUFFER then
        begin
           GetMem(ProxyInfo, Len);
           try
              if InternetQueryOption(nil, INTERNET_OPTION_PROXY, ProxyInfo, Len) then
              begin
                 if ProxyInfo^.dwAccessType = INTERNET_OPEN_TYPE_PROXY then
                    Result := String(ProxyInfo^.lpszProxy);
              end;
           finally
              FreeMem(ProxyInfo);
           end;
        end;
     end;
  end;

  function GetOptionString(Option: DWORD): String;
  begin
     Len := 0;
     if not InternetQueryOption(nil, Option, nil, Len) then
     begin
        if GetLastError = ERROR_INSUFFICIENT_BUFFER then
        begin
           SetLength(Result, Len);
           if InternetQueryOption(nil, Option, Pointer(Result), Len) then
              Exit;
        end;
     end;

     Result := '';
  end;

begin
  Port     := '';
  Server   := GetProxyServer;
  User     := GetOptionString(INTERNET_OPTION_PROXY_USERNAME);
  Password := GetOptionString(INTERNET_OPTION_PROXY_PASSWORD);

  if Server <> '' then
  begin
     i := Pos('http=', Server);
     if i > 0 then
     begin
        Delete(Server, 1, i+5);
        j := Pos(';', Server);
        if j > 0 then
           Server := Copy(Server, 1, j-1);
     end;

     i := Pos(':', Server);
     if i > 0 then
     begin
        Port   := Copy(Server, i+1, MaxInt);
        Server := Copy(Server, 1, i-1);
     end;
  end;

  ProxyHost := Server;
  ProxyPort := Port;
  ProxyUser := User;
  ProxyPass := Password;
end;
{$ELSE}
Var
  Arroba, DoisPontos, Barras : Integer ;
  http_proxy : String ;
begin
{ http_proxy=http://user:password@proxy:port/
  http_proxy=http://proxy:port/                    }

  http_proxy := Trim(GetEnvironmentVariable( 'http_proxy' )) ;
  if http_proxy = '' then exit ;

  if RightStr(http_proxy,1) = '/' then
     http_proxy := copy( http_proxy, 1, Length(http_proxy)-1 );

  Barras := pos('//', http_proxy);
  if Barras > 0 then
     http_proxy := copy( http_proxy, Barras+2, Length(http_proxy) ) ;

  Arroba     := pos('@', http_proxy) ;
  DoisPontos := pos(':', http_proxy) ;

  if (Arroba > 0) then
  begin
     if (DoisPontos < Arroba) then
        Pass := copy( http_proxy, DoisPontos+1, Arroba-DoisPontos-1 )
     else
        DoisPontos := Arroba;

     User := copy( http_proxy, 1, DoisPontos-1) ;

     http_proxy := copy( http_proxy, Arroba+1, Length(http_proxy) );
  end ;

  DoisPontos := pos(':', http_proxy+':') ;

  Server := copy( http_proxy, 1, DoisPontos-1) ;
  Port   := copy( http_proxy, DoisPontos+1, Length(http_proxy) );

  Proxy.Server   := Server;
  Proxy.Port     := Port;
  Proxy.User     := User;
  Proxy.Password := Password;
end ;
{$ENDIF}

function TACBrCNIEE.DownloadTabela: Boolean;
var
  OK: Boolean;
begin
  if Trim(FURLDownload) = '' then
    raise EACBrCNIEE.Create('URL de Download n�o informada.');

  if Trim(FArquivo) = '' then
    raise EACBrCNIEE.Create('Nome do arquivo em disco n�o especificado.');

  with FHTTPSend do
  begin
    Clear;
    OK := HTTPMethod('GET', FURLDownload);
    if OK and (ResultCode = 200) then
    begin
      Document.Seek(0, soFromBeginning);
      Document.SaveToFile(FArquivo);
      Result := True;
    end
    else
      Result := False;
  end;
end;

function TACBrCNIEE.AbrirTabela: Boolean;
var
  F: file of TRegistro;
  Registro: TRegistro;
  FileName: String;

  function ReplaceString(const AString: string;
    const ANovo: string; const AAntigo: array of string;
    const AOpcoes: TReplaceFlags): string;
  var
    I: Integer;
  begin
    Result := AString;
    for I := 0 to High(AAntigo) do
      Result := StringReplace(Result, AAntigo[I], ANovo, AOpcoes);
  end;

begin
  FileName := Trim(FArquivo);

  if FileName = '' then
    raise Exception.Create('Nome do arquivo em Disco n�o especificado.');

  if not FileExists(FileName) then
    raise Exception.Create('Arquivo n�o encontrado:' + sLineBreak + FileName);

  FCadastros.Clear;
  AssignFile(F, Filename);
  try
    Reset(F);
    while not Eof(F) do
    begin
      Read(F, Registro);

      with FCadastros.New do
      begin
        CodMarca             := Trim(string(Registro.Marca));
        CodCodModelo         := Trim(string(Registro.Modelo));
        CodCodVersao         := Trim(string(Registro.Versao));
        TipoECF              := Trim(string(Registro.Tipo));
        DescrMarca           := Trim(string(Registro.MarcaDescr));
        DescrModelo          := Trim(string(Registro.ModeloDescr));
        Versao               := Trim(string(Registro.VersaoSB));
        QtLacresSL           := Registro.QtLacreSL;
        QtLacresFab          := Registro.QTLacreFab;
        TemMFD               := Trim(string(Registro.MFD));
        TemLacreMFD          := Trim(string(Registro.LacreMFD));
        AtoAprovacao         := Trim(string(Registro.AtoAprovacao));
        AtoRegistro          := Trim(string(Registro.AtoRegistroMG));
        FormatoNumFabricacao := Trim(string(Registro.FormatoNumero));
      end;
    end;
    Result := True;
  finally
    CloseFile(F);
  end;
end;

procedure TACBrCNIEE.Exportar(const AArquivo: String; ATipo: TACBrCNIEEExporta);
begin
  if Cadastros.Count <= 0 then
    Self.AbrirTabela;

  case ATipo of
    exCSV: ExportarCSV(AArquivo);
    exDSV: ExportarDSV(AArquivo);
  end;
end;

procedure TACBrCNIEE.ExportarCSV(const AArquivo: String);
var
  I: Integer;
  Texto: String;
begin
  Texto := '';
  for I := 0 to Cadastros.Count - 1 do
  begin
    Texto := Texto +
      Cadastros[I].CodMarca + ',' +
      Cadastros[I].CodCodModelo + ',' +
      Cadastros[I].CodCodVersao + ',' +
      Cadastros[I].TipoECF + ',' +
      Cadastros[I].DescrMarca + ',' +
      Cadastros[I].DescrModelo + ',' +
      Cadastros[I].Versao + ',' +
      IntToStr(Cadastros[I].QtLacresSL) + ',' +
      IntToStr(Cadastros[I].QtLacresFab) + ',' +
      Cadastros[I].TemMFD + ',' +
      Cadastros[I].TemLacreMFD + ',' +
      Cadastros[I].AtoAprovacao + ',' +
      Cadastros[I].AtoRegistro + ',' +
      Cadastros[I].FormatoNumFabricacao + ',' +
      sLineBreak;
  end;

  if Trim(Texto) <> '' then
    WriteToTXT(AnsiString(AArquivo), AnsiString(Texto), False, True);
end;

procedure TACBrCNIEE.ExportarDSV(const AArquivo: String);
var
  I: Integer;
  Texto: String;

  function AddAspasDuplas(const ATexto: String): String;
  begin
    Result := '"' + ATexto + '"';
  end;

begin
  Texto := '';
  for I := 0 to Cadastros.Count - 1 do
  begin
    Texto := Texto +
      AddAspasDuplas(Cadastros[I].CodMarca) + ',' +
      AddAspasDuplas(Cadastros[I].CodCodModelo) + ',' +
      AddAspasDuplas(Cadastros[I].CodCodVersao) + ',' +
      AddAspasDuplas(Cadastros[I].TipoECF) + ',' +
      AddAspasDuplas(Cadastros[I].DescrMarca) + ',' +
      AddAspasDuplas(Cadastros[I].DescrModelo) + ',' +
      AddAspasDuplas(Cadastros[I].Versao) + ',' +
      AddAspasDuplas(IntToStr(Cadastros[I].QtLacresSL)) + ',' +
      AddAspasDuplas(IntToStr(Cadastros[I].QtLacresFab)) + ',' +
      AddAspasDuplas(Cadastros[I].TemMFD) + ',' +
      AddAspasDuplas(Cadastros[I].TemLacreMFD) + ',' +
      AddAspasDuplas(Cadastros[I].AtoAprovacao) + ',' +
      AddAspasDuplas(Cadastros[I].AtoRegistro) + ',' +
      AddAspasDuplas(Cadastros[I].FormatoNumFabricacao) + ',' +
      sLineBreak;
  end;

  if Trim(Texto) <> '' then
    WriteToTXT(AnsiString(AArquivo), AnsiString(Texto), False, True);
end;

end.
