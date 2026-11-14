---
version: 1.0.0
name: SI-Posyandu Unified Design System
description: Single Source of Truth Sistem Desain Aplikasi Layanan Kesehatan Komunitas SI-Posyandu (Orang Tua/Wali & Kader).
author: Senior UI/UX Designer & Flutter Design System Architect
date: 2026-11-10
framework: Flutter 3.x / Material 3
---

# SI-Posyandu Unified Design System

Dokumen ini merupakan **Single Source of Truth (SSOT)** untuk seluruh keputusan visual, komponen, interaksi, dan tata letak aplikasi **SI-Posyandu**. Seluruh halaman Flutter, widget, dialog, dan form wajib mematuhi standar dalam dokumen ini.

---

## 1. Prinsip Desain (Design Principles)

1. **Tenang, Bersih, dan Terpercaya (Calm & Trustworthy)**
   - Mengutamakan kenyamanan visual bagi pengguna di lingkungan pelayanan kesehatan.
   - Permukaan kartu putih bersih, latar netral, tanpa gradien mencolok, tanpa ornamen ilustrasi berlebihan.
   - Desain datar (*flat design*) dengan batas garis tipis (*divider 1px*), tanpa *heavy drop-shadow*.
2. **Keterbacaan Universal (Universal Readability & Accessibility - WCAG AA/AAA)**
   - Teks isi minimal 14 sp, label minimal 12 sp, tidak ada font di bawah 12 sp.
   - Kontras warna teks terhadap latar belakang minimal 4.5:1 (sebagian besar >= 6:1 hingga 11.6:1).
   - Seluruh target interaksi sentuh (*touch target*) minimal 48 × 48 dp (`AppSize.touch`).
3. **Status Multimodal (Never Color Alone)**
   - Setiap indikator status wajib memadukan tiga elemen: **Ikon + Teks + Warna Latar/Teks** (`StatusChip`).
   - Tidak pernah menyampaikan status medis atau peringatan hanya melalui perbedaan warna.
4. **Dua Peran, Satu Sistem (Dual Role, Unified System)**
   - Peran **Orang Tua** dan **Kader** memiliki warna penanda peran masing-masing, namun berbagi satu fondasi netral, tipografi, skala spacing, border radius, dan pustaka komponen yang identik.
   - Komponen reusable mengambil warna dari `Theme.of(context).colorScheme`, sehingga komponen yang sama otomatis adaptif sesuai konteks peran.
5. **Jujur pada Data Kesehatan (Honest Health Data)**
   - Aplikasi tidak menampilkan grafik atau interpretasi kurva standar WHO yang dibuat-buat jika data klinis KMS lengkap belum tersedia.
   - Form input catatan baru tidak menyisipkan *default value* fiktif yang rentan tersimpan tanpa pengukuran aktual.

---

## 2. Color System & Contrast Ratios

### A. Palet Peran (Role Palettes)

| Peran | Token | Hex | Rasio Kontras | Peruntukan |
|---|---|---|---|---|
| **Orang Tua** | `AppColors.parent` | `#1261A0` | 6.5:1 vs putih | Warna primer Orang Tua, tombol aktif, ikon utama |
| **Orang Tua** | `AppColors.parentTint` | `#E3EEF8` | 5.5:1 vs `#1261A0` | Latar tab nav aktif, badge, kontainer terpilih |
| **Orang Tua** | `AppColors.parentMid` | `#A99BCF` | 2.5:1 (Dekoratif) | Lavender aksen sekunder (dilarang jadi latar teks biru) |
| **Kader** | `AppColors.kader` | `#1D4ED8` | 6.7:1 vs putih | Warna primer Kader, tombol aksi, takik FAB |
| **Kader** | `AppColors.kaderMid` | `#DBEAFE` | 5.5:1 vs `#1D4ED8` | Latar tab nav aktif, badge kader, kontainer terpilih |
| **Kader** | `AppColors.kaderSoft` | `#EFF6FF` | Netral lembut | Alternatif surface kader |

### B. Warna Netral & Permukaan (Neutral & Surface)

| Token | Hex | Rasio Kontras | Peruntukan |
|---|---|---|---|
| `AppColors.background` | `#F4F1FA` | Netral kanvas | Latar belakang scaffold seluruh halaman |
| `AppColors.surface` | `#FFFFFF` | 11.6:1 vs text | Latar kartu, dialog, input, bottom sheet |
| `AppColors.text` | `#123B5D` | 11.6:1 vs putih | Teks utama, judul, angka pengukuran |
| `AppColors.secondaryText` | `#526277` | 6.2:1 vs putih | Teks pendukung, subtitle, deskripsi artikel |
| `AppColors.mutedText` | `#5F6F82` | 5.1:1 vs putih | Hint input, ikon non-aktif, label nav pasif |
| `AppColors.divider` | `#E2E8F0` | 1px border | Border kartu, garis pemisah, outline input |

### C. Warna Status Fungsional (`AppStatus`)

| Status | Foreground | Background | Ikon | Rasio |
|---|---|---|---|---|
| `AppStatus.success` | `#166534` | `#DCFCE7` | `Icons.check_circle_outline_rounded` | 7.4:1 |
| `AppStatus.warning` | `#92400E` | `#FEF3C7` | `Icons.warning_amber_rounded` | 5.8:1 |
| `AppStatus.danger` | `#BE123C` | `#FFE4E6` | `Icons.error_outline_rounded` | 6.1:1 |
| `AppStatus.info` | `#075985` | `#E0F2FE` | `Icons.info_outline_rounded` | 6.9:1 |
| `AppStatus.neutral` | `#475569` | `#EEF2F6` | `Icons.circle_outlined` | 5.2:1 |

---

## 3. Typography System

Menggunakan satu keluarga font tunggal yang ramah, jelas, dan sangat terbaca: **Nunito** (`google_fonts: ^8.2.1`). Seluruh penggunaan font dekoratif lama (*Fredoka*) dihentikan sepenuhnya.

| Token | Font Size | Font Weight | Line Height | Penggunaan |
|---|---|---|---|---|
| `AppText.headline` | 24 sp | 800 (Bold) | 1.25 | Judul utama layar auth, nama modul utama |
| `AppText.title` | 20 sp | 800 (Bold) | 1.30 | Judul AppBar, SectionHeader, dialog title |
| `AppText.subtitle` | 16 sp | 700 (SemiBold) | 1.35 | Judul kartu data anak, subjudul halaman |
| `AppText.bodyLarge` | 16 sp | 500 (Medium) | 1.50 | Isian form input (`AppTextField`), picker |
| `AppText.body` | 14 sp | 500 (Medium) | 1.50 | Teks isi artikel, deskripsi, pesan notifikasi |
| `AppText.label` | 14 sp | 800 (Bold) | 1.30 | Teks tombol (`AppButton`), label input di atas kolom |
| `AppText.caption` | 12 sp | 600 (SemiBold) | 1.40 | Label navigasi bawah, tanggal, status chip, helper |

*Catatan: Ukuran teks minimal adalah 12 sp. Desain wajib responsif terhadap sistem font scaling 130% - 200%.*

---

## 4. Spacing, Elevation & Radius

### A. Skala Spacing (`AppSpace`)
- `AppSpace.xs` = 4 dp (Jarak mikro antara ikon dan teks kecil)
- `AppSpace.sm` = 8 dp (Jarak antar chip, gap dalam grup kecil)
- `AppSpace.md` = 12 dp (Jarak vertikal form field, padding internal tile)
- `AppSpace.lg` = 16 dp (Padding standar kartu, margin komponen)
- `AppSpace.xl` = 24 dp (Jarak antar seksi halaman, padding modal)
- `AppSpace.xxl` = 32 dp (Jarak antar blok konten besar)
- `AppSpace.page` = 20 dp (Padding horizontal standar layar)

### B. Border Radius (`AppRadius`)
- `AppRadius.control` = **12 dp** (Tombol, textfield input, container filter)
- `AppRadius.card` = **16 dp** (Kartu data, dialog modal, bottom sheet)
- `AppRadius.pill` = **999 dp** (Chip pilihan tunggal, badge status, avatar bulat)
*Aturan: Nilai radius acak seperti 14, 18, 20, 24, 26 tidak diperkenankan.*

### C. Elevasi & Bayangan (Elevation & Shadows)
- Seluruh kartu data menggunakan **Flat Surface** (`elevation: 0`, warna `AppColors.surface`, dibatasi garis `AppColors.divider` 1px).
- Tidak menggunakan drop-shadow berat pada kartu konten.

---

## 5. Komponen Inti (`lib/widgets/app_components.dart`)

1. **`AppButton`**
   - Mendukung 3 varian: `primary` (Filled), `secondary` (Outlined), `text` (TextButton).
   - Dilengkapi `isLoading` dengan `CircularProgressIndicator` ukuran 18dp yang mencegah *double-tap* tanpa merusak kontras.
   - Area sentuh minimal 48dp tinggi.
2. **`AppTextField`**
   - Label selalu terlihat di atas kolom input (bukan floating label yang mudah luput).
   - Dilengkapi bantuan teks (`helper`), pesan error ramah multi-baris, dan toggle visibilitas kata sandi dengan Semantics.
3. **`AppCard`**
   - Kartu datar dengan batas `AppColors.divider`, mendukung ripple effect `InkWell` bila interaktif.
4. **`StatusChip`**
   - Label status multimodal (Ikon + Teks + Warna background dari `AppStatus`).
5. **`SectionHeader`**
   - Header bagian konten dengan judul tebal dan tautan aksi opsional di sisi kanan.
6. **`EmptyState` & `ErrorState`**
   - Penjelasan visual dan verbal ketika data kosong atau gagal dimuat, dilengkapi tombol aksi/coba lagi yang jelas.
7. **`InitialsAvatar`**
   - Avatar berbasis inisial nama anak dengan palet warna terdeterminasi stabil (`AppColors.avatarPairs`). Menggantikan ilustrasi kartun lama.
8. **`ServiceTile` & `ServiceGrid`**
   - Navigasi menu layanan dua kolom fleksibel (`IntrinsicHeight`) yang tahan saat font diperbesar.
9. **`AppSearchField`**
   - Kolom pencarian instan inline di halaman dengan ikon pencarian dan tombol pembersih cepat.
10. **`MeasurementField`**
    - Input pengukuran berat/tinggi badan dengan verifikasi rentang medis dan tombol koreksi cepat (- / +).
11. **`AppPickerTile`**
    - Baris pemilih tanggal atau anak dengan target sentuh penuh dan label aksesibilitas.
12. **`InlineMessage`**
    - Pesan inline di dalam dialog atau modal bottom sheet (mencegah Snackbar tertutup bottom sheet).
13. **`showConfirmDialog`**
    - Dialog konfirmasi tindakan penting (khususnya keluar akun dan hapus data anak/pemeriksaan) dengan penanda `destructive`.

---

## 6. Standar Navigasi Bawah

- **Orang Tua (5 Tab):** Beranda | Anak | Jadwal | Artikel | Profil
- **Kader (5 Elemen):** Beranda | Anak | [Catat Gizi - Center FAB] | Jadwal | Profil
- **Indikator Aktif:** Tiga penanda simultan: pil tint latar, ikon terisi (*filled*), dan label teks berbobot tebal (800). Area sentuh per tab >= 48dp.

---

## 7. Bahasa & Interaksi Antarmuka (Copywriting & UX Micro-copy)

- **Sapaan Netral & Inklusif:** Menggunakan sapaan `"Bapak/Ibu"` atau nama profil pengguna. Kata sapaan khusus gender seperti `"Bunda"` ditiadakan agar netral bagi seluruh wali anak.
- **Sapaan Waktu Otomatis:** Menggunakan helper `greetingNow()` (Selamat pagi/siang/sore/malam berdasarkan jam sistem).
- **Pesan Keberhasilan Spesifik:** Menyebutkan objek secara langsung (contoh: *"Catatan gizi Budi berhasil disimpan"*), bukan sekadar *"Berhasil"* atau *"Sukses!"*.
- **Pesan Kesalahan Manusiawi:** Menggunakan `friendlyError(error)` yang menjelaskan apa yang terjadi dan tindakan korektif yang dapat dilakukan pengguna tanpa mengekspos kode exception teknis.
- **Konfirmasi Aksi Destruktif:** Menampilkan konfirmasi sebelum keluar akun (*logout*) atau menghapus data riwayat.

---

## 8. Status Migrasi Halaman Flutter

| Halaman | File | Status Desain | Catatan Evaluasi |
|---|---|---|---|
| **Login** | `lib/pages/login_page.dart` | Sesuai Standar | Menggunakan `AuthShell`, `AppTextField`, `friendlyError` |
| **Register** | `lib/pages/register_page.dart` | Sesuai Standar | Menggunakan `AuthShell`, validasi form, pemilihan peran |
| **Home Ortu** | `lib/pages/home_ortu_page.dart` | Sesuai Standar | Ringkasan anak realtime, ServiceGrid, konfirmasi logout |
| **Home Kader** | `lib/pages/home_kader_page.dart` | Sesuai Standar | KaderHeroCard, KaderCenterFab, ringkasan Posyandu |
| **Data Anak** | `lib/pages/data_anak_page.dart` | Sesuai Standar | AppSearchField, InitialsAvatar, aksi peran sesuai aturan |
| **Pemeriksaan** | `lib/pages/pemeriksaan_page.dart` | Sesuai Standar | MeasurementField, validasi rentang gizi, InlineMessage |
| **Imunisasi** | `lib/pages/imunisasi_page.dart` | Sesuai Standar | ChoiceChipGroup vaksin, date picker, peringatan tanggal |
| **Jadwal** | `lib/pages/jadwal_page.dart` | Sesuai Standar | Terbagi Akan Datang & Riwayat Lewat, StatusChip Hari ini |
| **Riwayat** | `lib/pages/riwayat_page.dart` | Sesuai Standar | Pengelompokan bulanan, urutan terbaru di atas |
| **Perkembangan** | `lib/pages/perkembangan_page.dart` | Sesuai Standar | Grafik jujur tanpa kurva palsu, ringkasan teks Semantics |
| **Artikel** | `lib/pages/artikel_page.dart` | **PERLU DIRETROFIT** | Mengandung 'Bunda', warna acak, border radius 18, shadow |
| **Profil** | `lib/pages/profil_page.dart` | **PERLU DIRETROFIT** | Mengandung Fredoka, raw $error, logout tanpa konfirmasi |
| **Auth Widgets** | `lib/pages/auth_widgets.dart` | **KODE MATI** | Tidak dipakai, siap dibersihkan pada tahap persetujuan |
| **Menu Card** | `lib/widgets/menu_card.dart` | **KODE MATI** | Tidak dipakai, siap dibersihkan pada tahap persetujuan |
