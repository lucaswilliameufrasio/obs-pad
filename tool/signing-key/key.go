package main

import (
	"bufio"
	"bytes"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"

	"software.sslmate.com/src/go-pkcs12"
)

// Alias of the key inside the keystore (also used by the CI workflow).
const keyAlias = "obs-pad-dev"

const (
	keystoreName   = "obs-pad-dev.jks"
	propertiesName = "key.properties"
	// Committed: the public fingerprint every test APK is signed with.
	fingerprintFile = "android/signing/dev-key.sha256"
)

var (
	errWrongPassword = errors.New("senha errada para essa chave")
	errNotKeystore   = errors.New("isso não é um arquivo de chave (.jks/PKCS12) válido")
)

// Paths where the key lives on this computer and in the project.
type Paths struct {
	Dir        string // ~/.config/obs-pad
	Keystore   string // ~/.config/obs-pad/obs-pad-dev.jks
	Properties string // ~/.config/obs-pad/key.properties
	// android/key.properties in the project, or "" outside the project.
	ProjectProperties string
	ProjectRoot       string
}

func defaultPaths(projectRoot string) (Paths, error) {
	dir, err := configDir()
	if err != nil {
		return Paths{}, err
	}
	p := Paths{
		Dir:         dir,
		Keystore:    filepath.Join(dir, keystoreName),
		Properties:  filepath.Join(dir, propertiesName),
		ProjectRoot: projectRoot,
	}
	if projectRoot != "" {
		p.ProjectProperties = filepath.Join(projectRoot, "android", propertiesName)
	}
	return p, nil
}

// ~/.config/obs-pad on Linux and macOS, %APPDATA%\obs-pad on Windows.
func configDir() (string, error) {
	if runtime.GOOS == "windows" {
		if appData := os.Getenv("APPDATA"); appData != "" {
			return filepath.Join(appData, "obs-pad"), nil
		}
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(home, ".config", "obs-pad"), nil
}

// findProjectRoot walks up from dir looking for the OBS Pad pubspec.yaml.
func findProjectRoot(dir string) string {
	for {
		data, err := os.ReadFile(filepath.Join(dir, "pubspec.yaml"))
		if err == nil && bytes.Contains(data, []byte("name: obs_pad\n")) {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return ""
		}
		dir = parent
	}
}

// KeyInfo is what we learn from opening a keystore.
type KeyInfo struct {
	Fingerprint string // SHA-256, AA:BB:... like keytool prints it
	Subject     string
}

// inspectKey opens the keystore with the password.
func inspectKey(keystore []byte, password string) (KeyInfo, error) {
	_, cert, _, err := pkcs12.DecodeChain(keystore, password)
	if err != nil {
		if errors.Is(err, pkcs12.ErrIncorrectPassword) {
			return KeyInfo{}, errWrongPassword
		}
		return KeyInfo{}, fmt.Errorf("%w (%v)", errNotKeystore, err)
	}
	return KeyInfo{
		Fingerprint: formatFingerprint(sha256.Sum256(cert.Raw)),
		Subject:     cert.Subject.String(),
	}, nil
}

func formatFingerprint(sum [32]byte) string {
	parts := make([]string, len(sum))
	for i, b := range sum {
		parts[i] = fmt.Sprintf("%02X", b)
	}
	return strings.Join(parts, ":")
}

// expectedFingerprint is the committed fingerprint, or "" if unknown.
func expectedFingerprint(projectRoot string) string {
	if projectRoot == "" {
		return ""
	}
	data, err := os.ReadFile(filepath.Join(projectRoot, fingerprintFile))
	if err != nil {
		return ""
	}
	return normalizeFingerprint(string(data))
}

func normalizeFingerprint(s string) string {
	return strings.ToUpper(strings.TrimSpace(s))
}

var nonBase64 = regexp.MustCompile(`[^A-Za-z0-9+/=]`)

// decodePasted turns the text saved in the password manager back into the
// keystore bytes. Spaces and line breaks from copy/paste are ignored.
func decodePasted(text string) ([]byte, error) {
	clean := nonBase64.ReplaceAllString(text, "")
	if clean == "" {
		return nil, errors.New("nada colado")
	}
	data, err := base64.StdEncoding.DecodeString(clean)
	// A real key is ~4 KB; anything tiny is a partial or wrong paste.
	if err != nil || len(data) < 1000 {
		return nil, errors.New("o texto colado não é a chave inteira (copiou a nota toda?)")
	}
	return data, nil
}

func propertiesFor(keystorePath, password string) string {
	// Gradle reads this as a Java properties file: escape backslashes
	// (Windows paths) and keep everything on one line.
	escape := func(s string) string { return strings.ReplaceAll(s, `\`, `\\`) }
	return fmt.Sprintf(
		"storeFile=%s\nstorePassword=%s\nkeyAlias=%s\nkeyPassword=%s\n",
		escape(keystorePath), escape(password), keyAlias, escape(password),
	)
}

func readProperties(path string) (map[string]string, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	props := map[string]string{}
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		key, value, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}
		props[strings.TrimSpace(key)] = strings.ReplaceAll(strings.TrimSpace(value), `\\`, `\`)
	}
	return props, scanner.Err()
}

// install writes the keystore and key.properties (private files) and links
// the project to them.
func install(p Paths, keystore []byte, password string) error {
	if err := os.MkdirAll(p.Dir, 0o700); err != nil {
		return err
	}
	if err := writePrivate(p.Keystore, keystore); err != nil {
		return err
	}
	props := []byte(propertiesFor(p.Keystore, password))
	if err := writePrivate(p.Properties, props); err != nil {
		return err
	}
	if p.ProjectProperties != "" {
		return writePrivate(p.ProjectProperties, props)
	}
	return nil
}

// writePrivate replaces path atomically with a file only the user can read.
func writePrivate(path string, data []byte) error {
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, 0o600); err != nil {
		return err
	}
	if err := os.Chmod(tmp, 0o600); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

// Report is the result of checking what is installed.
type Report struct {
	KeystoreFound    bool
	PropertiesFound  bool
	Info             KeyInfo
	OpenError        error
	Expected         string
	ProjectLinked    bool // android/key.properties points to the keystore
	ProjectPropsPath string
}

func (r Report) Matches() bool {
	return r.Expected != "" && r.Info.Fingerprint == r.Expected
}

func (r Report) OK() bool {
	return r.KeystoreFound && r.PropertiesFound && r.OpenError == nil &&
		(r.Expected == "" || r.Matches())
}

func check(p Paths) Report {
	r := Report{
		Expected:         expectedFingerprint(p.ProjectRoot),
		ProjectPropsPath: p.ProjectProperties,
	}
	keystore, err := os.ReadFile(p.Keystore)
	r.KeystoreFound = err == nil
	props, err := readProperties(p.Properties)
	r.PropertiesFound = err == nil
	if r.KeystoreFound && r.PropertiesFound {
		r.Info, r.OpenError = inspectKey(keystore, props["storePassword"])
	}
	if p.ProjectProperties != "" {
		if projectProps, err := readProperties(p.ProjectProperties); err == nil {
			r.ProjectLinked = sameFile(projectProps["storeFile"], p.Keystore)
		}
	}
	return r
}

func sameFile(a, b string) bool {
	if a == "" || b == "" {
		return false
	}
	ia, errA := os.Stat(a)
	ib, errB := os.Stat(b)
	return errA == nil && errB == nil && os.SameFile(ia, ib)
}
