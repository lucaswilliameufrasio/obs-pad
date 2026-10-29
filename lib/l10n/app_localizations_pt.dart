// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'OBS Pad';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get delete => 'Apagar';

  @override
  String get edit => 'Editar';

  @override
  String get retry => 'Tentar de novo';

  @override
  String get close => 'Fechar';

  @override
  String get next => 'Próximo';

  @override
  String get back => 'Voltar';

  @override
  String get done => 'Concluir';

  @override
  String get details => 'Detalhes técnicos';

  @override
  String get add => 'Adicionar';

  @override
  String get navPad => 'Botões';

  @override
  String get navMixer => 'Mixer';

  @override
  String get navSounds => 'Sons';

  @override
  String get navMetrics => 'Métricas';

  @override
  String get menuProfiles => 'Computadores salvos';

  @override
  String get menuRemote => 'Acessar de fora de casa';

  @override
  String get menuSettings => 'Configurações';

  @override
  String get menuGuide => 'Guia de configuração';

  @override
  String stepOf(int current, int total) {
    return 'Passo $current de $total';
  }

  @override
  String get onbStep1Title => 'Abra o OBS no computador';

  @override
  String get onbStep1Body =>
      'Use o OBS Studio versão 28 ou mais nova. Ele já vem com tudo que o OBS Pad precisa — não tem nada para instalar no PC.';

  @override
  String get onbStep1Hint =>
      'Não sabe a versão? No OBS, clique em Ajuda > Sobre.';

  @override
  String get onbStep2Title => 'Ligue o controle remoto do OBS';

  @override
  String get onbStep2a => 'No OBS, clique no menu Ferramentas';

  @override
  String get onbStep2b => 'Escolha Configurações do Servidor WebSocket';

  @override
  String get onbStep2c => 'Marque \"Ativar servidor WebSocket\"';

  @override
  String get onbStep2d => 'Marque \"Ativar autenticação\" e crie uma senha';

  @override
  String get onbStep2e => 'Deixe a porta 4455 e clique em OK';

  @override
  String get onbStep2Hint =>
      'Dica: o botão \"Mostrar informações de conexão\" mostra o IP do PC e a senha.';

  @override
  String get onbStep3Title => 'Mesmo Wi-Fi';

  @override
  String get onbStep3Body =>
      'Seu PC e seu celular precisam estar na mesma rede Wi-Fi (o mesmo roteador). Os dados móveis não funcionam aqui.';

  @override
  String get onbFindIp => 'Como achar o IP do PC';

  @override
  String get onbIpWindows =>
      'Windows: aperte Windows + R, digite cmd e aperte Enter. Na janela preta, digite ipconfig e aperte Enter. Procure \"Endereço IPv4\" (ex.: 192.168.0.15).';

  @override
  String get onbIpMac =>
      'Mac: abra Ajustes do Sistema > Rede, clique na sua conexão Wi-Fi e veja o \"Endereço IP\".';

  @override
  String get onbIpLinux => 'Linux: abra um terminal e rode hostname -I.';

  @override
  String get onbStep4Title => 'Testar conexão';

  @override
  String get onbStep4Body =>
      'Digite os dados que você viu no OBS e toque no botão.';

  @override
  String get fieldProfileName => 'Nome deste computador';

  @override
  String get defaultProfileName => 'Meu PC';

  @override
  String get fieldHost => 'IP do computador';

  @override
  String get fieldHostHint => 'ex.: 192.168.0.15';

  @override
  String get fieldPort => 'Porta';

  @override
  String get fieldPassword => 'Senha do WebSocket';

  @override
  String get fieldPasswordHint =>
      'Deixe vazio se você não ativou a autenticação';

  @override
  String get showPassword => 'Mostrar senha';

  @override
  String get testConnection => 'Testar conexão';

  @override
  String get testing => 'Testando…';

  @override
  String testSuccess(String version) {
    return 'Tudo certo! Conectado ao OBS $version.';
  }

  @override
  String testOldObs(String version) {
    return 'O OBS $version é antigo. Algumas funções podem não funcionar; atualize para a 28 ou mais nova.';
  }

  @override
  String get onbSoundTipTitle => 'Dica sobre sons';

  @override
  String get onbSoundTip =>
      'Um som só sai na live se a fonte dele estiver na cena que está no ar. Ao adicionar sons pelo OBS Pad, deixe marcado \"Adicionar em todas as cenas\" — ou coloque os sons numa cena só e adicione essa cena como fonte nas outras.';

  @override
  String get errHostEmpty => 'Digite o IP do computador';

  @override
  String get errHostScheme => 'Digite só o IP, sem ws://';

  @override
  String get errHostPort => 'Coloque a porta no campo Porta, não junto do IP';

  @override
  String get errHostInvalid =>
      'Esse IP não parece certo. Exemplo: 192.168.0.15';

  @override
  String get errPort => 'Porta inválida (normalmente 4455)';

  @override
  String get errNameEmpty => 'Dê um nome';

  @override
  String get failWrongPasswordTitle => 'Senha errada';

  @override
  String get failWrongPasswordHint =>
      'A senha não confere com a do OBS. Confira em Ferramentas > Configurações do Servidor WebSocket > Mostrar informações de conexão.';

  @override
  String get failServerOffTitle => 'O OBS não respondeu';

  @override
  String get failServerOffHint =>
      'O computador foi encontrado, mas o servidor WebSocket parece desligado. Abra o OBS e confira se \"Ativar servidor WebSocket\" está marcado e se a porta é 4455.';

  @override
  String get failTimeoutTitle => 'Não consegui chegar ao computador';

  @override
  String get failTimeoutHint =>
      'Confira se o IP está certo e se os dois estão no mesmo Wi-Fi. No Windows, o Firewall pode estar bloqueando a porta 4455.';

  @override
  String get failUnreachableTitle => 'Rede diferente';

  @override
  String get failUnreachableHint =>
      'O celular não consegue ver esse endereço. Confira se ele está no mesmo Wi-Fi do PC (e não nos dados móveis).';

  @override
  String get failInvalidAddressTitle => 'Endereço inválido';

  @override
  String get failInvalidAddressHint =>
      'Não encontrei esse endereço. Digite o IP no formato 192.168.0.15.';

  @override
  String get failNotObsTitle => 'Isso não parece o OBS';

  @override
  String get failNotObsHint =>
      'Algo respondeu nessa porta, mas não é o OBS WebSocket. Confira a porta (padrão 4455).';

  @override
  String get failUnsupportedTitle => 'OBS muito antigo';

  @override
  String get failUnsupportedHint => 'Atualize para o OBS 28 ou mais novo.';

  @override
  String get failNotConnectedTitle => 'Sem conexão com o OBS';

  @override
  String get failNotConnectedHint =>
      'Aguarde reconectar ou toque em Tentar agora.';

  @override
  String failNotFoundNamed(String name) {
    return 'Não encontrei \"$name\" no OBS';
  }

  @override
  String get failNotFound => 'Item não encontrado no OBS';

  @override
  String get failNotFoundHint =>
      'Pode ter sido renomeado ou apagado no OBS. Edite o botão e escolha de novo.';

  @override
  String get failAlreadyExists => 'Já existe algo com esse nome no OBS.';

  @override
  String get failOutputActive => 'Já está rodando.';

  @override
  String get failOutputNotActive => 'Não está rodando.';

  @override
  String get failOutputDisabledTitle => 'Recurso desligado no OBS';

  @override
  String get failOutputDisabledHint =>
      'Ative em Configurações > Saída no OBS (ex.: Replay Buffer).';

  @override
  String failInvalidStateNamed(String name) {
    return 'O OBS não pode fazer isso com \"$name\" agora.';
  }

  @override
  String get failInvalidState => 'O OBS não pode fazer isso agora.';

  @override
  String get failInvalidInputKind => 'Seu OBS não tem esse tipo de fonte.';

  @override
  String get failRequestFailed => 'O OBS não conseguiu fazer isso.';

  @override
  String get failUnknown => 'Algo deu errado.';

  @override
  String get firewallHelpTitle => 'Como liberar o OBS no Firewall do Windows';

  @override
  String get firewallHelpBody =>
      'Abra o menu Iniciar e procure \"Permitir um aplicativo pelo Firewall do Windows\". Clique em \"Alterar configurações\", encontre \"OBS Studio\" e marque \"Privada\". Se não aparecer, clique em \"Permitir outro aplicativo\" e escolha o obs64.exe. Confira também se o seu Wi-Fi está como rede Privada.';

  @override
  String get statusConnecting => 'Conectando ao OBS…';

  @override
  String statusReconnecting(int seconds, int attempt) {
    return 'Conexão perdida. Tentando de novo em ${seconds}s (tentativa $attempt)';
  }

  @override
  String statusFailed(String reason) {
    return 'Não foi possível conectar: $reason';
  }

  @override
  String get statusDisconnected => 'Desconectado do OBS';

  @override
  String get statusConnected => 'Conectado';

  @override
  String get tryNow => 'Tentar agora';

  @override
  String get connect => 'Conectar';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get profilesTitle => 'Computadores salvos';

  @override
  String get profilesEmpty => 'Nenhum computador salvo ainda.';

  @override
  String get addProfile => 'Adicionar computador';

  @override
  String get editProfile => 'Editar computador';

  @override
  String deleteProfileConfirm(String name) {
    return 'Apagar \"$name\"?';
  }

  @override
  String get profileInUse => 'Em uso';

  @override
  String get saveWithoutTest => 'Salvar sem testar';

  @override
  String get testAndSave => 'Testar e salvar';

  @override
  String get scenesTitle => 'Cenas';

  @override
  String get scenesEmpty => 'Nenhuma cena encontrada no OBS.';

  @override
  String get onAir => 'No ar';

  @override
  String sceneSwitched(String name) {
    return 'Cena: $name';
  }

  @override
  String get remoteTitle => 'Acessar de fora de casa';

  @override
  String get remoteIntro =>
      'Quer controlar o OBS quando o celular não está no mesmo Wi-Fi (por exemplo, no 4G)? Use um app grátis de rede privada (VPN) como o Tailscale ou o NetBird. Ele liga seu celular e seu PC com segurança, como se estivessem em casa.';

  @override
  String get remoteWarningTitle => 'Nunca abra a porta 4455 no roteador';

  @override
  String get remoteWarning =>
      'NÃO use \"redirecionamento de portas\" para expor a porta 4455 na internet. Qualquer pessoa poderia tentar adivinhar sua senha e controlar seu OBS e sua live.';

  @override
  String get remoteOptionTailscale => 'Opção 1: Tailscale';

  @override
  String get remoteOptionNetbird => 'Opção 2: NetBird';

  @override
  String remoteStep1(String site) {
    return 'Crie uma conta grátis em $site';
  }

  @override
  String remoteStep2(String app) {
    return 'Instale o $app no PC (onde está o OBS) e entre com a conta';
  }

  @override
  String remoteStep3(String app) {
    return 'Instale o app $app no celular e entre com a mesma conta';
  }

  @override
  String remoteStep4(String app) {
    return 'No PC, abra o $app e copie o IP dele (começa com 100.)';
  }

  @override
  String get remoteStep5 =>
      'No OBS Pad, adicione um computador novo usando esse IP 100.x.x.x, com a mesma porta e senha';

  @override
  String get remoteFootnote =>
      'Deixe a VPN ligada no PC e no celular enquanto estiver usando.';

  @override
  String get remoteAddProfile => 'Adicionar computador com IP da VPN';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Igual ao celular';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSystem => 'Igual ao celular';

  @override
  String get settingsKeepScreenOn => 'Manter a tela ligada';

  @override
  String get settingsKeepScreenOnHint =>
      'A tela do celular não apaga enquanto o OBS Pad estiver aberto. Se a tela apagar ou você trocar de app, o celular corta a conexão com o OBS: macros em andamento e alertas param até você voltar.';

  @override
  String get settingsHaptics => 'Vibrar ao tocar';

  @override
  String get settingsGuide => 'Ver o guia de configuração de novo';

  @override
  String get obsMockTitle => 'Configurações do Servidor WebSocket';

  @override
  String get obsMockEnableServer => 'Ativar servidor WebSocket';

  @override
  String get obsMockEnableAuth => 'Ativar autenticação';

  @override
  String get obsMockPort => 'Porta do servidor';

  @override
  String get actionSwitchScene => 'Trocar de cena';

  @override
  String get actionToggleSource => 'Mostrar/ocultar fonte';

  @override
  String get actionToggleMute => 'Mutar/desmutar áudio';

  @override
  String get actionToggleStream => 'Iniciar/parar live';

  @override
  String get actionStartStream => 'Iniciar live';

  @override
  String get actionStopStream => 'Parar live';

  @override
  String get actionToggleRecord => 'Iniciar/parar gravação';

  @override
  String get actionStartRecord => 'Iniciar gravação';

  @override
  String get actionStopRecord => 'Parar gravação';

  @override
  String get actionToggleRecordPause => 'Pausar/continuar gravação';

  @override
  String get actionSaveReplay => 'Salvar replay';

  @override
  String get actionHotkey => 'Atalho do OBS';

  @override
  String get actionMacro => 'Macro (várias ações)';

  @override
  String get addButton => 'Adicionar botão';

  @override
  String get editButton => 'Editar botão';

  @override
  String get editButtons => 'Editar botões';

  @override
  String get doneEditing => 'Terminar edição';

  @override
  String get editModeHint =>
      'Segure e arraste para reordenar. Toque para editar.';

  @override
  String get columns => 'Colunas';

  @override
  String get padEmpty => 'Nenhum botão neste layout ainda.';

  @override
  String get buttonIncomplete =>
      'Este botão não está completo: escolha o que ele deve controlar.';

  @override
  String buttonsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count botões adicionados',
      one: '1 botão adicionado',
      zero: 'Nenhum botão novo',
    );
    return '$_temp0';
  }

  @override
  String get confirm => 'Confirmar';

  @override
  String get confirmStopLiveTitle => 'Parar a live?';

  @override
  String get confirmStopLiveBody =>
      'Sua live vai acabar para todo mundo que está assistindo.';

  @override
  String get layoutLive => 'Live';

  @override
  String get layoutRecording => 'Gravação';

  @override
  String get layoutAudioOnly => 'Só áudio';

  @override
  String get layoutMenu => 'Layouts';

  @override
  String get layoutNew => 'Novo layout';

  @override
  String get layoutRename => 'Renomear layout';

  @override
  String get layoutDelete => 'Apagar layout';

  @override
  String layoutDeleteConfirm(String name) {
    return 'Apagar o layout \"$name\"?';
  }

  @override
  String get layoutDeleteBody => 'Os botões dele também serão apagados.';

  @override
  String get layoutAddSceneButtons => 'Criar um botão para cada cena';

  @override
  String get layoutAddMuteButtons => 'Criar um botão de mute para cada áudio';

  @override
  String get fieldName => 'Nome';

  @override
  String get fieldAction => 'O que ele faz?';

  @override
  String get fieldScene => 'Cena';

  @override
  String get fieldSource => 'Fonte';

  @override
  String get fieldAudioInput => 'Áudio';

  @override
  String get fieldHotkey => 'Nome do atalho';

  @override
  String get fieldHotkeyHelp =>
      'Escolha na lista de atalhos do OBS. Atalhos de plugins também aparecem lá.';

  @override
  String get fieldLabel => 'Rótulo';

  @override
  String get fieldSize => 'Tamanho';

  @override
  String get fieldColor => 'Cor';

  @override
  String get fieldIcon => 'Ícone';

  @override
  String get fieldEmoji => 'Emoji';

  @override
  String get noEmoji => 'Nenhum';

  @override
  String get sizeSmall => 'Pequeno';

  @override
  String get sizeMedium => 'Médio';

  @override
  String get sizeLarge => 'Grande';

  @override
  String get pickFromObs => 'Escolher do OBS';

  @override
  String get search => 'Buscar';

  @override
  String get moveUp => 'Subir';

  @override
  String get macroHelp =>
      'Os passos rodam em ordem. A espera acontece depois de cada passo.';

  @override
  String macroStep(int number) {
    return 'Passo $number';
  }

  @override
  String macroStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passos',
      one: '1 passo',
    );
    return '$_temp0';
  }

  @override
  String macroDelay(String seconds) {
    return 'Esperar $seconds s antes do próximo passo';
  }

  @override
  String get macroAddStep => 'Adicionar passo';

  @override
  String get badgeOnAir => 'NO AR';

  @override
  String get badgeVisible => 'VISÍVEL';

  @override
  String get badgeMuted => 'MUTADO';

  @override
  String get badgeLive => 'AO VIVO';

  @override
  String get badgeRecording => 'GRAVANDO';

  @override
  String get badgePaused => 'PAUSADO';

  @override
  String get badgeReady => 'PRONTO';

  @override
  String get badgePlaying => 'TOCANDO';

  @override
  String get mute => 'Mutar';

  @override
  String get unmute => 'Desmutar';

  @override
  String get mixerEmpty => 'Nenhuma fonte de áudio encontrada no OBS.';

  @override
  String get statusReconnectingShort => 'Reconectando';

  @override
  String get metricLive => 'Live';

  @override
  String get metricRecording => 'Gravação';

  @override
  String get metricOff => 'Desligada';

  @override
  String get metricAirTime => 'Tempo no ar';

  @override
  String get metricBitrate => 'Bitrate';

  @override
  String get metricCpu => 'CPU do OBS';

  @override
  String get metricMemory => 'Memória';

  @override
  String get metricFps => 'FPS ativo';

  @override
  String get metricRenderDropped => 'Frames perdidos na renderização';

  @override
  String get metricOutputDropped => 'Frames perdidos na saída';

  @override
  String get metricCongestion => 'Congestionamento';

  @override
  String get chartWindow => 'Histórico dos gráficos';

  @override
  String get chartBitrate => 'Bitrate';

  @override
  String get chartCpu => 'CPU do OBS';

  @override
  String get chartDropped => 'Frames perdidos (últimos segundos)';

  @override
  String get alertFramesTitle => 'Frames estão sendo perdidos';

  @override
  String get alertFramesBody =>
      'Mais de 1% dos frames foram perdidos. Quem assiste pode ver travadas. Feche programas pesados, diminua o bitrate ou a resolução.';

  @override
  String get alertBitrateTitle => 'O bitrate caiu bruscamente';

  @override
  String get alertBitrateBody =>
      'O envio da sua internet pode estar instável. Se continuar, diminua o bitrate em OBS > Configurações > Saída.';

  @override
  String get soundProfileDefault => 'Principal';

  @override
  String get soundPageDefault => 'Sons';

  @override
  String get soundProfiles => 'Perfis de sons';

  @override
  String get soundProfileNew => 'Novo perfil de sons';

  @override
  String get soundProfileRename => 'Renomear perfil';

  @override
  String get soundProfileDelete => 'Apagar perfil';

  @override
  String get soundPageNew => 'Nova página';

  @override
  String get soundPageRename => 'Renomear página';

  @override
  String get soundPageDelete => 'Apagar página';

  @override
  String get soundEmpty => 'Nenhum som aqui ainda. Toque em \"Adicionar som\".';

  @override
  String get soundAdd => 'Adicionar som';

  @override
  String get soundEdit => 'Editar som';

  @override
  String get panicButton => 'Parar todos';

  @override
  String get panicDone => 'Todos os sons foram parados.';

  @override
  String panicPartial(int count) {
    return 'Parado, mas $count som(ns) não foram encontrados no OBS.';
  }

  @override
  String soundMissing(String name) {
    return 'A fonte de som \"$name\" não existe no OBS. Edite o pad ou adicione o som de novo.';
  }

  @override
  String get soundPlayFromStart => 'Tocar do começo';

  @override
  String get soundResume => 'Continuar';

  @override
  String get soundPause => 'Pausar';

  @override
  String get soundStop => 'Parar';

  @override
  String get soundAddIntro =>
      'O arquivo de áudio fica no seu PC — o celular não envia áudio. O OBS Pad cria no OBS uma Fonte de mídia que toca o arquivo, e este pad dispara essa fonte.';

  @override
  String get soundAddNeedsConnection =>
      'Conecte ao OBS para criar a fonte de som.';

  @override
  String get soundFromFile => 'Arquivo do PC';

  @override
  String get soundFromExisting => 'Fonte que já existe';

  @override
  String get soundLabelHint => 'ex.: Aplausos';

  @override
  String get soundPathField => 'Caminho do arquivo no PC';

  @override
  String get soundPathHelp =>
      'Dica: no Windows, segure Shift, clique com o botão direito no arquivo e escolha \"Copiar como caminho\" (tire as aspas). No Mac, Option + botão direito > \"Copiar como Nome de Caminho\".';

  @override
  String get soundPathEmpty => 'Digite onde o arquivo está no PC';

  @override
  String get soundPathInvalid =>
      'Isso não parece um caminho de arquivo. Exemplo: C:\\Users\\Ana\\Music\\aplausos.mp3';

  @override
  String get soundAllScenes => 'Adicionar em todas as cenas (recomendado)';

  @override
  String get soundAllScenesHelp =>
      'Um som só sai na live se a fonte estiver na cena que está no ar.';

  @override
  String get soundMonitor => 'Tocar também no meu fone';

  @override
  String get soundMonitorHelp =>
      'Usa o \"Monitorar e enviar\" do OBS, para você ouvir também.';

  @override
  String get soundLoop => 'Repetir (loop)';

  @override
  String get soundLoopHelp => 'Toca de novo e de novo até você parar.';

  @override
  String get advanced => 'Avançado';

  @override
  String get soundInputNameField => 'Nome da fonte no OBS';

  @override
  String get soundInputNameHelp =>
      'Se já existir uma fonte com esse nome, o arquivo dela é trocado.';

  @override
  String soundInputNameDefault(String label) {
    return 'Som - $label';
  }

  @override
  String get soundCreateInObs => 'Criar no OBS';

  @override
  String get soundAddPad => 'Adicionar pad';

  @override
  String soundAdded(String name) {
    return '\"$name\" adicionado.';
  }

  @override
  String get soundSourceField => 'Fonte de mídia no OBS';

  @override
  String get soundSourceHelp => 'A Fonte de mídia que este pad toca.';

  @override
  String get soundNoMediaSources => 'Nenhuma Fonte de mídia encontrada no OBS.';

  @override
  String get soundPickSource =>
      'Escolha qual fonte de mídia do OBS este pad toca.';

  @override
  String get soundModeTitle => 'Como ele toca';

  @override
  String get soundModeToEnd => 'Tocar até o fim';

  @override
  String get soundModeHold => 'Segurar para tocar';

  @override
  String get soundModeToEndHelp =>
      'Toque para tocar do começo. Toque de novo para parar. Segure para mais opções.';

  @override
  String get soundModeHoldHelp => 'Toca só enquanto seu dedo estiver no pad.';

  @override
  String get soundVolume => 'Ajustar volume';

  @override
  String get soundVolumeKeep => 'Manter o volume que está no OBS';

  @override
  String get duckingTitle => 'Abaixar outro áudio enquanto toca';

  @override
  String get duckingHelp =>
      'Ex.: abaixa o mic ou a música e volta ao normal quando o som termina. Se a conexão cair no meio do som, o volume volta ao normal assim que o OBS Pad reconectar.';

  @override
  String get duckingTarget => 'Áudio para abaixar';

  @override
  String duckingAmount(int db) {
    return 'Abaixar $db dB';
  }

  @override
  String get manualTitle => 'Fazer manualmente no OBS';

  @override
  String get manualStep1 =>
      'No OBS, selecione a cena e clique em + em Fontes > Fonte de mídia.';

  @override
  String get manualStep2 =>
      'Dê um nome e deixe \"Arquivo local\" marcado. Clique em Procurar e escolha o arquivo de áudio.';

  @override
  String get manualStep3 =>
      'Marque \"Fechar arquivo quando inativo\" e desmarque \"Reiniciar reprodução quando a fonte ficar ativa\". Clique em OK.';

  @override
  String get manualStep4 =>
      'No Mixer de áudio, clique em ⋮ (ou na engrenagem) > Propriedades avançadas de áudio. Na linha do seu som, confira que a Faixa 1 está marcada.';

  @override
  String get manualStep5 =>
      'Opcional: mude o Monitoramento de áudio para \"Monitorar e enviar\" para ouvir no seu fone.';

  @override
  String get manualStep6 =>
      'De volta aqui, escolha \"Fonte que já existe\" e selecione a fonte que você criou.';

  @override
  String get metricsForegroundHint =>
      'Os alertas só funcionam com o OBS Pad aberto e a tela ligada. Com o app fechado ou em segundo plano, ninguém está vigiando a live.';
}
