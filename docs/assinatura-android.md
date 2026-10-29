# Chave de assinatura das versões de teste (Android)

Todo APK é assinado. O Android só instala uma versão **por cima** da outra se as duas tiverem a mesma assinatura. As versões de teste (pré-lançamento [`dev`](https://github.com/lucaswilliameufrasio/obs-pad/releases/tag/dev)) são assinadas com uma **chave de testes fixa**, para quem testa não precisar desinstalar (e perder botões e sons) a cada versão.

> Esta **não** é a chave da Play Store. Quando o app for para a loja, crie outra.

## Onde a chave fica

| Lugar | O quê |
|---|---|
| Computador de quem gera APKs | `~/.config/obs-pad/obs-pad-dev.jks` (chave) e `~/.config/obs-pad/key.properties` (senha e alias). No Windows: `%APPDATA%\obs-pad\`. |
| Projeto | `android/key.properties` aponta para a chave. **Nunca vai para o git** (está no `.gitignore`, junto com `*.jks`). |
| GitHub | Secrets do repositório `ANDROID_DEV_KEYSTORE_BASE64` (a chave em base64) e `ANDROID_DEV_KEYSTORE_PASSWORD`. O alias é sempre `obs-pad-dev`. |
| Backup | Bitwarden, nota segura **"OBS Pad – chave de testes Android"**: a chave em base64 nas notas e a senha no campo oculto `storePassword`. |
| Repositório (público) | `android/signing/dev-key.sha256`: a impressão digital SHA-256 da chave. Não é segredo (aparece em todo APK); serve para conferir que a chave certa foi restaurada. |

Você **só precisa da chave num computador** para gerar APKs que instalem por cima das versões do GitHub. Para programar e testar, não: sem `android/key.properties`, o build usa a chave de debug da máquina.

## A ferramenta: `mise run chave`

Na raiz do projeto:

```bash
mise run chave
```

(Sem o mise: `cd tool/signing-key && go run .` — precisa do Go 1.27+.)

Abre um menu no terminal (↑/↓, Enter, Esc para voltar):

- **Restaurar a chave neste computador** — do Bitwarden (automático), colando o texto da nota, ou de um arquivo `.jks`.
- **Verificar a chave instalada** — arquivo, senha, se é a chave do projeto e se o projeto está ligado a ela.
- **Fazer backup no Bitwarden** — automático pelo `bw`, ou **manual**: guia o preenchimento no app/site do Bitwarden e copia cada valor na hora certa (funciona sem o `bw`).
- **Atualizar os secrets do GitHub** — envia a chave instalada para os secrets.
- **Criar uma chave nova** — só se a antiga foi perdida.

Para scripts: `go -C tool/signing-key run . check` sai com código 0 só se a chave estiver instalada e correta.

O que cada opção precisa:

| Opção | Precisa de |
|---|---|
| Restaurar colando o texto / de arquivo | nada além do Go (ou mise) |
| Restaurar do Bitwarden, Backup automático | [`bw`, a CLI do Bitwarden](https://bitwarden.com/help/cli/) (a ferramenta faz o `bw login`/desbloqueio se precisar) |
| Backup manual | nada: copia para a área de transferência (`wl-copy`, `xclip`/`xsel`, macOS, Windows ou, sem eles, pelo próprio terminal) ou mostra na tela |
| Atualizar os secrets | [`gh`](https://cli.github.com), logado (`gh auth login`) com acesso de admin ao repositório |
| Criar chave nova | Java (`keytool`), o mesmo usado para compilar o Android |

As senhas nunca passam pela linha de comando (vão por variável de ambiente ou stdin) e os arquivos são gravados só com permissão do seu usuário (`600`).

## Restaurar em outro computador

### Com a ferramenta (recomendado)

1. Clone o projeto e instale as ferramentas: `mise install`.
2. Na raiz do projeto: `mise run chave` › **Restaurar a chave neste computador**.
3. Escolha de onde vem a chave:
   - **Bitwarden (automático)**: com o `bw` instalado. Ela faz login se precisar, pede a senha mestra, acha a nota e já pega a senha da chave.
   - **Colar o texto da nota**: abra a nota no Bitwarden (app ou site), copie o texto das notas e cole. Depois digite a senha (campo `storePassword`). Senha errada é avisada na hora.
   - **Arquivo .jks**: se você tem o arquivo (ex.: anexo baixado).
4. A ferramenta confere a impressão digital com `android/signing/dev-key.sha256` e grava tudo. Se você rodar fora do projeto, ela grava em `~/.config/obs-pad/`; rode de novo dentro do projeto para ligá-lo.

Pronto: `flutter build apk --release` gera APKs que instalam por cima das versões de teste.

### Na mão (sem a ferramenta)

```bash
mkdir -p ~/.config/obs-pad && chmod 700 ~/.config/obs-pad
cd ~/.config/obs-pad

# cole o texto das notas do Bitwarden no lugar de COLE_AQUI
printf '%s' 'COLE_AQUI' | base64 -d > obs-pad-dev.jks
chmod 600 obs-pad-dev.jks

read -rs -p 'Senha (campo storePassword): ' P; echo
cat > key.properties <<EOF
storeFile=$HOME/.config/obs-pad/obs-pad-dev.jks
storePassword=$P
keyAlias=obs-pad-dev
keyPassword=$P
EOF
unset P; chmod 600 key.properties

# conferir: tem que bater com android/signing/dev-key.sha256
keytool -list -v -keystore obs-pad-dev.jks \
  -storepass "$(grep ^storePassword= key.properties | cut -d= -f2-)" | grep SHA256

cp key.properties /caminho/do/obs-pad/android/key.properties
```

## Backup no Bitwarden

**Com a ferramenta:** `mise run chave` › **Fazer backup no Bitwarden**:

- **Automático, pelo `bw`** (se instalado): cria a nota segura; se já existir, pergunta antes de substituir.
- **Manual** (sem `bw`, ou se preferir): quatro passos na tela — criar a nota, colar a chave, criar o campo oculto da senha, colar a impressão digital. Em cada passo, *Copiar* põe o valor na área de transferência e *Mostrar na tela* exibe para copiar com o mouse. No fim, a área de transferência é limpa.

**Totalmente na mão** (sem a ferramenta), no app ou site do Bitwarden:

1. Crie uma **Nota segura** chamada `OBS Pad – chave de testes Android`.
2. **Notas**: o texto da chave — copie com
   `base64 -w0 ~/.config/obs-pad/obs-pad-dev.jks | wl-copy` (no X11: `xclip -sel clip`; no macOS: `base64 -i ~/.config/obs-pad/obs-pad-dev.jks | pbcopy`).
   Cabe no plano grátis (~5.700 caracteres; o limite é 10.000).
3. **Campo oculto** `storePassword`: a senha —
   `grep '^storePassword=' ~/.config/obs-pad/key.properties | cut -d= -f2- | tr -d '\n' | wl-copy`.
4. **Campos de texto** `keyAlias` = `obs-pad-dev` e `SHA-256` = o conteúdo de `android/signing/dev-key.sha256`.
5. Limpe a área de transferência (copie qualquer outra coisa).

Com o Bitwarden Premium, dá para anexar o `.jks` em vez de colar o texto; a ferramenta usa o anexo quando existe.

## Atualizar os secrets do GitHub

Quando: depois de **criar uma chave nova**, se os secrets foram apagados, ou num fork/repositório novo.

### Com a ferramenta

`mise run chave` › **Atualizar os secrets do GitHub**. Ela mostra o repositório e a impressão digital, e avisa se a chave for diferente da registrada em `android/signing/dev-key.sha256`.

### Na mão

```bash
base64 -w0 ~/.config/obs-pad/obs-pad-dev.jks \
  | gh secret set ANDROID_DEV_KEYSTORE_BASE64 -R lucaswilliameufrasio/obs-pad
grep '^storePassword=' ~/.config/obs-pad/key.properties | cut -d= -f2- | tr -d '\n' \
  | gh secret set ANDROID_DEV_KEYSTORE_PASSWORD -R lucaswilliameufrasio/obs-pad
```

Ou pelo site: *Settings › Secrets and variables › Actions › New repository secret*, com os mesmos nomes. (No macOS, `base64 -i arquivo` em vez de `base64 -w0 arquivo`.)

### Depois de atualizar

1. Publique uma versão de teste: faça um push na `main`, ou em *Actions › Build apps* reexecute o último build da `main` (*Re-run all jobs*). Execução **manual** (*Run workflow*) só gera os arquivos, não publica.
2. Confira a assinatura do APK publicado:
   ```bash
   gh release download dev -p obs-pad-android.apk
   apksigner verify --print-certs obs-pad-android.apk | grep SHA-256
   ```
   Tem que bater com `android/signing/dev-key.sha256` (sem os `:` e em minúsculas).

Sem os secrets, o workflow ainda compila, mas com uma chave descartável — e **não publica** o `dev`, para ninguém instalar um APK que não poderia ser atualizado.

## Perdi a chave (sem backup)

1. `mise run chave` › **Criar uma chave nova**. Ela gera a chave (RSA 4096, alias `obs-pad-dev`), instala neste computador e atualiza `android/signing/dev-key.sha256`.
2. No mesmo menu: **Fazer backup no Bitwarden** e **Atualizar os secrets do GitHub**.
3. Faça commit de `android/signing/dev-key.sha256` e push.
4. Avise quem testa: vai precisar **desinstalar uma vez** a versão antiga (perde botões e sons configurados) e instalar a nova.
