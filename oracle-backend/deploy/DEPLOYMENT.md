# Deploying HypeMotiv Backend on OCI (Always Free Ubuntu VM)

Target: Oracle Cloud Infrastructure Compute VM.Standard.A1.Flex or
VM.E4.Flex (Always Free), Ubuntu 22.04/24.04. nginx terminates HTTP and proxies
to the Node backend on `127.0.0.1:3000`; systemd keeps it alive.

---

## 1. Create the VM

1. OCI Console → **Compute → Instances → Create instance**.
2. Image: **Ubuntu 22.04 (or 24.04) Minimal**, shape **VM.Standard.A1.Flex**
   (Always Free: 4 OCPU / 24 GB) or **VM.E4.Flex**.
3. Add your SSH public key. Create the instance and note its **public IP**.
4. Wait until `State = Running`.

## 2. Open ingress ports 80 and 443

In the instance's **VCN → Subnet → Default Security List**:

- **Add Ingress Rule** — Source CIDR `0.0.0.0/0`, Destination Port **80** (TCP).
- **Add Ingress Rule** — Source CIDR `0.0.0.0/0`, Destination Port **443** (TCP).

(Opening **22** from your own IP only is recommended for SSH.)
If `iptables`/`ufw` is enabled on the VM, allow HTTP/HTTPS there too:

```bash
sudo ufw allow 80/tcp && sudo ufw allow 443/tcp
```

## 3. Copy the backend to the VM and run setup

From your local machine (the folder containing `oracle-backend/`):

```bash
scp -r oracle-backend ubuntu@<vps-ip>:~/oracle-backend
ssh ubuntu@<vps-ip>
cd ~/oracle-backend
sudo bash deploy/setup-vps.sh
```

The script is idempotent: it installs packages (nodejs/npm/nginx/certbot,
yt-dlp), ensures Node 18+, copies the app to `/opt/hypemotiv/oracle-backend`
without touching your `.env`, runs `npm install --omit=dev`, enables the
`hypemotiv` systemd service and the nginx site, then reloads both.

## 4. Configure the environment

```bash
sudo nano /opt/hypemotiv/oracle-backend/.env
```

At minimum set `PORT=3000`, your `ORACLE_*` values (or leave them blank to run
in local-fallback mode), and optionally `SMTP_*` / `YTDLP_PATH` /
`MAX_UPLOAD_MB`. Then:

```bash
sudo systemctl restart hypemotiv
curl http://127.0.0.1:3000/api/health
```

Check logs with `journalctl -u hypemotiv -f`.

## 5. HTTPS with certbot

Point a DNS A record at the VM IP, then:

```bash
sudo certbot --nginx -d api.example.com
sudo certbot renew --dry-run
```

Certbot rewrites `/etc/nginx/sites-available/hypemotiv` to listen on 443 and
add the certificate paths. Verify:

```bash
curl https://api.example.com/api/health
```

Important for the Flutter client: nginx sends `X-Forwarded-Proto`, and
`server.js` sets `app.set('trust proxy', 1)`, so generated file URLs use
`https://` automatically.

## 6. Oracle Autonomous Database (ATP/ADW)

The Always Free ATP/ADW instance works with this backend in **thin mode** —
`node-oracledb` needs **no Oracle Instant Client for Oracle 12.1+**. Thick mode
is optional (only for older databases or advanced features).

1. In OCI Console: **Oracle Database → Autonomous Database → Create**. Choose
   **Always Free**, workload type **ATP** (or ADW), and set the admin password.
2. When available, click **DB Connection → Wallet download** (use the **Instance
   Wallet**), then copy the wallet file to the VM:

   ```bash
   sudo mkdir -p /opt/hypemotiv/wallet
   scp Wallet_*.zip ubuntu@<vps-ip>:/tmp/wallet.zip
   ssh ubuntu@<vps-ip>
   sudo unzip /tmp/wallet.zip -d /opt/hypemotiv/wallet
   sudo chown -R www-data:www-data /opt/hypemotiv/wallet
   sudo chmod 600 /opt/hypemotiv/wallet/*
   ```

3. Create the schema user in the **OCI console**, not with `CREATE USER`:
   **Database Actions → Users → Create User** (e.g. `HYPEMOTIV`), give it
   `CONNECT`/`RESOURCE` roles and a tablespace quota, and note the password.
4. Edit `/opt/hypemotiv/oracle-backend/.env`:

   ```env
   ORACLE_USER=HYPEMOTIV
   ORACLE_PASSWORD=<the ATP schema password>
   ORACLE_CONNECTSTRING=hypemotiv_low
   WALLET_LOCATION=/opt/hypemotiv/wallet
   TNS_ADMIN=/opt/hypemotiv/wallet
   ```

   (`hypemotiv_low` is a wallet TNS alias — use the alias matching your DB name
   and the `low`/`medium`/`high` consumer group.)

5. Run the schema scripts as the new owner with SQLcl or sqlplus from the VM:

   ```bash
   cd /opt/hypemotiv/oracle-backend
   # db/create-user.sql is for on-prem Oracle only; skip it on ATP/ADW.
   sqlplus /nolog
   SQL> connect HYPEMOTIV@hypemotiv_low
   SQL> @db/schema.sql
   SQL> @db/seed.sql
   ```

6. Restart and verify:

   ```bash
   sudo systemctl restart hypemotiv
   curl http://127.0.0.1:3000/api/health
   # {"status":"ok","oracle":"connected","filesBackend":"oracle", ...}
   curl 'http://127.0.0.1:3000/api/alarms?userId=demo'
   ```

`db/create-user.sql` is for standard Oracle (run as SYSDBA). For on-prem Oracle
also run `db/seed.sql` to populate the demo alarm, five checklist tasks and a
streak of 14 for `user_id='demo'`.

## 7. Build the Flutter app against this backend

```bash
flutter build apk --release \
  --dart-define=HYPE_API_URL=https://api.example.com/api
```

(Use `https://<vps-ip>/api` if you have no domain yet; HTTP works until you
install a certificate. Android clears `http://` traffic requires
`android:usesCleartextTraffic="true"` during local testing.)

The app calls these relative to that base URL: `/health`, `/sounds`,
`/files/upload`, `/files/:id`, `/rip`, and `/email/send`.

## Useful commands

```bash
systemctl status hypemotiv
systemctl restart hypemotiv
nginx -t && systemctl reload nginx
tail -f /opt/hypemotiv/oracle-backend/outbox.log   # demo emails when SMTP is unset
ls -lh /opt/hypemotiv/oracle-backend/uploads       # local BLOB fallback
```

## Notes

- `MAX_UPLOAD_MB` (default 25) must stay below nginx `client_max_body_size`
  (30m) in `deploy/nginx-hypemotiv.conf`.
- `yt-dlp` is only needed for pasted TikTok/Reels/YouTube URLs; direct media
  URLs are downloaded with Node's built-in `fetch`.
- Oracle BLOB storage requires `db/schema.sql` to be run as the HYPEMOTIV
  schema owner. Without it, uploads use the local disk fallback.
