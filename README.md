# OBS Pad

Controle remoto do **OBS Studio** pelo celular — uma alternativa ao Stream Deck feita para quem não é técnico. Botões grandes, guia passo a passo e mensagens de erro em português claro (também em inglês).

- **Botões**: grid customizável (arrastar, cor, ícone, rótulo, tamanho), layouts *Live*, *Gravação* e *Só áudio*. Ações: trocar de cena, mostrar/ocultar fonte, mutar áudio, live, gravação (iniciar/parar/pausar), salvar replay, atalhos do OBS e macros (várias ações com espera entre elas).
- **Mixer**: volume e mute por áudio, com medidor de nível ao vivo.
- **Sons** (soundboard): pads que tocam arquivos que ficam **no PC**, com páginas, perfis, "tocar até o fim" ou "segurar para tocar", volume, loop, *ducking* (abaixar mic/música enquanto toca) e botão de pânico.
- **Métricas**: status da live/gravação, tempo no ar, CPU, memória, FPS, frames perdidos, congestionamento, bitrate e gráficos de 2 a 5 minutos, com alerta (cor + vibração).
- Os botões acendem sozinhos conforme o OBS muda (cena no ar, live, gravação, mute, som tocando).

---

## 1. Configurar o OBS (no computador)

1. Use o **OBS Studio 28 ou mais novo** (Ajuda › Sobre mostra a versão). O servidor WebSocket já vem embutido.
2. Abra **Ferramentas › Configurações do Servidor WebSocket**.
3. Marque **Ativar servidor WebSocket**.
4. Marque **Ativar autenticação** e crie uma senha.
5. Deixe a **porta 4455** e clique em **OK**.
6. O botão **Mostrar informações de conexão** mostra o IP e a senha.

### Achar o IP do PC

- **Windows**: `Windows + R` › `cmd` › `ipconfig` › procure **Endereço IPv4** (ex.: `192.168.0.15`).
- **Mac**: Ajustes do Sistema › Rede › Wi-Fi › **Endereço IP**.
- **Linux**: `hostname -I`.

O celular e o PC precisam estar **no mesmo Wi-Fi**.

### Se não conectar

| O app diz | O que fazer |
|---|---|
| Senha errada | Confira a senha em *Mostrar informações de conexão*. |
| O OBS não respondeu | OBS fechado ou servidor WebSocket desligado/porta diferente. |
| Não consegui chegar ao computador | IP errado ou **Firewall do Windows** bloqueando a porta 4455: em *Permitir um aplicativo pelo Firewall do Windows*, marque **OBS Studio › Privada**, e deixe o Wi-Fi como rede *Privada*. |
| Rede diferente | O celular está em outro Wi-Fi ou nos dados móveis. |

## 2. Acessar de fora de casa (opcional)

Use uma VPN privada grátis — **Tailscale** (tailscale.com) ou **NetBird** (netbird.io):

1. Crie uma conta e instale o app **no PC e no celular**, com a mesma conta.
2. No PC, copie o IP da VPN (começa com `100.`).
3. No OBS Pad, adicione um computador com esse IP, a mesma porta e a mesma senha.

> ⚠️ **Nunca** faça redirecionamento de portas da 4455 no roteador. Isso expõe o controle do seu OBS para a internet inteira.

O app tem essa explicação na tela **Acessar de fora de casa**.

## 3. Sons (soundboard)

O áudio **não sai do celular**: os arquivos ficam no PC e o OBS toca. Em **Sons › Adicionar som**, digite o caminho do arquivo no PC (no Windows: Shift + botão direito no arquivo › *Copiar como caminho*). O app:

1. cria uma **Fonte de mídia** (`ffmpeg_source`) com `local_file` apontando para o arquivo — ou atualiza a fonte, se já existir uma com esse nome;
2. marca *Fechar arquivo quando inativo* e desliga *Reiniciar quando ficar ativa*;
3. adiciona a fonte em **todas as cenas** (opcional, recomendado: um som numa cena que não está no ar não sai na live);
4. tira o mute, liga a **Faixa 1** e, se pedido, *Monitorar e enviar* (para você ouvir no fone).

Se algo falhar, o app mostra o passo a passo para fazer manualmente no OBS e depois usar **Fonte que já existe**.

**Ducking**: o volume original fica salvo no celular enquanto o som toca. Se a conexão cair ou o app for fechado no meio do som, o volume é restaurado assim que o app reconectar ao OBS. Se o som ainda estiver tocando nesse momento, a música volta ao normal antes de ele acabar.

## 4. Limitações conhecidas

O app não usa servidor: conversa direto com o OBS e guarda tudo no celular.

- **Tamanho dos botões**: todos os botões ocupam uma célula; o tamanho muda o ícone e o texto, e o número de colunas (2 a 6) é escolhido por layout.
- **App aberto e na tela**: com o app em segundo plano o celular derruba a conexão; alertas de métricas, macros em andamento e "segurar para tocar" param.
- **Bateria**: as métricas são lidas a cada 1 s enquanto o app está conectado, em qualquer aba (para o alerta aparecer em todas).
- **IP digitado à mão**: o OBS não se anuncia na rede, então o app não encontra o PC sozinho.
- **Atalhos**: só os que o OBS lista pelo nome; combinações de teclas puras não são suportadas.
- **Sons**: o arquivo precisa já estar no PC e o caminho é digitado — o obs-websocket não permite navegar nas pastas nem enviar arquivos.
- **Layouts e sons ficam só neste celular**: não há backup nem sincronização entre aparelhos.
- **Idiomas**: português e inglês.
- **Ainda não validado**: os testes usam um servidor obs-websocket simulado; falta testar com o OBS real e em aparelhos. O app iOS não foi compilado, e o APK de release usa a chave de debug.

### O que precisaria de algo além do app

- **Escolher/enviar sons pelo celular**: um pequeno programa no PC que receba o arquivo ou mostre as pastas.
- **Alertas com o app fechado**: algo rodando no PC (ou um serviço de push) vigiando o OBS.
- **Sincronizar layouts entre aparelhos**: um servidor — ou, sem servidor, exportar/importar um arquivo.
- **Acesso de fora sem VPN**: daria com um servidor intermediário, mas a VPN é mais simples e mais segura.

---

## Para desenvolvedores

### Requisitos

- Flutter **3.47.7** (stable) / Dart 3.13 — o projeto tem um `mise.toml` fixando a versão.
- Android SDK (para APK) e/ou Xcode (para iOS).

### Rodar

```bash
flutter pub get
flutter run                 # celular conectado por USB ou emulador
flutter analyze             # lints estritos
flutter test                # unit + widget tests
```

As traduções ficam em `lib/l10n/app_pt.arb` e `lib/l10n/app_en.arb`; o código é gerado automaticamente (`flutter gen-l10n`).

### Gerar o APK

```bash
flutter build apk --release
# arquivo: build/app/outputs/flutter-apk/app-release.apk
```

Copie o APK para o celular e instale (o Android vai pedir para permitir "fontes desconhecidas"). O build release usa a chave de debug; para publicar na Play Store, configure uma chave própria em `android/app/build.gradle.kts`.

### Arquitetura

```
lib/
  domain/        modelos puros, ObsRepository (interface), cálculo de métricas,
                 ducking, matemática de volume — sem Flutter nem obs_websocket
  data/
    obs/         WebSocketObsRepository (único lugar que usa obs_websocket),
                 mapeamento de erros de rede/protocolo -> ObsFailure
    storage/     perfis (senha no flutter_secure_storage), layouts, sons, ajustes
  presentation/  Riverpod (estado), go_router (rotas), telas e widgets
```

- **`ObsRepository`** isola o pacote `obs_websocket`: a UI só vê modelos de domínio e `ObsFailure`. As requisições usam a API crua do pacote para que falhas em `Set*` também sejam reportadas.
- **Reconexão**: backoff exponencial (1s, 2s, 4s… até 30s) sem limite enquanto o usuário quiser estar conectado; para em erros permanentes (senha errada). Requisições sem resposta em 8s derrubam o socket e disparam a reconexão; ao voltar do segundo plano, tenta na hora.
- **Eventos**: assinatura de todos os eventos de baixo volume; `InputVolumeMeters` (alto volume, a cada 50ms) só é assinado enquanto a aba Mixer está na tela (via `Reidentify`).
- **Métricas**: `GetStats` + `GetStreamStatus` + `GetRecordStatus` a cada 1s. Bitrate = Δ`outputBytes` × 8 / Δt. Alerta quando > 1% dos frames (renderização ou saída) foram perdidos nos últimos 10s, ou quando o bitrate cai abaixo de 50% da média das últimas amostras.
- Os nomes de requests/eventos foram conferidos contra o `protocol.json` oficial do obs-websocket 5.x.

### Configuração nativa (ws:// sem TLS)

- **Android** (`android/app/src/main/AndroidManifest.xml`): permissão `INTERNET` e `android:usesCleartextTraffic="true"`.
- **iOS** (`ios/Runner/Info.plist`): `NSAppTransportSecurity › NSAllowsLocalNetworking` e `NSLocalNetworkUsageDescription` (texto mostrado na permissão de rede local).

### Testes

- `test/metrics_calculator_test.dart` — bitrate, frames perdidos, alertas, janela.
- `test/obs_error_mapper_test.dart` — erros de socket/protocolo → mensagens humanas; validação de IP.
- `test/ducking_and_audio_test.dart` — ducking (inclusive restaurar após queda de conexão ou app fechado) e conversões de volume.
- `test/websocket_obs_repository_test.dart` — o repositório real contra um servidor obs-websocket 5 falso (handshake com senha, close 4009, porta fechada, recurso inexistente, assinaturas, reconexão).
- `test/onboarding_wizard_test.dart` — widget tests do guia de 4 passos.
- `test/home_features_test.dart` — botões, sincronização por eventos, mixer, soundboard e "Adicionar som".
