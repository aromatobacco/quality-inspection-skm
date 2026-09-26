# Patch tren physical SKM v2.0.3

Skala vertikal grafik Berat, Diameter, Pressure Drop, dan Ventilasi sekarang mengikuti rentang spesifikasi serta nilai aktual dengan ruang 18% di atas/bawah. Selisih kecil terlihat jelas; titik di luar spesifikasi dan garis LSL/USL tetap tampil. Grafik persentase tetap memakai 0–100%.

Login, data multi user Supabase, status, warning poin, dan ekspor tetap sama. **SQL tidak perlu dijalankan ulang.**

Ganti `index.html` dan `skm-app.js` di root repo dalam satu commit. Setelah deployment Pages selesai, cek footer `v2.0.3` dan muat ulang halaman.
