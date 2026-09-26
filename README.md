# SKM Quality Inspection v3.0.1

Pembaruan tampilan Pengaturan: kartu ringkas untuk brand Batangan, brand Packaging, parameter visual, status, dan akun; pencarian pada tiap daftar dan dialog tambah/edit. Ikon tab browser menggunakan logo Aroma yang sama dengan header aplikasi.

## Pemasangan

Jika v3.0.0 sudah terpasang dan `migration-v3.sql` sudah berhasil dijalankan, **tidak perlu menjalankan SQL lagi**. Upload `index.html`, `skm-app.js`, dan `aroma-logo.png` ke root repository yang sama dalam satu commit. Jangan menghapus atau mengganti `supabase-config.js`.

Jika v3 belum dipasang, jalankan `migration-v3.sql` di Supabase setelah migrasi v2, lalu upload tiga file web di atas. `skm-api.js` di paket ini sama dengan versi sebelumnya. `migration-v3.sql` juga disertakan untuk pemasangan baru.

Tunggu GitHub Pages selesai deploy, lalu muat ulang halaman. File `index.html` memuat login dan dashboard; `dashboard.html` lama tidak dipakai oleh rilis ini.

Pemeriksaan: sintaks JavaScript, rujukan elemen HTML, dan logika standar dinamis lulus. Integrasi langsung dengan database proyek dan tangkapan layar browser tidak dapat dijalankan di lingkungan ini.
