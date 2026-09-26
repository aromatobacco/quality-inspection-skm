# SKM Quality Inspection v3.0.2

Perbaikan daftar Master Quality yang kosong: `index.html` kini memanggil `skm-app.js?v=3.0.2`, sehingga browser mengambil JavaScript sesuai layout baru, bukan script v3.0.0 yang tersimpan di cache.

Upload `index.html`, `skm-app.js`, dan `aroma-logo.png` ke root repository GitHub Pages dalam satu commit. Tunggu deployment selesai, lalu muat ulang situs. Pastikan footer menampilkan v3.0.2. `supabase-config.js` yang lama tetap digunakan.

Jika migrasi v3 sudah pernah berhasil dijalankan, tidak perlu menjalankan SQL lagi. Jika belum, jalankan `migration-v3.sql` sesudah migrasi v2. File `migration-v3.sql` dan `skm-api.js` disertakan sebagai referensi pemasangan baru.
