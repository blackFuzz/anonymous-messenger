#!/bin/bash

# === CONFIG ===
DB="users.db"
messages_file="messages.db"
CURRENT_USER=""
CURRENT_PIN=""

# === INIT DBs ===
[ ! -f "$DB" ] && touch "$DB"
[ ! -f "$messages_file" ] && touch "$messages_file"

# === CREATE ACCOUNT ===
create_account() {
  USERNAME="user_$(tr -dc 'a-z0-9' </dev/urandom | head -c6)"
  PIN=$(shuf -i 100000-999999 -n 1)

  echo "$USERNAME:$PIN" >> "$DB"

  CURRENT_USER="$USERNAME"
  CURRENT_PIN="$PIN"

  echo ""
  echo "===[ NEW ACCOUNT CREATED ]==="
  echo "Username: $USERNAME"
  echo "PIN     : $PIN"
  echo "=============================="
  echo "[+] You are now logged in as $CURRENT_USER"
}

# === LOGIN ===
login() {
  echo -n "Enter username: "
  read USER
  echo -n "Enter PIN: "
  read -s PIN_INPUT
  echo ""

  FOUND=$(grep "^$USER:$PIN_INPUT$" "$DB")

  if [ "$FOUND" != "" ]; then
    echo "[+] Login SUCCESS for $USER"
    CURRENT_USER="$USER"
    CURRENT_PIN="$PIN_INPUT"
  else
    echo "[-] Login FAILED"
  fi
}

# === CHANGE USERNAME / PIN ===
change_account() {
  if [ "$CURRENT_USER" = "" ]; then
    echo "[-] You must be logged in."
    return
  fi

  echo ""
  echo "===[ CHANGE USERNAME or PIN ]==="

  echo -n "Change username? (y/n): "
  read CHANGE_USER
  if [ "$CHANGE_USER" = "y" ]; then
    NEWNAME="user_$(tr -dc 'a-z0-9' </dev/urandom | head -c6)"
    sed -i "s/^$CURRENT_USER:$CURRENT_PIN\$/$NEWNAME:$CURRENT_PIN/" "$DB"
    echo "[+] Username changed to $NEWNAME"
    CURRENT_USER="$NEWNAME"
  fi

  echo -n "Change PIN? (y/n): "
  read CHANGE_PIN
  if [ "$CHANGE_PIN" = "y" ]; then
    echo -n "Enter NEW PIN (6 digits): "
    read -s NEWPIN
    echo ""
    sed -i "s/^$CURRENT_USER:$CURRENT_PIN\$/$CURRENT_USER:$NEWPIN/" "$DB"
    echo "[+] PIN updated for $CURRENT_USER"
    CURRENT_PIN="$NEWPIN"
  fi
}

# === MESSAGING ===
messaging() {
  while true; do
    echo ""
    echo "===[ ANONYMOUS MESSAGING ]==="
    echo "1) Send to ROOM"
    echo "2) Send 1-to-1"
    echo "3) View ROOM"
    echo "4) View my 1-to-1 messages"
    echo "99) Back"
    echo -n "Choose: "
    read MSG_CHOICE

    case "$MSG_CHOICE" in
      1)
        echo -n "Write your ROOM message: "
        read MESSAGE
        TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
        echo "$TIMESTAMP | ROOM | $CURRENT_USER : $MESSAGE" >> "$messages_file"
        echo "[+] Room message saved."
        ;;
      2)
        echo -n "To (username): "
        read DEST
        echo -n "Write your PRIVATE message: "
        read MESSAGE
        TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
        echo "$TIMESTAMP | 1TO1 | From: $CURRENT_USER | To: $DEST | $MESSAGE" >> "$messages_file"
        echo "[+] Private message saved."
        ;;
      3)
        echo ""
        echo "===[ ROOM MESSAGES ]==="
        grep "ROOM" "$messages_file"
        ;;
      4)
        echo ""
        echo "===[ YOUR 1-TO-1 MESSAGES ]==="
        grep "1TO1" "$messages_file" | grep "To: $CURRENT_USER"
        ;;
      99)
        echo "Returning..."
        break
        ;;
      *)
        echo "Invalid option."
        ;;
    esac
  done
}

# === VIEW CREDS ===
show_credentials() {
  echo ""
  echo "===[ YOUR IDENTIFIERS ]==="
  echo "Username: $CURRENT_USER"
  echo "PIN     : $CURRENT_PIN"
  echo "==========================="
}

# === LOGOUT ===
logout() {
  echo "[+] User $CURRENT_USER logged out."
  CURRENT_USER=""
  CURRENT_PIN=""
}

# === MAIN MENUS ===

main_menu() {
  while true; do
    echo ""
    echo "========================="
    echo "     ANON MESSENGER      "
    echo "========================="
    echo "1) Create Account"
    echo "2) Login"
    echo "99) Exit"
    echo -n "Choose: "
    read CHOICE

    case "$CHOICE" in
      1) create_account && logged_in_menu ;;
      2) login && [ "$CURRENT_USER" != "" ] && logged_in_menu ;;
      99) echo "Goodbye!" ; exit 0 ;;
      *) echo "Invalid option!" ;;
    esac
  done
}

logged_in_menu() {
  while true; do
    echo ""
    echo "=============================="
    echo "   LOGGED IN AS: $CURRENT_USER"
    echo "=============================="
    echo "1) Change PIN or Username"
    echo "2) Messaging (ROOM + 1-to-1)"
    echo "3) View My Credentials"
    echo "4) Logout"
    echo "99) Exit"
    echo -n "Choose: "
    read CHOICE2

    case "$CHOICE2" in
      1) change_account ;;
      2) messaging ;;
      3) show_credentials ;;
      4) logout; break ;;
      99) echo "Goodbye!" ; exit 0 ;;
      *) echo "Invalid option!" ;;
    esac
  done
}

# === START ===
main_menu
