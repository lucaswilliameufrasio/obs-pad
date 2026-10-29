// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'OBS Pad Desktop';

  @override
  String get appSubtitle =>
      'Deixe este app aberto enquanto usa o OBS Pad no celular. Ele ajuda o celular a achar este computador e recebe os sons que você mandar.';

  @override
  String get obsSection => 'OBS neste computador';

  @override
  String get obsNotFound =>
      'Não encontrei as configurações do OBS. Abra o OBS uma vez (versão 28 ou mais nova), feche e volte aqui.';

  @override
  String get obsRunning => 'O OBS está aberto';

  @override
  String get obsClosed => 'O OBS está fechado';

  @override
  String phoneControlOn(int port) {
    return 'Controle pelo celular ligado (porta $port, com senha)';
  }

  @override
  String get phoneControlOff => 'Controle pelo celular desligado';

  @override
  String get phoneControlNoPassword =>
      'Controle pelo celular ligado, mas sem senha';

  @override
  String get enableButton => 'Ligar o controle pelo celular';

  @override
  String get enableNeedsClosedObs =>
      'Feche o OBS antes: ele desfaz essa mudança quando fecha. Depois aperte o botão.';

  @override
  String get enableExplain =>
      'Isso liga o servidor WebSocket do OBS com uma senha — o mesmo que fazer no OBS em Ferramentas › Configurações do Servidor WebSocket.';

  @override
  String get enableDone =>
      'Pronto! Abra o OBS de novo e conecte o celular aqui embaixo.';

  @override
  String get enableFailed =>
      'Não consegui mudar as configurações do OBS. Faça no OBS: Ferramentas › Configurações do Servidor WebSocket › Ativar, com senha.';

  @override
  String get connectSection => 'Conectar o celular';

  @override
  String get connectHowTo =>
      'No OBS Pad do celular, toque em \"Ler QR code\" e aponte a câmera para cá. Ou toque em \"Procurar na rede\".';

  @override
  String get showQr => 'Mostrar QR code';

  @override
  String get hideQr => 'Esconder QR code';

  @override
  String get qrWarning =>
      'O QR code tem a senha do OBS. Só mostre para quem você confia.';

  @override
  String get addressLabel => 'IP do computador';

  @override
  String addressVpn(String ip) {
    return '$ip (VPN, funciona fora de casa)';
  }

  @override
  String get noAddress =>
      'Nenhuma rede encontrada. Conecte este computador ao Wi-Fi ou cabo.';

  @override
  String get portLabel => 'Porta';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get showPassword => 'Mostrar';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => 'Copiado';

  @override
  String get soundsSection => 'Sons';

  @override
  String get soundsFolder => 'Os sons enviados pelo celular ficam em:';

  @override
  String soundsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sons',
      one: '1 som',
      zero: 'Nenhum som ainda',
    );
    return '$_temp0';
  }

  @override
  String get openFolder => 'Abrir pasta';

  @override
  String get firewallSection => 'Firewall do Windows';

  @override
  String get firewallExplain =>
      'Se o celular não encontra ou não conecta neste computador, libere o OBS e o OBS Pad em redes privadas. O Windows vai pedir permissão.';

  @override
  String get firewallButton => 'Liberar no firewall';

  @override
  String get firewallDone =>
      'Pronto. Confira também se o Wi-Fi está como rede Privada.';

  @override
  String get firewallFailed =>
      'Não foi liberado. Tente de novo e responda \"Sim\" no aviso do Windows.';

  @override
  String get serverFailed =>
      'Outro programa está usando a porta 4457 (talvez o OBS Pad Desktop já esteja aberto). O celular não vai achar este computador nem mandar sons até você fechá-lo.';

  @override
  String get activitySection => 'O que o celular fez';

  @override
  String get activityEmpty => 'Nada ainda.';

  @override
  String activityDiscovered(String ip) {
    return 'Um celular achou este computador ($ip)';
  }

  @override
  String get activityListed => 'O celular abriu a lista de sons';

  @override
  String activityUploaded(String name) {
    return 'Recebi \"$name\"';
  }

  @override
  String activityRejected(String ip) {
    return 'Recusei um pedido de $ip: a senha do OBS no celular é diferente';
  }

  @override
  String activityRejectedOther(String ip, String reason) {
    return 'Recusei um pedido de $ip ($reason)';
  }
}
