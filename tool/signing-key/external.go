package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// Name of the Bitwarden item holding the key (secure note).
const bwItemName = "OBS Pad – chave de testes Android"

// GitHub secrets read by .github/workflows/build.yml.
const (
	secretKeystore = "ANDROID_DEV_KEYSTORE_BASE64"
	secretPassword = "ANDROID_DEV_KEYSTORE_PASSWORD"
)

func hasCommand(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

// run executes a command and returns stdout; stderr goes into the error.
func run(stdin []byte, env []string, name string, args ...string) ([]byte, error) {
	cmd := exec.Command(name, args...)
	if stdin != nil {
		cmd.Stdin = bytes.NewReader(stdin)
	}
	if env != nil {
		cmd.Env = append(os.Environ(), env...)
	}
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		msg := strings.TrimSpace(stderr.String())
		if msg == "" {
			msg = err.Error()
		}
		return nil, fmt.Errorf("%s: %s", name, msg)
	}
	return stdout.Bytes(), nil
}

// runInteractive hands the terminal to a command (e.g. `bw login`).
func runInteractive(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	return cmd.Run()
}

// ---------------------------------------------------------------- Bitwarden

type bwState string

const (
	bwUnauthenticated bwState = "unauthenticated"
	bwLocked          bwState = "locked"
	bwUnlocked        bwState = "unlocked"
)

func bwStatus() (bwState, error) {
	out, err := run(nil, nil, "bw", "status")
	if err != nil {
		return "", err
	}
	var status struct {
		Status bwState `json:"status"`
	}
	if err := json.Unmarshal(out, &status); err != nil {
		return "", fmt.Errorf("bw status: %w", err)
	}
	return status.Status, nil
}

// bwUnlock returns a session key. The master password goes through an
// environment variable, never the command line (visible in `ps`).
func bwUnlock(masterPassword string) (string, error) {
	out, err := run(nil, []string{"OBSPAD_BW_PASSWORD=" + masterPassword},
		"bw", "unlock", "--raw", "--passwordenv", "OBSPAD_BW_PASSWORD")
	if err != nil {
		return "", errors.New("não consegui desbloquear o Bitwarden (senha mestra errada?)")
	}
	return strings.TrimSpace(string(out)), nil
}

type bwField struct {
	Name  string `json:"name"`
	Value string `json:"value"`
	Type  int    `json:"type"` // 0 text, 1 hidden
}

type bwAttachment struct {
	ID       string `json:"id"`
	FileName string `json:"fileName"`
}

type bwItem struct {
	ID          string         `json:"id"`
	Name        string         `json:"name"`
	Notes       string         `json:"notes"`
	Fields      []bwField      `json:"fields"`
	Attachments []bwAttachment `json:"attachments"`
}

func (i bwItem) field(name string) string {
	for _, f := range i.Fields {
		if strings.EqualFold(f.Name, name) {
			return f.Value
		}
	}
	return ""
}

func bwSearch(session, query string) ([]bwItem, error) {
	_, _ = run(nil, nil, "bw", "sync", "--session", session)
	out, err := run(nil, nil, "bw", "list", "items", "--search", query, "--session", session)
	if err != nil {
		return nil, err
	}
	var items []bwItem
	return items, json.Unmarshal(out, &items)
}

// bwKeystore gets the key from the item: a .jks attachment (Premium) or
// the base64 text in the notes.
func bwKeystore(session string, item bwItem) ([]byte, error) {
	for _, a := range item.Attachments {
		if strings.HasSuffix(strings.ToLower(a.FileName), ".jks") {
			return run(nil, nil, "bw", "get", "attachment", a.ID,
				"--itemid", item.ID, "--raw", "--session", session)
		}
	}
	if strings.TrimSpace(item.Notes) == "" {
		return nil, errors.New("o item do Bitwarden não tem a chave (nem nas notas, nem anexo .jks)")
	}
	return decodePasted(item.Notes)
}

// bwSave creates (or replaces) the secure note with the key.
func bwSave(session string, keystore []byte, password, fingerprint string, existing *bwItem) error {
	item := map[string]any{
		"type":       2, // secure note
		"name":       bwItemName,
		"secureNote": map[string]any{"type": 0},
		"notes":      base64.StdEncoding.EncodeToString(keystore),
		"fields": []bwField{
			{Name: "storePassword", Value: password, Type: 1},
			{Name: "keyAlias", Value: keyAlias, Type: 0},
			{Name: "SHA-256", Value: fingerprint, Type: 0},
		},
	}
	data, err := json.Marshal(item)
	if err != nil {
		return err
	}
	encoded := []byte(base64.StdEncoding.EncodeToString(data))
	if existing != nil {
		_, err = run(encoded, nil, "bw", "edit", "item", existing.ID, "--session", session)
	} else {
		_, err = run(encoded, nil, "bw", "create", "item", "--session", session)
	}
	return err
}

// ------------------------------------------------------------------- GitHub

func ghLoggedIn() bool {
	_, err := run(nil, nil, "gh", "auth", "status")
	return err == nil
}

func ghRepo(projectRoot string) (string, error) {
	cmd := exec.Command("gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner")
	cmd.Dir = projectRoot
	out, err := cmd.Output()
	if err != nil {
		return "", errors.New("não achei o repositório do GitHub deste projeto")
	}
	return strings.TrimSpace(string(out)), nil
}

// ghSetSecrets replaces the two secrets the build workflow uses. Values go
// through stdin, never the command line.
func ghSetSecrets(repo string, keystore []byte, password string) error {
	if _, err := run([]byte(base64.StdEncoding.EncodeToString(keystore)), nil,
		"gh", "secret", "set", secretKeystore, "-R", repo); err != nil {
		return err
	}
	_, err := run([]byte(password), nil, "gh", "secret", "set", secretPassword, "-R", repo)
	return err
}
