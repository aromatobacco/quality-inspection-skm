# SKM Quality Inspection v3.2.0

Dua pembaruan tampilan yang terpisah:

1. Foto mesin yang diberikan menjadi latar halaman login (panel kiri) dan latar seluruh halaman aplikasi, dengan opacity rendah agar teks dan grafik tetap terbaca.
2. Bagian akun di header kini berupa pill ringkas: indikator Online, nama pengguna, role, dan ikon keluar. Tombol Segarkan dipindah ke baris status sinkronisasi.

## Pemasangan

Upload **`index.html`**, **`skm-app.js`**, dan **`machine-background.png`** ke root repository GitHub Pages yang sama dalam satu commit. File `aroma-logo.png` dan `skm-api.js` disertakan sebagai aset pendukung jika belum ada. Pertahankan `supabase-config.js` yang sudah dipakai.

Perubahan ini **tidak membutuhkan migrasi Supabase baru** bila `migration-v3.1.sql` sudah berhasil dijalankan. SQL yang sama disertakan hanya untuk pemasangan baru. Setelah deployment, muat ulang situs dan pastikan footer v3.2.0.
