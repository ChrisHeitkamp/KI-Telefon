![GitHub Logo](http://www.heise.de/make/icons/make_logo.png)

Maker Media GmbH

***

# KI-Telefon

**In diesem Projekt habe ich einem alten „Telekom 611-2“-Tischtelefon neues Leben eingehaucht. Abheben, wählen, sprechen – genau wie früher, nur dass am anderen Ende kein Mensch, sondern eine KI den Hörer abnimmt. Ein Raspberry Pi und die API-Schnittstelle von OpenAI machen Echtzeitgespräche möglich.**

![Aufmacherbild aus dem Heft](./doc/kiTelefon_github.jpg)

Die Benötigten Dateien für das Projekt liegen in diesem GitHub-Repository.

Der vollständige Artikel zum Projekt steht in der **[Make-Ausgabe 2/26](https://www.heise.de/select/make/2026/2)**.

## Update (Mai 2026): Code an die OpenAI Realtime API (GA) angepasst
 
OpenAI hat die bisher genutzte Realtime-API-Beta zum 12. Mai 2026 abgeschaltet und aus der API entfernt. Dadurch funktionierte die ursprüngliche Version dieses Projekts nicht mehr – die Verbindung brach direkt nach dem Session-Update ab („Connection to remote host was lost“).
 
Die Datei openai_ws.py wurde auf die neue GA-Schnittstelle umgestellt. Geändert wurde:
- Der Header „OpenAI-Beta: realtime=v1“ wurde entfernt.
- Das session.update nutzt jetzt die GA-Struktur: "type": "realtime", output_modalities, Audio-Konfiguration unter audio.input / audio.output, Format als Objekt {"type": "audio/pcm", "rate": 24000} (im Input und im Output).
- Die Event-Namen wurden angepasst (response.output_audio.delta, response.output_audio_transcript.done).
- Fehler-Events von OpenAI werden jetzt im Terminal ausgegeben, was die Fehlersuche erleichtert.
 
Das verwendete Modell gpt-realtime-mini bleibt unverändert gültig.

## Autostart beim Booten (systemd)

Das Telefon kann ohne Anmeldung direkt nach dem Booten starten. Unter Raspberry Pi OS Bookworm (Desktop) läuft der Ton über PipeWire in der Sitzung des Benutzers, deshalb wird ein **User-Dienst mit Linger** verwendet.

1. API-Key hinterlegen (statt in `config.py`):
   ```bash
   mkdir -p ~/.config
   cp autostart/ki-telefon.env.example ~/.config/ki-telefon.env
   nano ~/.config/ki-telefon.env      # OPENAI_API_KEY=sk-... eintragen
   chmod 600 ~/.config/ki-telefon.env
   ```
2. Dienst installieren (Pfade in der Datei ggf. anpassen, ohne venv `ExecStart=/usr/bin/python3 main.py`):
   ```bash
   mkdir -p ~/.config/systemd/user
   cp autostart/ki-telefon.service ~/.config/systemd/user/
   sudo loginctl enable-linger pi
   systemctl --user daemon-reload
   systemctl --user enable --now ki-telefon
   ```
3. Log ansehen: `journalctl --user -u ki-telefon -f`

Hinweise:
- USB-Soundkarte als Standardgerät festlegen (`~/.asoundrc` oder `wpctl set-default <ID>`), da sich der Index zwischen Bootvorgängen ändern kann.
- Ziffer 0 (Herunterfahren) braucht `sudo` ohne Passwort für `/sbin/shutdown`.
- Raspberry Pi 5: `sudo apt install python3-rpi-lgpio` als Ersatz für `RPi.GPIO`.
- Raspberry Pi OS Lite ohne PipeWire: alternativ als Systemdienst unter `/etc/systemd/system/` mit `User=pi`, `SupplementaryGroups=gpio audio`, `After=network-online.target` und `Wants=network-online.target`.
