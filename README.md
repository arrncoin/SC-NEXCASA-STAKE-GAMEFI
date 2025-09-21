# NexCasa Game Staking Project V1

Dokumentasi resmi untuk deployment ekosistem **NexCasa Game + Staking** di jaringan `nexus`.  
🌐 Website: [https://nexcasa.vercel.app/](https://nexcasa.vercel.app/)

---

## 🚀 Deploy Token

Jalankan perintah berikut:

```bash
npx hardhat run scripts/deployTokens.js --network nexus
```

### Contoh hasil deploy

- **NexcasaToken ($NEXCASA)** → `0x9049aab30D49bA7036dA27FA3FC18375b6341b45`  
- **CustomERC20 (ncBTC)** → `0x447335Aa2D62bB917082b3833e56b416e78Ba43c`  
- **CustomERC20 (ncETH)** → `0x3eC1E7ab0328606Bbb0AeDa392979072c830963f`  
- **CustomERC20 (ncUSDT)** → `0x1DDDc56ccd817A0001352A6474255fF9B3DA1713`  
- **CustomERC20 (ncUSDC)** → `0x9E7DD26455cc34Aa538e6C8F970df854f14e3B35`  

---

## ✅ Verifikasi Token

### Verifikasi manual

```bash
npx hardhat verify --network nexus <ALAMAT_TOKEN> <SUPPLY>
```

**Contoh:**

```bash
npx hardhat verify --network nexus 0x9E7DD26455cc34Aa538e6C8F970df854f14e3B35 250000000000000000000000000
```

### Verifikasi melalui script

```bash
npx hardhat run scripts/verifyTokens.js --network nexus
```

---

## 🏗 Deploy Kontrak Inti (Game + Staking)

Deploy kontrak inti:

```bash
npx hardhat run scripts/deployCore.js --network nexus
```

### Contoh hasil deploy

- **NexCasaNFT** → `0x62a647527683824615fc2493059683E44E0A6b1f`  
- **NexCasaGame** → `0xF0C30aA46e3214D639DedBdAb69b6737fEDb47ba`  
- **NexCasaNFTStaking** → `0x532b0D6B16A6B7352924DEfA999D901bD0Aa86Af`  

### Verifikasi kontrak

```bash
npx hardhat verify --network nexus 0x532b0D6B16A6B7352924DEfA999D901bD0Aa86Af
```

---

## 💧 Deploy Kontrak Faucet

Deploy faucet:

```bash
npx hardhat run scripts/deployFaucet.js --network nexus
```

### Verifikasi kontrak faucet

```bash
npx hardhat verify --network nexus <SMART_CONTRACT> <OWNER_ADDRESS>
```

**Contoh:**

```bash
npx hardhat verify --network nexus 0xcB169BdBE884D15622A70214Ee04bec17be3fCE7 0x11Cde369597203f385BC164E64E34e1F520E1983
```

---

## 🔧 Konfigurasi Akhir

Konfigurasi semua kontrak agar saling terhubung:

```bash
npx hardhat run scripts/configureCore.js --network nexus
```

Jika berhasil, akan muncul pesan:

```
Core contracts are now linked and configured.
➡️ ACTION: The system is now technically live. The final step is to set the game rules.
```

---

## 📌 Catatan

- Gunakan **jaringan nexus** untuk semua proses deploy & verifikasi.  
- Pastikan file **.env** sudah berisi `PRIVATE_KEY` & `RPC_URL` nexus.  
- Setelah konfigurasi selesai, sistem siap untuk diatur game rules sesuai mekanisme staking yang diinginkan.  

---

## ✨ Penutup

Dengan semua langkah di atas, ekosistem **Game Staking Project V1** siap dijalankan 🚀

---

## 📢 Kontak

- X: [@kridopratomo90](https://x.com/kridopratomo90)  
- YouTube: [kridopratomo](https://youtube.com/kridopratomo)  
- Telegram: [@KridoPratomo](https://telegram.com/@KridoPratomo)  
