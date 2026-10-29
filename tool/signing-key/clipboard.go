package main

import (
	"os"

	"github.com/atotto/clipboard"
	"github.com/aymanbagabas/go-osc52/v2"
)

type copyMethod int

const (
	copiedSystem   copyMethod = iota // wl-copy, xclip, xsel, pbcopy, Windows
	copiedTerminal                   // OSC 52: the terminal copies (works over SSH)
)

// copyText puts text on the clipboard: the system one when available,
// otherwise asks the terminal to do it (OSC 52), which can't be confirmed.
func copyText(text string) copyMethod {
	if err := clipboard.WriteAll(text); err == nil {
		return copiedSystem
	}
	seq := osc52.New(text)
	if os.Getenv("TMUX") != "" {
		seq = seq.Tmux()
	}
	_, _ = seq.WriteTo(os.Stderr)
	return copiedTerminal
}

// clearClipboard removes the secret from the clipboard at the end.
func clearClipboard() {
	if err := clipboard.WriteAll(""); err != nil {
		seq := osc52.New("")
		if os.Getenv("TMUX") != "" {
			seq = seq.Tmux()
		}
		_, _ = seq.WriteTo(os.Stderr)
	}
}
