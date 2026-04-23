# Cipher

A private, end-to-end encrypted messaging app for Android and iOS, paired with a lightweight Go relay server. The server never sees plaintext — it only routes encrypted blobs between clients.

---

## How It Works

1. Each user generates an asymmetric keypair (Curve25519) stored locally on-device.
2. Messages are encrypted client-side using the recipient's public key before leaving the device.
3. The relay server routes the encrypted payload to the recipient if online, or queues it in PostgreSQL if offline.
4. On reconnection, queued messages are delivered and immediately purged from the server.
5. The server never has access to decryption keys or plaintext content.

---

## Features

### Messaging
- End-to-end encrypted text messages (NaCl Box: Curve25519 + XSalsa20 + Poly1305)
- Message delivery status: sending → delivered → read
- Read receipts
- Message retry on failure

### Contacts
- Add contacts by public key or QR code scan
- Contact request flow (pending / accepted / blocked)
- Block and unblock contacts
- Per-contact display aliases

### Group Chats
- Create encrypted group conversations with any subset of your contacts
- Messages are individually encrypted for each member (no shared group key)
- Group read receipts with per-member tracking
- Invite new members via QR code
- Add or remove members at any time
- Edit group name and group picture
- Leave a group at any time; admins can remove members

### Disappearing Messages
- Set a per-contact auto-delete timer
- Messages are automatically purged locally after the configured duration
- Configurable intervals (e.g. 1 min, 5 min, 15 min, etc.)

### App Lock
- Biometric authentication (fingerprint / face ID)
- Configurable lock timeout when the app is backgrounded
- Per-account setting

### Tor Integration
- Optional routing of all traffic through the Tor network
- SOCKS5 proxy support for the WebSocket connection
- Per-account enable/disable
- Bootstrap progress dialog on first connection

### Traffic Masking
- Sends randomized dummy encrypted traffic at unpredictable intervals (30–120 seconds)
- Prevents traffic analysis or timing-based correlation attacks
- Dummy messages are ignored server-side and never stored

### Multi-Account Support
- Create or import multiple accounts (keypairs)
- Each account has its own separate encrypted SQLite database
- Switch between accounts without data leakage

### Profile
- Set a display nickname shared with contacts
- QR code generation for easy contact sharing
- Profile sync sent automatically when a contact request is accepted

### Offline Message Delivery
- If the recipient is offline, messages are queued (encrypted) on the relay server
- Delivered atomically on next connection and deleted from the server immediately after

---

## Architecture

```
┌─────────────────────────────┐        ┌──────────────────────────────────┐
│     Flutter Mobile App      │        │         Go Relay Server          │
│                             │        │                                  │
│  ┌──────────┐  ┌──────────┐ │  WSS   │  ┌────────┐   ┌───────────────┐  │
│  │  Crypto  │  │   Drift  │ │◄──────►│  │  Hub   │   │  PostgreSQL   │  │
│  │ (sodium) │  │  SQLite  │ │        │  │ Router │──►│ Offline Queue │  │
│  └──────────┘  └──────────┘ │        │  └────────┘   └───────────────┘  │
│  ┌──────────────────────┐   │        │                                  │
│  │  FlutterSecureStorage│   │        │  - Routes encrypted blobs only   │
│  │  (Keychain/Keystore) │   │        │  - Never decrypts anything       │
│  └──────────────────────┘   │        │  - Authenticated via X-App-Secret│
└─────────────────────────────┘        └──────────────────────────────────┘
```

### Flutter App Stack
- **State management**: Riverpod (AsyncNotifier, StreamProvider, family modifiers)
- **Database**: Drift ORM on encrypted SQLite (SQLCipher)
- **Cryptography**: libsodium via `sodium_libs`
- **Secure storage**: `flutter_secure_storage` (Android Keystore / iOS Keychain)
- **Networking**: `web_socket_channel` with optional SOCKS5/Tor proxy
- **Navigation**: `go_router`-style named routes with `CupertinoPageRoute`

### Relay Server Stack
- **Language**: Go
- **WebSocket**: Gorilla WebSocket
- **Database**: PostgreSQL via `pgx` (connection pool)
- **Pattern**: Hub & Spoke — one goroutine per client (read + write pumps)

---

## Project Structure

```

/                        # Flutter mobile app
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── app_router.dart          # Named route definitions
│   │   ├── providers.dart           # Riverpod provider setup
│   │   ├── database/                # Drift tables & migrations
│   │   ├── network/                 # WebSocket service, connection controller, message handler
│   │   └── security/                # Crypto service, secure storage service
│   └── features/
│       ├── app_lock/                # Biometric lock
│       ├── chat/                    # 1-to-1 chat screen & controller
│       ├── contacts/                # Contact management
│       ├── disappearing_messages/   # Auto-delete service
│       ├── groups/                  # Group chat screen, controller & repository
│       ├── key_management/          # Keypair generation & account switching
│       ├── main/                    # Home screen (chats + groups list)
│       ├── mask_traffic/            # Dummy traffic service
│       ├── profile/                 # Profile screen & QR display
│       └── tor/                     # Tor bootstrap & provider
├── assets/
└── pubspec.yaml
```

---

## Setup

### Prerequisites
- Flutter SDK `^3.11.1`
- Go `1.21+`
- PostgreSQL

### Relay Server

```bash
cd chat-relay # from the separate repo dedicated to the server
cp .env.example .env   # fill in APP_SECRET and DB_* values
go run .
```

The server listens on `:8080`. Clients connect to `/ws?pubkey=<hex_public_key>` with the `X-App-Secret` header.

### Flutter App

```bash
cd chat
cp .env.example .env   # set APP_SECRET to match the relay server
flutter pub get
flutter run
```

The app reads the relay server URL from constants in the network layer. By default it connects to `ws://10.0.2.2:8080/ws` (Android emulator) or `ws://127.0.0.1:8080/ws`.

---

## Security Notes

- **Private keys** are stored in the OS keychain/Keystore via `flutter_secure_storage` and loaded into a `sodium.SecureKey` in RAM only when needed.
- **Database encryption**: each account has a separate SQLCipher-encrypted SQLite file with a randomly generated 32-byte key stored in secure storage.
- **The relay server** authenticates connections with a shared `APP_SECRET` header but has no access to any encryption keys or plaintext.
- **Offline messages** stored on the server are encrypted blobs — the server cannot read them and deletes them immediately after delivery.
- Traffic masking and Tor support are opt-in privacy enhancements to reduce metadata leakage.

---

## Message Protocol

All payloads sent over the WebSocket are JSON with an encrypted `encrypted_blob` field. Recognised `type` values:

| Type | Description |
|------|-------------|
| `text` | Regular chat message |
| `contact_request` | Initial contact request (includes sender nickname) |
| `contact_request_accepted` | Acceptance with nickname |
| `profile_sync` | Nickname update pushed to a contact |
| `messages_read` | Read receipt (array of message IDs) |
| `dummy` | Traffic masking — ignored by server |
| `ping` / `disconnect` | Connection lifecycle — ignored by server |
| `group_text` | Encrypted group message sent to each member individually |
| `group_invite` | Invite a contact to join a group (includes group metadata) |
| `group_update` | Group metadata change (name, picture, member add/remove) |
