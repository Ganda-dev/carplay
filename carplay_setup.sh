#!/bin/bash

# Assicurarsi che lo script venga eseguito come root
if [ "$EUID" -ne 0 ]; then
  echo "Per favore esegui lo script come root."
  exit 1
fi

echo "Automazione configurazione CarPlay - Inizio"

# Aggiornamento dei pacchetti e installazione delle dipendenze principali
echo "Aggiornamento dei pacchetti..."
apt update -y && apt upgrade -y

echo "Installazione di Avahi (Bonjour/mDNS)..."
apt install -y avahi-daemon avahi-utils

echo "Installazione di usbmuxd e libimobiledevice..."
apt install -y usbmuxd libimobiledevice-utils ideviceinstaller

echo "Installazione di GStreamer per decodifica video..."
apt install -y gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad

echo "Installazione di ALSA per gestione audio..."
apt install -y alsa-utils pulseaudio

echo "Installazione di libinput per input..."
apt install -y libinput-tools

# Configurazione di Avahi
echo "Configurazione di Avahi per CarPlay..."
cat <<EOL > /etc/avahi/services/carplay.service
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">CarPlay on %h</name>
  <service>
    <type>_carplay._tcp</type>
    <port>5353</port>
    <txt-record>DeviceName=VirtualCarPlay</txt-record>
    <txt-record>Model=CarPlayEmulator</txt-record>
  </service>
</service-group>
EOL

# Riavviare il servizio Avahi
echo "Riavvio del servizio Avahi..."
systemctl restart avahi-daemon

# Verifica della configurazione Avahi
echo "Verifica dei servizi Bonjour/mDNS disponibili..."
avahi-browse -a | grep _carplay._tcp

# Pairing con iPhone tramite usbmuxd
echo "Preparazione alla connessione USB con iPhone..."
systemctl start usbmuxd
echo "Collega l'iPhone al sistema per continuare."
read -p "Premi INVIO quando il dispositivo è collegato..."

# Test della connessione USB
echo "Verifica della connessione USB con iPhone..."
ideviceinfo
if [ $? -ne 0 ]; then
  echo "Errore: il dispositivo non è stato rilevato. Controlla il collegamento USB."
  exit 1
fi

echo "Pairing con l'iPhone..."
idevicepair pair
if [ $? -ne 0 ]; then
  echo "Errore nel pairing. Assicurati che l'iPhone sia sbloccato e autorizza la connessione."
  exit 1
fi

# Test audio e video
echo "Test di riproduzione audio con ALSA..."
speaker-test -c2 -twav -l1

echo "Test di rendering video con GStreamer..."
gst-launch-1.0 videotestsrc ! autovideosink

echo "Configurazione completata! Il sistema è pronto per testare CarPlay."
echo "Verifica che l'iPhone rilevi il servizio CarPlay sul dispositivo."
