// Command signing-key installs, checks and backs up the key that signs the
// OBS Pad test APKs. Run it with `mise run chave` (or `go run .` here).
package main

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/huh"
	"github.com/charmbracelet/huh/spinner"
	"github.com/charmbracelet/lipgloss"
)

var (
	accent  = lipgloss.Color("#7B6CF6")
	good    = lipgloss.NewStyle().Foreground(lipgloss.Color("#3FB950")).Bold(true)
	bad     = lipgloss.NewStyle().Foreground(lipgloss.Color("#F85149")).Bold(true)
	warn    = lipgloss.NewStyle().Foreground(lipgloss.Color("#D29922")).Bold(true)
	dim     = lipgloss.NewStyle().Foreground(lipgloss.Color("#8B949E"))
	title   = lipgloss.NewStyle().Bold(true).Foreground(accent)
	boxBase = lipgloss.NewStyle().Border(lipgloss.RoundedBorder()).Padding(0, 2).MarginBottom(1)
)

// short shows paths with ~ and trims the middle of very long ones, so the
// boxes do not wrap.
func short(path string) string {
	if home, err := os.UserHomeDir(); err == nil && home != "" && strings.HasPrefix(path, home) {
		path = "~" + strings.TrimPrefix(path, home)
	}
	const max = 60
	if r := []rune(path); len(r) > max {
		path = string(r[:20]) + "…" + string(r[len(r)-(max-21):])
	}
	return path
}

// pause keeps a result on screen until Enter.
func pause() {
	fmt.Print(dim.Render("Enter para voltar ao menu… "))
	_, _ = bufio.NewReader(os.Stdin).ReadString('\n')
}

func clearScreen() { fmt.Print("\033[H\033[2J") }

func box(color lipgloss.Color, lines ...string) {
	fmt.Println(boxBase.BorderForeground(color).Render(strings.Join(lines, "\n")))
}

type app struct {
	paths   Paths
	theme   *huh.Theme
	session string // Bitwarden session, once unlocked
}

func main() {
	cwd, _ := os.Getwd()
	root := findProjectRoot(cwd)
	paths, err := defaultPaths(root)
	if err != nil {
		fmt.Println(bad.Render("Erro: ") + err.Error())
		os.Exit(1)
	}
	a := &app{paths: paths, theme: huh.ThemeCharm(), session: os.Getenv("BW_SESSION")}

	if len(os.Args) > 1 && os.Args[1] == "check" {
		// Non-interactive, for scripts: exit 0 only when everything is fine.
		r := check(paths)
		a.printReport(r)
		if !r.OK() {
			os.Exit(1)
		}
		return
	}
	a.menu()
}

func (a *app) form(groups ...*huh.Group) *huh.Form {
	// Esc goes back (cancels the step), like Ctrl+C.
	keys := huh.NewDefaultKeyMap()
	keys.Quit = key.NewBinding(key.WithKeys("ctrl+c", "esc"), key.WithHelp("esc", "voltar"))
	return huh.NewForm(groups...).WithTheme(a.theme).WithKeyMap(keys)
}

func (a *app) header() {
	r := check(a.paths)
	status := bad.Render("✘ não instalada neste computador")
	switch {
	case r.OK():
		status = good.Render("✔ instalada e funcionando") + dim.Render("  "+shortFP(r.Info.Fingerprint))
	case r.KeystoreFound:
		status = warn.Render("⚠ instalada, mas com problema") + dim.Render(" (veja \"Verificar\")")
	}
	project := dim.Render("fora do projeto OBS Pad")
	if a.paths.ProjectRoot != "" {
		project = dim.Render(short(a.paths.ProjectRoot))
	}
	box(accent,
		title.Render("🔑  OBS Pad — chave de testes do Android"),
		"",
		"Neste computador: "+status,
		"Projeto: "+project,
	)
}

func shortFP(fp string) string {
	if len(fp) < 11 {
		return fp
	}
	return fp[:11] + "…"
}

func (a *app) menu() {
	for {
		clearScreen()
		a.header()
		installed := check(a.paths).OK()
		var choice string
		options := []huh.Option[string]{
			huh.NewOption("Restaurar a chave neste computador", "restore"),
			huh.NewOption("Verificar a chave instalada", "check"),
		}
		if installed {
			options = append(options,
				huh.NewOption("Fazer backup no Bitwarden", "backup"),
				huh.NewOption("Atualizar os secrets do GitHub", "secrets"),
			)
		}
		options = append(options,
			huh.NewOption("Criar uma chave nova (só se a antiga foi perdida)", "new"),
			huh.NewOption("O que é essa chave?", "help"),
			huh.NewOption("Sair", "quit"),
		)
		err := a.form(huh.NewGroup(
			huh.NewSelect[string]().
				Title("O que você quer fazer?").
				Description("↑/↓ para escolher, Enter para confirmar, Esc para sair").
				Options(options...).
				Value(&choice),
		)).Run()
		if err != nil || choice == "quit" {
			fmt.Println(dim.Render("Até mais!"))
			return
		}

		var actionErr error
		switch choice {
		case "restore":
			actionErr = a.restore()
		case "check":
			a.printReport(check(a.paths))
		case "backup":
			actionErr = a.backup()
		case "secrets":
			actionErr = a.updateSecrets()
		case "new":
			actionErr = a.createNew()
		case "help":
			a.help()
		}
		if errors.Is(actionErr, huh.ErrUserAborted) {
			continue
		}
		if actionErr != nil {
			box(lipgloss.Color("#F85149"), bad.Render("Não deu certo"), "", actionErr.Error())
		}
		pause()
	}
}

// ------------------------------------------------------------------ restore

func (a *app) restore() error {
	var source string
	bwDesc := "Busca a nota \"" + bwItemName + "\" e já pega a senha"
	if !hasCommand("bw") {
		bwDesc = "Precisa do bw (Bitwarden CLI) instalado — ou use \"Colar o texto\""
	}
	err := a.form(huh.NewGroup(
		huh.NewSelect[string]().
			Title("De onde vem a chave?").
			Options(
				huh.NewOption("Bitwarden (automático)", "bw"),
				huh.NewOption("Colar o texto da nota (Bitwarden ou outro gerenciador)", "paste"),
				huh.NewOption("Um arquivo .jks neste computador", "file"),
			).
			Value(&source),
		huh.NewNote().Description("Bitwarden: "+bwDesc),
	)).Run()
	if err != nil {
		return err
	}

	var keystore []byte
	var password string
	switch source {
	case "bw":
		if !hasCommand("bw") {
			return errors.New("o bw não está instalado. Instale (https://bitwarden.com/help/cli/) ou escolha \"Colar o texto da nota\"")
		}
		item, err := a.pickBitwardenItem()
		if err != nil {
			return err
		}
		keystore, err = bwKeystore(a.session, item)
		if err != nil {
			return err
		}
		password = item.field("storePassword")
	case "paste":
		var text string
		err := a.form(huh.NewGroup(
			huh.NewText().
				Title("Cole aqui o texto da chave").
				Description("É o texto longo (base64) que está nas notas do item no gerenciador de senhas. Ctrl+Shift+V para colar.").
				CharLimit(50000).
				Lines(6).
				Value(&text).
				Validate(func(s string) error { _, err := decodePasted(s); return err }),
		)).Run()
		if err != nil {
			return err
		}
		keystore, _ = decodePasted(text)
	case "file":
		var path string
		err := a.form(huh.NewGroup(
			huh.NewInput().
				Title("Caminho do arquivo .jks").
				Placeholder("~/Downloads/obs-pad-dev.jks").
				Value(&path).
				Validate(func(s string) error {
					_, err := os.Stat(expandHome(s))
					if err != nil {
						return errors.New("não achei esse arquivo")
					}
					return nil
				}),
		)).Run()
		if err != nil {
			return err
		}
		keystore, err = os.ReadFile(expandHome(path))
		if err != nil {
			return err
		}
	}

	// The password: from Bitwarden, or typed (checked as you type Enter).
	if _, err := inspectKey(keystore, password); password == "" || err != nil {
		if errors.Is(err, errNotKeystore) && password != "" {
			return err
		}
		err := a.form(huh.NewGroup(
			huh.NewInput().
				Title("Senha da chave").
				Description("O campo storePassword do item no gerenciador de senhas.").
				EchoMode(huh.EchoModePassword).
				Value(&password).
				Validate(func(s string) error {
					_, err := inspectKey(keystore, s)
					return err
				}),
		)).Run()
		if err != nil {
			return err
		}
	}

	info, err := inspectKey(keystore, password)
	if err != nil {
		return err
	}
	if !a.confirmFingerprint(info) {
		return huh.ErrUserAborted
	}
	if !a.confirmReplace(info) {
		return huh.ErrUserAborted
	}

	if err := install(a.paths, keystore, password); err != nil {
		return err
	}
	lines := []string{
		good.Render("✔ Chave restaurada!"),
		"",
		"Chave:          " + short(a.paths.Keystore),
		"Configuração:   " + short(a.paths.Properties),
	}
	if a.paths.ProjectProperties != "" {
		lines = append(lines, "Projeto:        "+short(a.paths.ProjectProperties))
	} else {
		lines = append(lines, "",
			warn.Render("Rode de novo dentro do projeto para ligar a chave a ele,"),
			warn.Render("ou copie "+short(a.paths.Properties)+" para android/key.properties."))
	}
	lines = append(lines, "",
		"Agora `flutter build apk --release` gera APKs que instalam",
		"por cima das versões de teste do GitHub.")
	box(lipgloss.Color("#3FB950"), lines...)
	return nil
}

func (a *app) confirmFingerprint(info KeyInfo) bool {
	expected := expectedFingerprint(a.paths.ProjectRoot)
	if expected == "" || info.Fingerprint == expected {
		return true
	}
	ok := false
	_ = a.form(huh.NewGroup(
		huh.NewConfirm().
			Title("⚠ Essa não é a chave que o projeto usa").
			Description("Impressão digital desta chave:\n" + info.Fingerprint +
				"\n\nO projeto espera (" + fingerprintFile + "):\n" + expected +
				"\n\nAPKs assinados com ela não instalam por cima das versões de teste.").
			Affirmative("Instalar mesmo assim").
			Negative("Cancelar").
			Value(&ok),
	)).Run()
	return ok
}

// confirmReplace asks before overwriting a different installed key (the old
// one is kept as .bak).
func (a *app) confirmReplace(info KeyInfo) bool {
	current := check(a.paths)
	if !current.KeystoreFound || current.Info.Fingerprint == info.Fingerprint {
		return true
	}
	ok := false
	_ = a.form(huh.NewGroup(
		huh.NewConfirm().
			Title("Já existe outra chave neste computador").
			Description("Ela será guardada como " + filepath.Base(a.paths.Keystore) + ".bak.").
			Affirmative("Substituir").
			Negative("Cancelar").
			Value(&ok),
	)).Run()
	if ok {
		_ = os.Rename(a.paths.Keystore, a.paths.Keystore+".bak")
	}
	return ok
}

func expandHome(path string) string {
	path = strings.TrimSpace(path)
	if strings.HasPrefix(path, "~") {
		if home, err := os.UserHomeDir(); err == nil {
			return filepath.Join(home, strings.TrimPrefix(path, "~"))
		}
	}
	return path
}

// ---------------------------------------------------------------- Bitwarden

// unlockBitwarden makes sure we have a session: logs in (interactive, with
// 2FA) and unlocks with the master password when needed.
func (a *app) unlockBitwarden() error {
	if a.session != "" {
		return nil
	}
	state, err := bwStatus()
	if err != nil {
		return err
	}
	if state == bwUnauthenticated {
		login := true
		if err := a.form(huh.NewGroup(huh.NewConfirm().
			Title("Você não está logado no Bitwarden CLI").
			Description("Vou rodar `bw login` (e-mail, senha mestra e 2FA).").
			Affirmative("Fazer login").Negative("Cancelar").
			Value(&login))).Run(); err != nil || !login {
			return huh.ErrUserAborted
		}
		if err := runInteractive("bw", "login"); err != nil {
			return errors.New("o login no Bitwarden não terminou")
		}
	}
	var master string
	if err := a.form(huh.NewGroup(huh.NewInput().
		Title("Senha mestra do Bitwarden").
		Description("Para desbloquear o cofre só durante esta sessão.").
		EchoMode(huh.EchoModePassword).
		Value(&master))).Run(); err != nil {
		return err
	}
	return spinner.New().Title("Desbloqueando o Bitwarden…").Action(func() {
		a.session, err = bwUnlock(master)
	}).Run()
}

func (a *app) pickBitwardenItem() (bwItem, error) {
	if err := a.unlockBitwarden(); err != nil {
		return bwItem{}, err
	}
	if a.session == "" {
		return bwItem{}, errors.New("não consegui desbloquear o Bitwarden")
	}
	var items []bwItem
	var err error
	_ = spinner.New().Title("Procurando a chave no Bitwarden…").Action(func() {
		items, err = bwSearch(a.session, "OBS Pad")
	}).Run()
	if err != nil {
		return bwItem{}, err
	}
	switch len(items) {
	case 0:
		return bwItem{}, fmt.Errorf("nenhum item com \"OBS Pad\" no nome. O backup se chama \"%s\"", bwItemName)
	case 1:
		return items[0], nil
	}
	options := make([]huh.Option[int], len(items))
	for i, item := range items {
		options[i] = huh.NewOption(item.Name, i)
	}
	var chosen int
	err = a.form(huh.NewGroup(huh.NewSelect[int]().
		Title("Qual item tem a chave?").Options(options...).Value(&chosen))).Run()
	return items[chosen], err
}

func (a *app) backup() error {
	if !hasCommand("bw") {
		return errors.New("o bw (Bitwarden CLI) não está instalado: https://bitwarden.com/help/cli/\nSem ele, veja \"Backup manual\" em docs/assinatura-android.md")
	}
	keystore, password, info, err := a.installedKey()
	if err != nil {
		return err
	}
	if err := a.unlockBitwarden(); err != nil {
		return err
	}
	var existing *bwItem
	items, _ := bwSearch(a.session, bwItemName)
	for i := range items {
		if items[i].Name == bwItemName {
			existing = &items[i]
		}
	}
	if existing != nil {
		replace := false
		if err := a.form(huh.NewGroup(huh.NewConfirm().
			Title("Já existe um backup no Bitwarden").
			Description("Substituir pelo da chave deste computador (" + shortFP(info.Fingerprint) + ")?").
			Affirmative("Substituir").Negative("Cancelar").Value(&replace))).Run(); err != nil || !replace {
			return huh.ErrUserAborted
		}
	}
	err = spinner.New().Title("Salvando no Bitwarden…").Action(func() {
		err = bwSave(a.session, keystore, password, info.Fingerprint, existing)
		if err == nil {
			_, _ = run(nil, nil, "bw", "sync", "--session", a.session)
		}
	}).Run()
	if err != nil {
		return err
	}
	box(lipgloss.Color("#3FB950"),
		good.Render("✔ Backup salvo no Bitwarden"),
		"",
		"Item: "+bwItemName+" (nota segura)",
		dim.Render("Chave nas notas (base64), senha no campo oculto storePassword."))
	return nil
}

// installedKey reads the key installed on this computer.
func (a *app) installedKey() ([]byte, string, KeyInfo, error) {
	keystore, err := os.ReadFile(a.paths.Keystore)
	if err != nil {
		return nil, "", KeyInfo{}, errors.New("a chave não está instalada neste computador. Restaure primeiro")
	}
	props, err := readProperties(a.paths.Properties)
	if err != nil {
		return nil, "", KeyInfo{}, errors.New("falta " + a.paths.Properties + ". Restaure a chave de novo")
	}
	info, err := inspectKey(keystore, props["storePassword"])
	return keystore, props["storePassword"], info, err
}

// ------------------------------------------------------------------- GitHub

func (a *app) updateSecrets() error {
	if !hasCommand("gh") {
		return errors.New("o gh (GitHub CLI) não está instalado: https://cli.github.com")
	}
	if !ghLoggedIn() {
		return errors.New("o gh não está logado. Rode `gh auth login` e tente de novo")
	}
	if a.paths.ProjectRoot == "" {
		return errors.New("rode dentro do projeto OBS Pad para saber qual repositório atualizar")
	}
	keystore, password, info, err := a.installedKey()
	if err != nil {
		return err
	}
	repo, err := ghRepo(a.paths.ProjectRoot)
	if err != nil {
		return err
	}
	expected := expectedFingerprint(a.paths.ProjectRoot)
	description := "Os builds automáticos passam a assinar com esta chave (" + shortFP(info.Fingerprint) + ")."
	if expected != "" && expected != info.Fingerprint {
		description += "\n\n" + warn.Render("⚠ Ela é diferente da que está em "+fingerprintFile+".") +
			"\nQuem já instalou uma versão de teste vai precisar desinstalar uma vez." +
			"\nDepois, faça commit do novo " + fingerprintFile + "."
	}
	ok := false
	if err := a.form(huh.NewGroup(huh.NewConfirm().
		Title("Atualizar os secrets de " + repo + "?").
		Description(description + "\n\nSecrets: " + secretKeystore + ", " + secretPassword).
		Affirmative("Atualizar").Negative("Cancelar").Value(&ok))).Run(); err != nil || !ok {
		return huh.ErrUserAborted
	}
	err = spinner.New().Title("Enviando para o GitHub…").Action(func() {
		err = ghSetSecrets(repo, keystore, password)
	}).Run()
	if err != nil {
		return err
	}
	box(lipgloss.Color("#3FB950"),
		good.Render("✔ Secrets atualizados em "+repo),
		"",
		"O próximo push na main publica a versão de teste com esta chave.",
		dim.Render("Para publicar já: Actions › Build apps › re-run do último build da main."))
	return nil
}

// ---------------------------------------------------------------- new key

func (a *app) createNew() error {
	ok := false
	if err := a.form(huh.NewGroup(huh.NewConfirm().
		Title("Criar uma chave nova?").
		Description("Só faça isso se a chave antiga foi perdida (sem backup).\n\n" +
			"Quem já instalou uma versão de teste vai precisar desinstalar uma vez\n" +
			"(perde os botões e sons configurados).").
		Affirmative("Criar chave nova").Negative("Cancelar").Value(&ok))).Run(); err != nil || !ok {
		return huh.ErrUserAborted
	}
	var keystore []byte
	var password string
	var info KeyInfo
	var err error
	_ = spinner.New().Title("Gerando a chave (RSA 4096)…").Action(func() {
		keystore, password, err = generateKey()
		if err == nil {
			info, err = inspectKey(keystore, password)
		}
	}).Run()
	if err != nil {
		return err
	}
	if !a.confirmReplace(info) {
		return huh.ErrUserAborted
	}
	if err := install(a.paths, keystore, password); err != nil {
		return err
	}
	if a.paths.ProjectRoot != "" {
		if err := os.WriteFile(filepath.Join(a.paths.ProjectRoot, fingerprintFile),
			[]byte(info.Fingerprint+"\n"), 0o644); err != nil {
			return err
		}
	}
	box(lipgloss.Color("#3FB950"),
		good.Render("✔ Chave nova criada e instalada"),
		"",
		"Impressão digital: "+info.Fingerprint,
		"",
		"Próximos passos (neste menu):",
		"  1. Fazer backup no Bitwarden",
		"  2. Atualizar os secrets do GitHub",
		"  3. Commit de "+fingerprintFile)
	return nil
}

// --------------------------------------------------------------- report/help

func (a *app) printReport(r Report) {
	mark := func(ok bool, yes, no string) string {
		if ok {
			return good.Render("✔ ") + yes
		}
		return bad.Render("✘ ") + no
	}
	lines := []string{
		title.Render("Verificação"),
		"",
		mark(r.KeystoreFound, "Arquivo da chave: "+short(a.paths.Keystore), "Falta o arquivo da chave ("+short(a.paths.Keystore)+")"),
		mark(r.PropertiesFound, "Configuração: "+short(a.paths.Properties), "Falta "+short(a.paths.Properties)),
	}
	if r.KeystoreFound && r.PropertiesFound {
		lines = append(lines, mark(r.OpenError == nil, "A senha abre a chave", "A chave não abre: "+fmt.Sprint(r.OpenError)))
	}
	if r.OpenError == nil && r.KeystoreFound {
		switch {
		case r.Expected == "":
			lines = append(lines, warn.Render("? ")+"Impressão digital "+r.Info.Fingerprint+dim.Render(" (fora do projeto: sem comparar)"))
		default:
			lines = append(lines, mark(r.Matches(), "É a chave do projeto ("+shortFP(r.Expected)+")",
				"NÃO é a chave do projeto: "+shortFP(r.Info.Fingerprint)+" ≠ "+shortFP(r.Expected)))
		}
	}
	if r.ProjectPropsPath != "" {
		lines = append(lines, mark(r.ProjectLinked, "O projeto usa esta chave (android/key.properties)",
			"O projeto não está ligado a ela: escolha \"Restaurar\" de novo"))
	}
	color := lipgloss.Color("#3FB950")
	if !r.OK() {
		color = lipgloss.Color("#F85149")
		lines = append(lines, "", "Para resolver: \"Restaurar a chave neste computador\".")
	}
	box(color, lines...)
}

func (a *app) help() {
	box(accent,
		title.Render("O que é essa chave?"),
		"",
		"Todo APK é assinado. O Android só instala uma versão por cima da outra",
		"se as duas tiverem a mesma assinatura. Esta é a chave das versões de",
		"teste (pré-lançamento \"dev\" no GitHub) — não é a da Play Store.",
		"",
		"Ela fica em três lugares:",
		"  • neste computador: "+short(a.paths.Dir),
		"  • no GitHub: secrets "+secretKeystore+" e "+secretPassword,
		"  • no backup: Bitwarden, item \""+bwItemName+"\"",
		"",
		"Só precisa dela num computador para gerar APKs que instalem por cima",
		"das versões do GitHub. Para programar e testar, não precisa.",
		"",
		dim.Render("Guia completo: docs/assinatura-android.md"),
	)
}
