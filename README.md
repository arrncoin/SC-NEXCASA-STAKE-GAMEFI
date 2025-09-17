# NexCasa Game Staking Project V1

Dokumentasi resmi untuk deployment ekosistem **NexCasa Game + Staking** di jaringan `nexus`.

---

## 🚀 Deploy Token

Jalankan perintah berikut:

```bash
npx hardhat run scripts/deployTokens.js --network nexus
```

### Contoh hasil deploy:

- **NexcasaToken ($NEXCASA)** → `0xa09B15252831D47cF85c159bC72cfC45F0D1bBEB`  
- **CustomERC20 (ncBTC)** → `0xA1A5987Cc7da36f4606A2a9F00DEb66A4e37734F`  
- **CustomERC20 (ncETH)** → `0x7ceC127e4c5793BaeA2C5da5e8b6086f0D3A23f5`  
- **CustomERC20 (ncUSDT)** → `0x7729Cbf0F8745fc5698adbD5B2D27b8C3C1ab23f`  
- **CustomERC20 (ncUSDC)** → `0x1381ceB65a8e6769658e84291CF28782bE4C2668`  

---

## ✅ Verifikasi Token

### Verifikasi manual:

```bash
npx hardhat verify --network nexus <ALAMAT_TOKEN> <SUPPLY>
```

**Contoh:**

```bash
npx hardhat verify --network nexus 0xa09B15252831D47cF85c159bC72cfC45F0D1bBEB 250000000000000000000000000
```

### Verifikasi melalui script:

```bash
npx hardhat run scripts/verifyTokens.js --network nexus
```

---

## 🏗 Deploy Kontrak Inti (Game + Staking)

Deploy kontrak inti:

```bash
npx hardhat run scripts/deployCore.js --network nexus
```

### Contoh hasil deploy:

- **NexCasaNFT** → `0xBaF3a4713E4655e13850bc47948A5D04DC4d3304`  
- **NexCasaGameStaking** → `0x8E04B4DF3deb5A34DA4daF69C9c83a8F36073777`  
- **NexCasaNFTStaking** → `0x60Edf6DF345cCE085839AC42c66DAa8c26e019FB`  

### Verifikasi kontrak:

```bash
npx hardhat verify --network nexus 0xBaF3a4713E4655e13850bc47948A5D04DC4d3304
```

---

## 💧 Deploy Kontrak Faucet

Deploy faucet:

```bash
npx hardhat run scripts/deployFaucet.js --network nexus
```

### Verifikasi kontrak faucet:

```bash
npx hardhat verify --network nexus <SMART_CONTRACT> <OWNER_ADDRESS>
```

**Contoh:**

```bash
npx hardhat verify --network nexus 0xcB169BdBE884D15622A70214Ee04bec17be3fCE7 0x11Cde369597203f385BC164E64E34e1F520E1983
```

---

## 🔧 Konfigurasi Akhir (Final Step)

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
