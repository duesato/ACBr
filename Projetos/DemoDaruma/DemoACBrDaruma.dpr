program DemoACBrDaruma;

uses
  Forms,
  uPrincipal in 'uPrincipal.pas' {frmPrincipal},
  uBasicoModal in 'uBasicoModal.pas' {frmBasicoModal},
  uGeracaoArquivos in 'uGeracaoArquivos.pas' {frmGeracaoArquivos},
  uIdentificacaoPafECF in 'uIdentificacaoPafECF.pas' {frmIdentificacaoPafECF},
  uProgramarBitmap in 'uProgramarBitmap.pas' {frmProgramarBitmap},
  uSuprimento in 'uSuprimento.pas' {frmSuprimento},
  uSangria in 'uSangria.pas' {frmSangria},
  uRelatorioGerencial in 'uRelatorioGerencial.pas' {frmRelatorioGerencial},
  uComprNaoFiscalCompleto in 'uComprNaoFiscalCompleto.pas' {frmComprNaoFiscalCompleto},
  uComprNaoFiscal in 'uComprNaoFiscal.pas' {frmComprNaoFiscal},
  uCupomFiscal in 'uCupomFiscal.pas' {frmCupomFiscal},
  uCupomFiscalCancelParcial in 'uCupomFiscalCancelParcial.pas' {frmCupomFiscalCancelParcial},
  uCupomFiscalDescAcresAnterior in 'uCupomFiscalDescAcresAnterior.pas' {frmCupomFiscalDescAcresAnterior},
  uRelatorioGerencialFormatado in 'uRelatorioGerencialFormatado.pas' {frmRelatorioGerencialFormatado},
  uLeituraXArquivo in 'uLeituraXArquivo.pas' {frmLeituraXArquivo};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
