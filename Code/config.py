import os

# Der API-Key wird bevorzugt aus der Umgebungsvariable OPENAI_API_KEY gelesen
# (z. B. über ~/.config/ki-telefon.env beim Autostart per systemd).
# Alternativ kann er hier direkt eingetragen werden – dann aber nicht committen!
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY", "HIER OPENAI API KEY EINTRAGEN")
