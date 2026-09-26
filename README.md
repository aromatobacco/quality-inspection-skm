# SKM Quality Inspection v3.0.0

## Pasang pembaruan

1. Di Supabase SQL Editor untuk proyek aplikasi yang sekarang, jalankan `migration-v3.sql` **sekali** setelah `migration-v2.sql` dari rilis sebelumnya. Ini menambah tabel master, snapshot standar tiap inspeksi, dan heartbeat pengguna; data dan akun lama tidak dihapus.
2. Upload `index.html` dan `skm-app.js` ke **root repository GitHub Pages yang sama**, dalam satu commit. `skm-api.js` disertakan dan isinya sama seperti rilis v2; boleh ditimpa. Pertahankan `supabase-config.js` yang sudah terpasang, terutama URL dan publishable key.
3. Tunggu deployment GitHub Pages selesai. Buka ulang halaman dengan hard refresh agar `skm-app.js?v=3.0.0` terambil. Masuk sebagai Admin dan buka Pengaturan → Master Quality.

## Pengaturan

- Brand Maker dan Packer terpisah. Setiap brand Maker memiliki LSL/USL untuk berat, diameter, pressure drop, dan ventilasi. Edit kode/standar atau hapus brand melalui daftar.
- Tambah/hapus visual untuk masing-masing station.
- Tambah/edit/hapus status dan persentase minimum. Minimal satu status berambang 0% tetap wajib agar setiap hasil mendapat status. Contoh awal: Good ≥71%, Fair ≥50%, Bad ≥0%.
- Admin melihat daftar akun Online/Offline, jumlah akun, dan aktivitas terakhir. Online berarti ada sesi aktif yang menghubungi aplikasi dalam 3 menit terakhir; pembaruan halaman setiap 1 menit. Logout atau sesi kedaluwarsa menjadi Offline.
- Inspeksi baru menyimpan salinan standar physical dan ambang status. Inspeksi lama tetap memakai standar sebelumnya; penghapusan master tidak menghapus riwayat.

## Pemeriksaan

`node --check skm-app.js` dan tes logika terisolasi lulus. Migrasi SQL perlu dijalankan di Supabase Anda; lingkungan paket ini tidak memiliki koneksi database proyek. Setelah pemasangan, uji dengan dua akun di perangkat berbeda untuk melihat perubahan Online/Offline dan satu input inspeksi baru.
