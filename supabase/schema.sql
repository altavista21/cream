-- Cream admin schema for Supabase
-- Run this file in Supabase SQL Editor. It does not touch existing IndexedDB task records.

create table if not exists public.cream_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.profession_settings (
  slug text primary key,
  title text not null,
  description text not null default '',
  active boolean not null default true,
  sort_order integer not null default 0,
  dashboard_config jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.cream_admin_audit (
  id bigint generated always as identity primary key,
  actor uuid not null references auth.users(id),
  action text not null,
  profession_slug text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.is_cream_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.cream_admins a
    where a.user_id = (select auth.uid())
  );
$$;

alter table public.cream_admins enable row level security;
alter table public.profession_settings enable row level security;
alter table public.cream_admin_audit enable row level security;

drop policy if exists "Cream admins can read their own membership" on public.cream_admins;
create policy "Cream admins can read their own membership"
on public.cream_admins for select to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "Public can read active profession settings" on public.profession_settings;
create policy "Public can read active profession settings"
on public.profession_settings for select to anon, authenticated
using (active = true or public.is_cream_admin());

drop policy if exists "Only Cream admins can insert profession settings" on public.profession_settings;
create policy "Only Cream admins can insert profession settings"
on public.profession_settings for insert to authenticated
with check (public.is_cream_admin());

drop policy if exists "Only Cream admins can update profession settings" on public.profession_settings;
create policy "Only Cream admins can update profession settings"
on public.profession_settings for update to authenticated
using (public.is_cream_admin()) with check (public.is_cream_admin());

drop policy if exists "Only Cream admins can delete profession settings" on public.profession_settings;
create policy "Only Cream admins can delete profession settings"
on public.profession_settings for delete to authenticated
using (public.is_cream_admin());

drop policy if exists "Only Cream admins can read audit log" on public.cream_admin_audit;
create policy "Only Cream admins can read audit log"
on public.cream_admin_audit for select to authenticated
using (public.is_cream_admin());

drop policy if exists "Only Cream admins can insert audit log" on public.cream_admin_audit;
create policy "Only Cream admins can insert audit log"
on public.cream_admin_audit for insert to authenticated
with check (public.is_cream_admin() and actor = (select auth.uid()));

insert into public.profession_settings (slug, title, description, active, sort_order, dashboard_config)
values
('accountants','Accountants','Susun laporan, analisis data, dan periksa kepatuhan dengan lebih mudah bersama Cream.',true,1,'{"categories":["Rekonsiliasi","Pelaporan","Kepatuhan","Administrasi"],"quick":[["file-spreadsheet","Catatan rekonsiliasi","Rekonsiliasi"],["file-text","Laporan keuangan","Pelaporan"],["shield-check","Daftar periksa tutup buku","Kepatuhan"]],"lead":"Kelola rekonsiliasi, laporan keuangan, dokumen, dan daftar periksa penutupan periode.","work":"Meja kerja keuangan","note":"Cocokkan setiap angka dengan dokumen sumber sebelum laporan atau pelaporan resmi digunakan."}'),
('hr','HR Professionals','Permudah proses rekrutmen, susun kebijakan, dan tingkatkan pengalaman karyawan.',true,2,'{"categories":["Rekrutmen","Onboarding","Kebijakan","Administrasi"],"quick":[["user-plus","Rencana onboarding","Onboarding"],["calendar","Jadwal wawancara","Rekrutmen"],["book-open","Tinjauan kebijakan","Kebijakan"]],"lead":"Atur rekrutmen, onboarding, administrasi karyawan, dan tindak lanjut kebijakan.","work":"Operasional SDM","note":"Jaga kerahasiaan data kandidat dan karyawan. Hindari menyimpan data pribadi sensitif yang tidak diperlukan."}'),
('sales','Sales Managers','Tingkatkan penjualan melalui analisis yang lebih baik, tindak lanjut pelanggan, dan dukungan tim.',true,3,'{"categories":["Prospek","Pipeline","Pelanggan","Evaluasi"],"quick":[["mail","Tindak lanjut prospek","Prospek"],["chart-column","Tinjauan pipeline","Pipeline"],["list-check","Evaluasi peluang","Evaluasi"]],"lead":"Catat prospek, tindak lanjut pelanggan, peluang penjualan, dan aktivitas tim.","work":"Pipeline penjualan","note":"Angka penjualan dihitung dari catatan yang kamu masukkan, bukan dari CRM eksternal."}'),
('office','Office Managers','Atur tugas, kelola jadwal, dan tingkatkan kelancaran operasional harian.',true,4,'{"categories":["Jadwal","Inventaris","Fasilitas","Prosedur"],"quick":[["calendar-plus","Rencana rapat","Jadwal"],["package","Daftar kebutuhan kantor","Inventaris"],["clipboard-list","Prosedur kantor","Prosedur"]],"lead":"Koordinasikan jadwal, kebutuhan kantor, permintaan fasilitas, dan pekerjaan administratif.","work":"Operasional kantor","note":"Konfirmasi jadwal, anggaran, dan persetujuan pembelian sebelum melakukan komitmen."}'),
('designers','Designers','Kembangkan ide, buat konten, dan percepat proses kreatif.',true,5,'{"categories":["Konsep","Brief","Produksi","Revisi"],"quick":[["lightbulb","Konsep kreatif","Konsep"],["palette","Brief desain","Brief"],["check-circle","Checklist serah terima","Produksi"]],"lead":"Atur brief kreatif, proyek desain, revisi, umpan balik, dan penyerahan aset.","work":"Meja kerja kreatif","note":"Periksa lisensi aset, aksesibilitas, spesifikasi, dan panduan merek sebelum publikasi."}'),
('financiers','Financiers','Buat simulasi skenario, nilai risiko, dan ambil keputusan berdasarkan data.',true,6,'{"categories":["Analisis","Pemodelan","Risiko","Pelaporan"],"quick":[["calculator","Model skenario","Pemodelan"],["chart-column","Analisis varians","Analisis"],["file-text","Ringkasan eksekutif","Pelaporan"]],"lead":"Kelola analisis kinerja, model skenario, penilaian risiko, dan ringkasan keputusan.","work":"Analisis keuangan","note":"Dokumentasikan sumber dan asumsi. Catatan ini bukan rekomendasi investasi dan tidak menarik data pasar otomatis."}'),
('teachers','Trainers','Rancang sesi pelatihan, siapkan materi pembelajaran, dan pantau perkembangan peserta.',true,7,'{"categories":["Perencanaan","Materi pelatihan","Evaluasi","Tindak lanjut"],"quick":[["book-open","Rencana sesi pelatihan","Perencanaan"],["file-question","Evaluasi pemahaman peserta","Evaluasi"],["clipboard-check","Daftar tindak lanjut peserta","Tindak lanjut"]],"lead":"Rancang sesi pelatihan, siapkan materi, kelola peserta, dan pantau tindak lanjut pembelajaran.","work":"Meja kerja pelatihan","note":"Sesuaikan materi dengan tujuan pelatihan, tingkat kemampuan peserta, aksesibilitas, dan kebutuhan organisasi."}'),
('consultants','Consultants','Sesuaikan penggunaan Cream dengan kebutuhan profesi dan bidang keahlianmu.',true,8,'{"categories":["Riset","Analisis","Pelaporan","Implementasi"],"quick":[["search","Pertanyaan discovery","Riset"],["file-text","Ringkasan eksekutif","Pelaporan"],["route","Rencana aksi","Implementasi"]],"lead":"Susun kebutuhan klien, analisis temuan, rekomendasi, dan rencana implementasi.","work":"Meja kerja konsultasi","note":"Pisahkan fakta dan asumsi, catat sumber, serta jaga kerahasiaan informasi klien."}'),
('real-estate','Real Estate Agents','Kelola informasi properti, pahami kebutuhan klien, dan tindak lanjuti peluang penjualan.',true,9,'{"categories":["Listing","Klien","Kunjungan","Transaksi"],"quick":[["house-plus","Draft listing properti","Listing"],["calendar","Jadwalkan kunjungan","Kunjungan"],["mail","Tindak lanjut klien","Klien"]],"lead":"Kelola listing, kebutuhan klien, jadwal kunjungan, penawaran, dan tenggat transaksi.","work":"Meja kerja properti","note":"Verifikasi detail properti dan izin publikasi. Simpan data klien secukupnya dan secara aman."}')
on conflict (slug) do nothing;

-- Bootstrap one superadmin only AFTER creating the account in Supabase Auth:
-- insert into public.cream_admins (user_id) values ('PASTE_AUTH_USER_UUID_HERE');
