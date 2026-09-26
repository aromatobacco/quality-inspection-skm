# SKM multi user v2.0 — pemasangan

Paket ini menggabungkan revisi dashboard dan form ke aplikasi login yang sudah ada. Akun, role, dan inspeksi lama tetap berada di Supabase. `supabase-config.js` dan `skm-api.js` yang sudah ada di repo tidak perlu diubah.

## Urutan pemasangan

1. Di Supabase SQL Editor, jalankan seluruh isi **`migration-v2.sql`**. Migrasi ini menambah kolom operator dan Machine Trouble, memperbolehkan brand ARB pada Maker, dan menambah izin edit melalui endpoint aplikasi. Tidak ada perintah yang menghapus akun atau inspeksi lama.
2. Di root branch yang dipakai GitHub Pages, **ganti** `index.html`, `skm-app.js`, dan `dashboard.html` dengan file bernama sama dari paket ini. Unggah ketiganya dalam satu commit. Jangan unggah folder pembungkus `skm-multiuser-v2` sebagai subfolder. `dashboard.html` mengarahkan pengguna ke aplikasi login sehingga tautan lama tetap menuju halaman multi user.
3. Ganti juga `supabase-setup.sql` di repo agar dokumentasi setup berikutnya sesuai versi baru. Ini tidak perlu dijalankan jika migrasi langkah 1 sudah berhasil.
4. Setelah deployment Pages hijau, buka `https://aromatobacco.github.io/quality-inspection-skm/?v=2.0` dan masuk memakai akun lama. Periksa penanda versi `v2.0` di footer.

## Pemeriksaan singkat

- Login lama tampil; Admin, Inspector, dan Guest memiliki akses sesuai role yang ada.
- Pilih **Dashboard**: ringkasan dan tren empat parameter physical Maker tersedia per brand.
- Di Maker, brand ARB tunggal; Packaging memakai ARB 12 atau ARB 16. Record lama Maker ARB12/16 tetap tampil sebagai ARB.
- Coba input normal dan Machine Trouble. Machine Trouble meminta trouble point serta keterangan dan menyimpan sampel 0.
- Di Data Inspeksi, pilih periode, tanggal, mesin, shift, lalu unduh Excel. Admin atau pemilik record Inspector dapat edit/hapus; Guest hanya membaca sesuai role.

Jika SQL migrasi gagal, jangan unggah file web dahulu. Simpan salinan file repo sebelum mengganti supaya dapat dipulihkan melalui riwayat commit GitHub.
