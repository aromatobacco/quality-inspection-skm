-- QUALITY INSPECTION SKM v2.0 - jalankan di Supabase SQL Editor sebelum mengunggah file web.
-- Tidak menghapus inspeksi atau akun lama. Kompatibel dengan klien v1.6 selama transisi.

-- Migrasi v2 untuk tabel yang sudah mempunyai data.
alter table public.skm_quality_inspections add column if not exists operator_name text not null default '';
alter table public.skm_quality_inspections add column if not exists machine_trouble boolean not null default false;
alter table public.skm_quality_inspections drop constraint if exists skm_quality_inspections_brand_check;
alter table public.skm_quality_inspections add constraint skm_quality_inspections_brand_check
  check (brand in ('AMB','AMT','ARM','ARB','ARB12','ARB16'));
alter table public.skm_quality_inspections drop constraint if exists skm_quality_inspections_sample_count_check;
alter table public.skm_quality_inspections add constraint skm_quality_inspections_sample_count_check
  check ((machine_trouble and station='Maker' and sample_count=0) or
         (not machine_trouble and sample_count between 1 and 10000));

create or replace function public.skm_api_request(
  p_path text,
  p_method text default 'GET',
  p_payload jsonb default '{}'::jsonb,
  p_session_token text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user public.skm_app_users%rowtype;
  v_target public.skm_app_users%rowtype;
  v_record public.skm_quality_inspections%rowtype;
  v_method text := upper(coalesce(p_method,'GET'));
  v_payload jsonb := coalesce(p_payload,'{}'::jsonb);
  v_result jsonb;
  v_token text;
  v_token_hash text;
  v_id uuid;
  v_failed integer;
begin
  delete from public.skm_app_sessions where expires_at <= now();

  if p_path='/api/auth/status' and v_method='GET' then
    if coalesce(p_session_token,'')='' then
      return jsonb_build_object('user',null,'needsBootstrap',not exists(select 1 from public.skm_app_users));
    end if;
    select u.* into v_user from public.skm_app_sessions s
      join public.skm_app_users u on u.id=s.user_id
      where s.token_hash=encode(extensions.digest(p_session_token,'sha256'),'hex')
        and s.expires_at>now() and u.is_active;
    if not found then
      return jsonb_build_object('user',null,'needsBootstrap',not exists(select 1 from public.skm_app_users),'clearSession',true);
    end if;
    return jsonb_build_object('needsBootstrap',false,'user',jsonb_build_object(
      'id',v_user.id,'displayName',v_user.display_name,'username',v_user.username,
      'role',v_user.role,'isActive',v_user.is_active));
  end if;

  if p_path='/api/auth/bootstrap' and v_method='POST' then
    lock table public.skm_app_users in exclusive mode;
    if exists(select 1 from public.skm_app_users) then
      return jsonb_build_object('__error','Admin pertama sudah dibuat. Silakan login.','__status',409);
    end if;
    if length(trim(coalesce(v_payload->>'displayName','')))<2 then
      return jsonb_build_object('__error','Nama Admin wajib diisi.','__status',400);
    end if;
    if trim(coalesce(v_payload->>'username','')) !~ '^[A-Za-z0-9._-]{3,40}$' then
      return jsonb_build_object('__error','Username harus 3–40 karakter: huruf, angka, titik, garis bawah, atau strip.','__status',400);
    end if;
    if length(coalesce(v_payload->>'password',''))<8
       or coalesce(v_payload->>'password','') !~ '[A-Za-z]'
       or coalesce(v_payload->>'password','') !~ '[0-9]' then
      return jsonb_build_object('__error','Password minimal 8 karakter serta mengandung huruf dan angka.','__status',400);
    end if;
    insert into public.skm_app_users(display_name,username,password_hash,role,is_active)
    values(trim(v_payload->>'displayName'),lower(trim(v_payload->>'username')),
      extensions.crypt(v_payload->>'password',extensions.gen_salt('bf',10)),'ADMIN',true)
    returning * into v_user;
    v_token:=encode(extensions.gen_random_bytes(32),'hex');
    v_token_hash:=encode(extensions.digest(v_token,'sha256'),'hex');
    insert into public.skm_app_sessions(token_hash,user_id,expires_at)
    values(v_token_hash,v_user.id,now()+interval '12 hours');
    return jsonb_build_object('sessionToken',v_token,'user',jsonb_build_object(
      'id',v_user.id,'displayName',v_user.display_name,'username',v_user.username,
      'role',v_user.role,'isActive',v_user.is_active));
  end if;

  if p_path='/api/auth/login' and v_method='POST' then
    select * into v_target from public.skm_app_users
      where lower(username)=lower(trim(coalesce(v_payload->>'username',''))) limit 1;
    if not found or not v_target.is_active then
      return jsonb_build_object('__error','Username atau password salah, atau akun nonaktif.','__status',401);
    end if;
    if v_target.locked_until is not null and v_target.locked_until>now() then
      return jsonb_build_object('__error','Akun dikunci sementara. Coba lagi 15 menit kemudian.','__status',429);
    end if;
    if v_target.password_hash<>extensions.crypt(coalesce(v_payload->>'password',''),v_target.password_hash) then
      v_failed:=coalesce(v_target.failed_login_count,0)+1;
      update public.skm_app_users set
        failed_login_count=case when v_failed>=5 then 0 else v_failed end,
        locked_until=case when v_failed>=5 then now()+interval '15 minutes' else null end
      where id=v_target.id;
      return jsonb_build_object('__error','Username atau password salah, atau akun nonaktif.','__status',401);
    end if;
    update public.skm_app_users set failed_login_count=0,locked_until=null where id=v_target.id returning * into v_user;
    v_token:=encode(extensions.gen_random_bytes(32),'hex');
    v_token_hash:=encode(extensions.digest(v_token,'sha256'),'hex');
    insert into public.skm_app_sessions(token_hash,user_id,expires_at)
    values(v_token_hash,v_user.id,now()+interval '12 hours');
    return jsonb_build_object('sessionToken',v_token,'user',jsonb_build_object(
      'id',v_user.id,'displayName',v_user.display_name,'username',v_user.username,
      'role',v_user.role,'isActive',v_user.is_active));
  end if;

  if coalesce(p_session_token,'')<>'' then
    select u.* into v_user from public.skm_app_sessions s
      join public.skm_app_users u on u.id=s.user_id
      where s.token_hash=encode(extensions.digest(p_session_token,'sha256'),'hex')
        and s.expires_at>now() and u.is_active;
  end if;
  if v_user.id is null then
    return jsonb_build_object('__error','Sesi berakhir. Silakan login kembali.','__status',401,'clearSession',true);
  end if;

  if p_path='/api/auth/logout' and v_method='POST' then
    delete from public.skm_app_sessions where token_hash=encode(extensions.digest(p_session_token,'sha256'),'hex');
    return jsonb_build_object('ok',true,'clearSession',true);
  end if;

  if p_path='/api/inspections' and v_method='GET' then
    select coalesce(jsonb_agg(item order by item->>'date' desc,item->>'time' desc),'[]'::jsonb) into v_result
    from (select jsonb_build_object(
      'id',i.id,'authorId',i.author_id,'source','Supabase','type',i.station,
      'date',to_char(i.sample_date,'YYYY-MM-DD'),'time',to_char(i.sample_time,'HH24:MI'),
      'qc',i.qc_name,'shift',i.shift,'brand',i.brand,'machine',i.machine,
      'sample',i.sample_count,'physical',i.physical,'visual',i.visual,
      'noFinding',i.no_finding,'trouble',i.trouble_point,'notes',i.notes,
      'operator',i.operator_name,'machineTrouble',i.machine_trouble,
      'code',i.production_code,'cigarettes',i.cigarettes_per_pack,'packCount',i.pack_count
    ) item from public.skm_quality_inspections i) q;
    return jsonb_build_object('inspections',v_result);
  end if;

  if p_path='/api/inspections' and v_method='POST' then
    if v_user.role not in ('ADMIN','INSPECTOR') then
      return jsonb_build_object('__error','Akun viewer tidak memiliki izin mengisi data.','__status',403);
    end if;
    if (v_payload->>'type') not in ('Maker','Packer')
       or (v_payload->>'shift') not in ('Shift 1','Shift 2','Shift 3')
       or ((v_payload->>'type')='Maker' and (v_payload->>'brand') not in ('AMB','AMT','ARM','ARB','ARB12','ARB16'))
       or ((v_payload->>'type')='Packer' and (v_payload->>'brand') not in ('AMB','AMT','ARM','ARB12','ARB16')) then
      return jsonb_build_object('__error','Bagian, shift, atau brand tidak valid.','__status',400);
    end if;
    if coalesce((v_payload->>'machineTrouble')::boolean,false) and
       ((v_payload->>'type')<>'Maker' or coalesce(v_payload->>'sample','')<>'0' or
        trim(coalesce(v_payload->>'trouble',''))='' or trim(coalesce(v_payload->>'notes',''))='') then
      return jsonb_build_object('__error','Machine Trouble Maker memerlukan trouble point dan keterangan tanpa sampel.','__status',400);
    end if;
    insert into public.skm_quality_inspections(
      author_id,station,sample_date,sample_time,qc_name,shift,brand,machine,sample_count,
      physical,visual,no_finding,trouble_point,notes,operator_name,machine_trouble,
      production_code,cigarettes_per_pack,pack_count)
    values(v_user.id,v_payload->>'type',(v_payload->>'date')::date,(v_payload->>'time')::time,
      v_user.display_name,v_payload->>'shift',v_payload->>'brand',v_payload->>'machine',
      (v_payload->>'sample')::integer,coalesce(v_payload->'physical','{}'::jsonb),
      coalesce(v_payload->'visual','{}'::jsonb),coalesce((v_payload->>'noFinding')::boolean,false),
      left(coalesce(v_payload->>'trouble',''),500),left(coalesce(v_payload->>'notes',''),500),
      left(coalesce(v_payload->>'operator',''),60),coalesce((v_payload->>'machineTrouble')::boolean,false),
      left(coalesce(v_payload->>'code',''),100),nullif(v_payload->>'cigarettes','')::integer,
      nullif(v_payload->>'packCount','')::integer)
    returning * into v_record;
    return jsonb_build_object('id',v_record.id);
  end if;

  if p_path ~ '^/api/inspections/[0-9a-fA-F-]+$' and v_method='PATCH' then
    v_id:=split_part(p_path,'/',4)::uuid;
    select * into v_record from public.skm_quality_inspections where id=v_id;
    if not found then return jsonb_build_object('__error','Data inspeksi tidak ditemukan.','__status',404); end if;
    if v_user.role<>'ADMIN' and not (v_user.role='INSPECTOR' and v_record.author_id=v_user.id) then
      return jsonb_build_object('__error','Kamu tidak memiliki izin mengubah data ini.','__status',403);
    end if;
    if (v_payload->>'type')<>v_record.station
       or ((v_payload->>'type')='Maker' and (v_payload->>'brand') not in ('AMB','AMT','ARM','ARB','ARB12','ARB16'))
       or ((v_payload->>'type')='Packer' and (v_payload->>'brand') not in ('AMB','AMT','ARM','ARB12','ARB16')) then
      return jsonb_build_object('__error','Bagian atau brand tidak valid.','__status',400);
    end if;
    if coalesce((v_payload->>'machineTrouble')::boolean,false) and
       (v_record.station<>'Maker' or coalesce(v_payload->>'sample','')<>'0' or
        trim(coalesce(v_payload->>'trouble',''))='' or trim(coalesce(v_payload->>'notes',''))='') then
      return jsonb_build_object('__error','Machine Trouble Maker memerlukan trouble point dan keterangan tanpa sampel.','__status',400);
    end if;
    update public.skm_quality_inspections set
      sample_date=(v_payload->>'date')::date,sample_time=(v_payload->>'time')::time,
      shift=v_payload->>'shift',brand=v_payload->>'brand',machine=v_payload->>'machine',
      sample_count=(v_payload->>'sample')::integer,
      physical=coalesce(v_payload->'physical','{}'::jsonb),visual=coalesce(v_payload->'visual','{}'::jsonb),
      no_finding=coalesce((v_payload->>'noFinding')::boolean,false),trouble_point=left(coalesce(v_payload->>'trouble',''),500),
      notes=left(coalesce(v_payload->>'notes',''),500),operator_name=left(coalesce(v_payload->>'operator',''),60),
      machine_trouble=coalesce((v_payload->>'machineTrouble')::boolean,false)
    where id=v_id;
    return jsonb_build_object('ok',true);
  end if;

  if p_path ~ '^/api/inspections/[0-9a-fA-F-]+$' and v_method='DELETE' then
    v_id:=split_part(p_path,'/',4)::uuid;
    select * into v_record from public.skm_quality_inspections where id=v_id;
    if not found then return jsonb_build_object('__error','Data inspeksi tidak ditemukan.','__status',404); end if;
    if v_user.role<>'ADMIN' and not (v_user.role='INSPECTOR' and v_record.author_id=v_user.id) then
      return jsonb_build_object('__error','Kamu tidak memiliki izin menghapus data ini.','__status',403);
    end if;
    delete from public.skm_quality_inspections where id=v_id;
    return jsonb_build_object('ok',true);
  end if;

  if p_path='/api/users' and v_method='GET' then
    if v_user.role<>'ADMIN' then return jsonb_build_object('__error','Hanya Admin yang dapat melihat akun.','__status',403); end if;
    select coalesce(jsonb_agg(jsonb_build_object(
      'id',id,'displayName',display_name,'username',username,'role',role,'isActive',is_active
    ) order by created_at),'[]'::jsonb) into v_result from public.skm_app_users;
    return jsonb_build_object('users',v_result);
  end if;

  if p_path='/api/users' and v_method='POST' then
    if v_user.role<>'ADMIN' then return jsonb_build_object('__error','Hanya Admin yang dapat membuat akun.','__status',403); end if;
    if length(trim(coalesce(v_payload->>'displayName','')))<2
       or trim(coalesce(v_payload->>'username','')) !~ '^[A-Za-z0-9._-]{3,40}$'
       or coalesce(v_payload->>'role','') not in ('ADMIN','INSPECTOR','GUEST_INTERNAL','GUEST_EXTERNAL') then
      return jsonb_build_object('__error','Nama, username, atau role akun tidak valid.','__status',400);
    end if;
    if length(coalesce(v_payload->>'password',''))<8
       or coalesce(v_payload->>'password','') !~ '[A-Za-z]'
       or coalesce(v_payload->>'password','') !~ '[0-9]' then
      return jsonb_build_object('__error','Password minimal 8 karakter serta mengandung huruf dan angka.','__status',400);
    end if;
    begin
      insert into public.skm_app_users(display_name,username,password_hash,role,is_active)
      values(trim(v_payload->>'displayName'),lower(trim(v_payload->>'username')),
        extensions.crypt(v_payload->>'password',extensions.gen_salt('bf',10)),v_payload->>'role',true)
      returning * into v_target;
    exception when unique_violation then
      return jsonb_build_object('__error','Username sudah dipakai.','__status',409);
    end;
    return jsonb_build_object('id',v_target.id);
  end if;

  if p_path ~ '^/api/users/[0-9a-fA-F-]+$' and v_method='PATCH' then
    if v_user.role<>'ADMIN' then return jsonb_build_object('__error','Hanya Admin yang dapat mengubah akun.','__status',403); end if;
    v_id:=split_part(p_path,'/',4)::uuid;
    if v_id=v_user.id and coalesce((v_payload->>'isActive')::boolean,true)=false then
      return jsonb_build_object('__error','Admin tidak dapat menonaktifkan akunnya sendiri.','__status',400);
    end if;
    update public.skm_app_users set is_active=coalesce((v_payload->>'isActive')::boolean,is_active) where id=v_id;
    if not found then return jsonb_build_object('__error','Akun tidak ditemukan.','__status',404); end if;
    if coalesce((v_payload->>'isActive')::boolean,true)=false then
      delete from public.skm_app_sessions where user_id=v_id;
    end if;
    return jsonb_build_object('ok',true);
  end if;

  return jsonb_build_object('__error','Endpoint tidak ditemukan.','__status',404);
exception when others then
  return jsonb_build_object('__error','Database gagal memproses permintaan: '||sqlerrm,'__status',500);
end;
$$;

