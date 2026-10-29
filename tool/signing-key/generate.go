package main

import (
	"crypto/rand"
	"errors"
	"math/big"
	"os"
	"path/filepath"
)

// generateKey creates a new test signing key with the JDK's keytool (needed
// for Android builds anyway). keytool sets the alias Gradle looks for.
func generateKey() (keystore []byte, password string, err error) {
	if !hasCommand("keytool") {
		return nil, "", errors.New("precisa do Java (keytool) instalado — o mesmo usado para compilar o Android")
	}
	password, err = randomPassword(32)
	if err != nil {
		return nil, "", err
	}
	dir, err := os.MkdirTemp("", "obs-pad-key-")
	if err != nil {
		return nil, "", err
	}
	defer os.RemoveAll(dir)
	path := filepath.Join(dir, keystoreName)
	_, err = run(nil, []string{"OBSPAD_KEY_PASSWORD=" + password},
		"keytool", "-genkeypair",
		"-keystore", path, "-storetype", "PKCS12",
		"-alias", keyAlias, "-keyalg", "RSA", "-keysize", "4096",
		"-validity", "10000",
		"-dname", "CN=OBS Pad dev build, O=OBS Pad",
		// Passwords from the environment, not visible in `ps`.
		"-storepass:env", "OBSPAD_KEY_PASSWORD",
		"-keypass:env", "OBSPAD_KEY_PASSWORD",
	)
	if err != nil {
		return nil, "", err
	}
	keystore, err = os.ReadFile(path)
	return keystore, password, err
}

func randomPassword(length int) (string, error) {
	const chars = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	out := make([]byte, length)
	for i := range out {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(len(chars))))
		if err != nil {
			return "", err
		}
		out[i] = chars[n.Int64()]
	}
	return string(out), nil
}
