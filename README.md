# Porkbun Dynamic DNS Updater

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/asonnino/porkbun-dns-updater/ci.yml?branch=main&style=for-the-badge&logo=githubactions)
![Static Badge](https://img.shields.io/badge/Bash-v4%2B-blue?style=for-the-badge&logo=gnu-bash&logoColor=white)
![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge)

This is a simple Bash script that automatically updates the A (IPv4) and/or AAAA (IPv6) DNS records for a domain or subdomain registered with [Porkbun](https://porkbun.com). The script detects your machine’s current public IP address and updates the DNS records accordingly. If no record exists, it creates one.

## ✨ Features

- ✅ Automatically detects public **IPv4** and **IPv6** addresses
- ✅ Updates existing DNS A/AAAA records on Porkbun
- ✅ Creates new records if none exist
- ✅ Clean logging with timestamps
- ✅ `.env` support to keep credentials secure and separate
- ✅ Works with both root domain (`@`) and subdomains

## 📦 Requirements

- `bash` (v4+)
- `curl`
- `jq`

Install `jq` if needed:

```bash
# Debian/Ubuntu
sudo apt install jq

# macOS
brew install jq
```

## 🛠️ Setup

### 1. Clone this repo

```bash
git clone https://github.com/asonnino/porkbun-dns-updater.git
cd porkbun-dns-updater
```

### 2. Create your `.env` file

```bash
cp .env.example .env
chmod 600 .env
```

Edit `.env` to match your configuration:

```env
API_KEY=pk1_abc123...
API_SECRET=pk2_def456...
DOMAIN=example.com         # Your root domain
RECORD_NAME=@              # Use "@" for root, or e.g. "home" for home.example.com
TTL=300                    # Optional; default is 300 seconds
```

### 3. Run the script

```bash
chmod +x update_porkbun_dns.sh
./update_porkbun_dns.sh
```

## 🧪 Sample Output

```text
[2025-06-02 14:00:00] Detected A record IP: 203.0.113.45
[2025-06-02 14:00:00] Processing A record for @.example.com → 203.0.113.45
[2025-06-02 14:00:01] Updating existing A record (ID=123456)
[2025-06-02 14:00:01] Porkbun API response: {"status":"SUCCESS"}

[2025-06-02 14:00:02] No external IPv6 detected.
```

Log file: `update_porkbun.log`

## ⚠️ Security Considerations

- **Keep `.env` private.** It contains your Porkbun API keys.
- Never commit `.env` to GitHub or share it publicly.
- Use [Porkbun API manager](https://porkbun.com/account/api) to regenerate your keys if you suspect a leak.

## 🕒 Automation (Optional)

You can run the script automatically using **cron** or **systemd timers**.

### Example: Cron job (every 10 minutes)

```bash
crontab -e
```

Add:

```cron
*/10 * * * * /path/to/update-porkbun-dns.sh > /dev/null
```

## 🙏 Acknowledgments

- [Porkbun API Docs](https://porkbun.com/api/json/v3/documentation)
- [ipify.org](https://www.ipify.org/) for public IP detection
- `jq` for JSON parsing

## 🐛 Issues / Suggestions

Feel free to open issues or submit PRs!

## 📜 License

This project is licensed under the Apache License 2.0.
See the [LICENSE](/LICENSE) file for details.
