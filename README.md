# SKM multi user — warning poin v2.0.2

Perbaikan final: warning di dashboard, halaman Maker/Packaging, dan tabel Data Inspeksi hanya menampilkan poin trouble singkat. Nilai asli tetap tersimpan di Supabase dan dapat diekspor ke Excel. Login, role, dan database tidak berubah.

Ganti `index.html` dan `skm-app.js` di root repo GitHub Pages dalam satu commit. Jangan jalankan SQL lagi jika migrasi v2.0 sebelumnya sudah berhasil. Setelah deploy, cek footer `v2.0.2` lalu muat ulang halaman.
