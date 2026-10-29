package main

import (
	"encoding/base64"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// newKey generates a real keystore once per test run (keytool is slow).
var testKey struct {
	keystore []byte
	password string
	err      error
	done     bool
}

func testKeystore(t *testing.T) ([]byte, string) {
	t.Helper()
	if !hasCommand("keytool") {
		t.Skip("keytool not installed")
	}
	if !testKey.done {
		testKey.keystore, testKey.password, testKey.err = generateKey()
		testKey.done = true
	}
	if testKey.err != nil {
		t.Fatal(testKey.err)
	}
	return testKey.keystore, testKey.password
}

// project creates a fake OBS Pad checkout with the expected fingerprint.
func project(t *testing.T, fingerprint string) string {
	t.Helper()
	root := t.TempDir()
	must(t, os.WriteFile(filepath.Join(root, "pubspec.yaml"), []byte("name: obs_pad\n"), 0o644))
	must(t, os.MkdirAll(filepath.Join(root, "android", "signing"), 0o755))
	if fingerprint != "" {
		must(t, os.WriteFile(filepath.Join(root, fingerprintFile), []byte(fingerprint+"\n"), 0o644))
	}
	return root
}

func pathsIn(t *testing.T, root string) Paths {
	dir := filepath.Join(t.TempDir(), "obs-pad")
	p := Paths{
		Dir:         dir,
		Keystore:    filepath.Join(dir, keystoreName),
		Properties:  filepath.Join(dir, propertiesName),
		ProjectRoot: root,
	}
	if root != "" {
		p.ProjectProperties = filepath.Join(root, "android", propertiesName)
	}
	return p
}

func must(t *testing.T, err error) {
	t.Helper()
	if err != nil {
		t.Fatal(err)
	}
}

func TestGeneratedKeyOpensOnlyWithItsPassword(t *testing.T) {
	keystore, password := testKeystore(t)
	info, err := inspectKey(keystore, password)
	must(t, err)
	if len(strings.Split(info.Fingerprint, ":")) != 32 {
		t.Fatalf("fingerprint %q", info.Fingerprint)
	}
	if !strings.Contains(info.Subject, "OBS Pad dev build") {
		t.Fatalf("subject %q", info.Subject)
	}
	if _, err := inspectKey(keystore, "errada"); !errors.Is(err, errWrongPassword) {
		t.Fatalf("wrong password gave %v", err)
	}
}

func TestGeneratedKeyHasTheAliasGradleUses(t *testing.T) {
	keystore, password := testKeystore(t)
	path := filepath.Join(t.TempDir(), "k.jks")
	must(t, os.WriteFile(path, keystore, 0o600))
	out, err := run(nil, []string{"P=" + password}, "keytool", "-list",
		"-keystore", path, "-storepass:env", "P")
	must(t, err)
	if !strings.Contains(string(out), keyAlias+",") {
		t.Fatalf("alias %q not in:\n%s", keyAlias, out)
	}
}

func TestNotAKeystore(t *testing.T) {
	if _, err := inspectKey([]byte("isso não é uma chave"), "x"); !errors.Is(err, errNotKeystore) {
		t.Fatalf("got %v", err)
	}
}

func TestPastedTextSurvivesCopyPasteMangling(t *testing.T) {
	keystore, _ := testKeystore(t)
	encoded := base64.StdEncoding.EncodeToString(keystore)
	// Line breaks and spaces added by password managers and terminals.
	mangled := "  " + encoded[:100] + "\n" + encoded[100:500] + " \r\n" + encoded[500:] + "\n"
	decoded, err := decodePasted(mangled)
	must(t, err)
	if string(decoded) != string(keystore) {
		t.Fatal("decoded keystore differs")
	}
	if _, err := decodePasted("   "); err == nil {
		t.Fatal("empty paste accepted")
	}
	if _, err := decodePasted("não é base64!!"); err == nil {
		t.Fatal("garbage accepted")
	}
}

func TestInstallThenCheck(t *testing.T) {
	keystore, password := testKeystore(t)
	info, err := inspectKey(keystore, password)
	must(t, err)
	root := project(t, info.Fingerprint)
	p := pathsIn(t, root)

	before := check(p)
	if before.OK() || before.KeystoreFound {
		t.Fatalf("nothing installed yet, got %+v", before)
	}

	must(t, install(p, keystore, password))
	for _, f := range []string{p.Keystore, p.Properties, p.ProjectProperties} {
		st, err := os.Stat(f)
		must(t, err)
		if st.Mode().Perm() != 0o600 {
			t.Errorf("%s has mode %v, want 0600", f, st.Mode().Perm())
		}
	}
	r := check(p)
	if !r.OK() || !r.Matches() || !r.ProjectLinked {
		t.Fatalf("after install: %+v", r)
	}
	props, err := readProperties(p.ProjectProperties)
	must(t, err)
	if props["keyAlias"] != keyAlias || props["storePassword"] != password {
		t.Fatalf("properties %v", props)
	}
}

func TestCheckFlagsAForeignKey(t *testing.T) {
	keystore, password := testKeystore(t)
	root := project(t, "AA:BB")
	p := pathsIn(t, root)
	must(t, install(p, keystore, password))
	r := check(p)
	if r.Matches() || r.OK() {
		t.Fatalf("foreign key passed: %+v", r)
	}
}

func TestCheckFlagsWrongPasswordInProperties(t *testing.T) {
	keystore, _ := testKeystore(t)
	p := pathsIn(t, "")
	must(t, install(p, keystore, "errada"))
	r := check(p)
	if !errors.Is(r.OpenError, errWrongPassword) || r.OK() {
		t.Fatalf("got %+v", r)
	}
}

func TestWindowsPathsAreEscapedForGradle(t *testing.T) {
	text := propertiesFor(`C:\Users\Ana\AppData\Roaming\obs-pad\obs-pad-dev.jks`, `a\b`)
	if !strings.Contains(text, `storeFile=C:\\Users\\Ana\\AppData\\Roaming\\obs-pad\\obs-pad-dev.jks`) {
		t.Fatalf("not escaped:\n%s", text)
	}
	path := filepath.Join(t.TempDir(), "key.properties")
	must(t, os.WriteFile(path, []byte(text), 0o600))
	props, err := readProperties(path)
	must(t, err)
	if props["storePassword"] != `a\b` {
		t.Fatalf("round trip: %q", props["storePassword"])
	}
}

func TestFindProjectRoot(t *testing.T) {
	root := project(t, "")
	deep := filepath.Join(root, "tool", "signing-key")
	must(t, os.MkdirAll(deep, 0o755))
	if got := findProjectRoot(deep); got != root {
		t.Fatalf("got %q want %q", got, root)
	}
	if got := findProjectRoot(t.TempDir()); got != "" {
		t.Fatalf("outside project got %q", got)
	}
}
