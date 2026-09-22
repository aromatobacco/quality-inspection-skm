# Dashboard Quality Inspection SKM · v1.2

Paket ini berisi situs SKM mandiri untuk GitHub Pages. Inspeksi Maker dan Packaging disimpan di project Supabase **khusus SKM**. Dashboard harian, mingguan, bulanan, grafik physical, warning produksi, riwayat, dan ekspor CSV membaca data yang tersimpan di sana.

## Isi ZIP

| File | Kegunaan |
| --- | --- |
| `index.html` | Tampilan dan formulir dashboard SKM |
| `skm-app.js` | Login, input, kalkulasi dan pembacaan data Supabase |
| `supabase-config.js` | Tempat URL dan publishable key project SKM |
| `supabase-setup.sql` | Tabel dan aturan akses database SKM |
| `.nojekyll` | File pendukung GitHub Pages |
| `README.md` | Panduan ini |

## 1. Buat project Supabase SKM

Masuk ke [Supabase](https://supabase.com/dashboard), buat **project baru** khusus SKM. Jangan menggunakan project lama SKT (`tsojwuarbstnovotbpdz`). Dengan project terpisah, akun dan tabel SKT tidak terhubung otomatis ke SKM.

## 2. Buat tabel dan aturan akses

Di project SKM, buka **SQL Editor** → buat query baru → salin seluruh isi `supabase-setup.sql` → klik **Run**. Jalankan skrip itu sekali; skrip aman dijalankan lagi jika tabel sudah ada. Database mempunyai dua tabel: `skm_members` untuk daftar akun yang diizinkan dan `skm_inspections` untuk data pemeriksaan.

## 3. Buat akun QC lalu beri akses

Di project SKM, buka **Authentication → Users**, tambah pengguna dengan email dan password. Pastikan akunnya sudah dikonfirmasi agar bisa login dengan password.

Kembali ke **SQL Editor**, jalankan contoh berikut dengan **email akun yang baru dibuat**. Ubah nama dan peran sesuai kebutuhan:

```sql
insert into public.skm_members (user_id, display_name, role, is_active)
select id, 'Natasya Shalomita', 'ADMIN', true
from auth.users
where email = 'email-admin-skm@example.com'
on conflict (user_id) do update set
  display_name = excluded.display_name,
  role = excluded.role,
  is_active = excluded.is_active;
```

Untuk setiap anggota tim SKM lain, ulangi perintah yang sama dengan email masing-masing. Nilai `role`:

| Peran | Akses |
| --- | --- |
| `ADMIN` | Lihat semua, isi, hapus semua inspeksi |
| `QC` | Lihat semua, isi, hapus inspeksi yang dibuat sendiri |
| `VIEWER` | Hanya lihat dashboard, riwayat dan unduh CSV |

Periksa hasilnya dengan `select display_name, role, is_active from public.skm_members;`. Akun yang belum masuk daftar anggota atau sudah dinonaktifkan tidak dapat membaca data SKM. Halaman tidak menyediakan pendaftaran akun sendiri.

## 4. Isi koneksi Supabase

Di dashboard **project SKM**, temukan **Project URL** dan **publishable key** di pengaturan API. Edit `supabase-config.js`:

```js
window.SKM_SUPABASE_CONFIG = {
  url: 'https://nama-project-skm.supabase.co',
  publishableKey: 'sb_publishable_...'
};
```

Gunakan **publishable key** project SKM. Jangan pernah menaruh *secret key* atau *service_role key* di situs. Publishable key dapat dilihat pengunjung halaman; akses data ditentukan oleh login dan kebijakan Row Level Security (RLS) di `supabase-setup.sql`.

## 5. Unggah ke GitHub Pages

Pada repository GitHub **SKM** yang ingin dipakai, unggah empat file ini ke direktori utama repository: `index.html`, `skm-app.js`, `supabase-config.js`, `.nojekyll`. Boleh juga unggah `README.md`; file SQL hanya perlu dijalankan di Supabase dan tidak diperlukan oleh situs.

Di repository, buka **Settings → Pages** → pilih **Deploy from a branch** → branch `main` → folder `/ (root)` → **Save**. Setelah Pages terbit, buka tautan situsnya, login dengan akun SKM, lalu mulai mengisi inspeksi.

Untuk mencoba lokal: dari folder berisi `index.html`, jalankan `python -m http.server 8000` lalu buka `http://localhost:8000`.

## Cek cepat setelah pemasangan

1. Login menggunakan akun yang tercantum pada `skm_members`.
2. Isi satu inspeksi Maker atau Packaging, kemudian simpan.
3. Klik **Segarkan**; inspeksi akan muncul di dashboard dan Data Inspeksi.
4. Buka link yang sama di perangkat lain dengan akun SKM lain; inspeksinya akan tampil juga.
5. Coba akun tanpa keanggotaan SKM; data tidak boleh terbuka.

Data contoh **tidak aktif secara default**, hanya contoh tampilan jika kotak *Tampilkan data contoh* dicentang; tidak masuk database. Riwayat yang sebelumnya tersimpan di `localStorage` pada halaman lama **tidak otomatis dipindahkan** ke Supabase. Situs pada GitHub Pages tetap dapat dibuka hingga halaman login oleh siapa pun yang mempunyai link; **data SKM baru terlihat setelah login akun yang mendapat akses**. Situs membutuhkan internet untuk library Supabase dan koneksi database.

Developed @MT2026 · Last Version: v1.2 · 22 September 2026.
