ALTER TABLE public.anak
  ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users (id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS anak_user_id_idx ON public.anak (user_id);

DO $$
DECLARE
  anak_id_type text;
BEGIN
  SELECT format_type(attribute.atttypid, attribute.atttypmod)
    INTO anak_id_type
  FROM pg_attribute AS attribute
  WHERE attribute.attrelid = 'public.anak'::regclass
    AND attribute.attname = 'id'
    AND NOT attribute.attisdropped;

  IF anak_id_type IS NULL THEN
    RAISE EXCEPTION 'public.anak must have an id column';
  END IF;

  IF to_regclass('public.pemeriksaan') IS NULL THEN
    EXECUTE format(
      'CREATE TABLE public.pemeriksaan (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        anak_id %s NOT NULL REFERENCES public.anak (id) ON DELETE CASCADE,
        tanggal date NOT NULL,
        berat_badan numeric NOT NULL,
        tinggi_badan numeric NOT NULL,
        catatan text NOT NULL DEFAULT ''''
      )',
      anak_id_type
    );
  END IF;

  IF to_regclass('public.imunisasi') IS NULL THEN
    EXECUTE format(
      'CREATE TABLE public.imunisasi (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        anak_id %s NOT NULL REFERENCES public.anak (id) ON DELETE CASCADE,
        nama_vaksin text NOT NULL,
        tanggal date NOT NULL,
        keterangan text NOT NULL DEFAULT ''''
      )',
      anak_id_type
    );
  END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.jadwal (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tanggal date NOT NULL,
  waktu text NOT NULL,
  lokasi text NOT NULL
);

DO $$
DECLARE
  target_table text;
  existing_policy record;
BEGIN
  FOREACH target_table IN ARRAY ARRAY[
    'anak',
    'pemeriksaan',
    'imunisasi',
    'jadwal'
  ]
  LOOP
    IF to_regclass(format('public.%I', target_table)) IS NOT NULL THEN
      FOR existing_policy IN
        SELECT policyname
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = target_table
      LOOP
        EXECUTE format(
          'DROP POLICY %I ON public.%I',
          existing_policy.policyname,
          target_table
        );
      END LOOP;

      EXECUTE format(
        'ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',
        target_table
      );
      EXECUTE format(
        'GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated',
        target_table
      );
    END IF;
  END LOOP;
END;
$$;

CREATE POLICY anak_select_owned_or_kader
  ON public.anak FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR lower(auth.jwt() ->> 'email') = 'kader@gmail.com'
  );

CREATE POLICY anak_insert_owned_or_kader
  ON public.anak FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    OR lower(auth.jwt() ->> 'email') = 'kader@gmail.com'
  );

CREATE POLICY anak_update_kader
  ON public.anak FOR UPDATE TO authenticated
  USING (lower(auth.jwt() ->> 'email') = 'kader@gmail.com')
  WITH CHECK (lower(auth.jwt() ->> 'email') = 'kader@gmail.com');

CREATE POLICY anak_delete_kader
  ON public.anak FOR DELETE TO authenticated
  USING (lower(auth.jwt() ->> 'email') = 'kader@gmail.com');

DO $$
DECLARE
  target_table text;
BEGIN
  FOREACH target_table IN ARRAY ARRAY['pemeriksaan', 'imunisasi']
  LOOP
    IF EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = target_table
        AND column_name = 'anak_id'
    ) THEN
      EXECUTE format(
        'CREATE POLICY %I ON public.%I FOR SELECT TO authenticated
         USING (
           EXISTS (
             SELECT 1 FROM public.anak AS child
             WHERE child.id = %I.anak_id
               AND child.user_id = auth.uid()
           )
           OR lower(auth.jwt() ->> ''email'') = ''kader@gmail.com''
         )',
        target_table || '_select_owned_or_kader',
        target_table,
        target_table
      );
      EXECUTE format(
        'CREATE POLICY %I ON public.%I FOR INSERT TO authenticated
         WITH CHECK (lower(auth.jwt() ->> ''email'') = ''kader@gmail.com'')',
        target_table || '_insert_kader',
        target_table
      );
      EXECUTE format(
        'CREATE POLICY %I ON public.%I FOR UPDATE TO authenticated
         USING (lower(auth.jwt() ->> ''email'') = ''kader@gmail.com'')
         WITH CHECK (lower(auth.jwt() ->> ''email'') = ''kader@gmail.com'')',
        target_table || '_update_kader',
        target_table
      );
      EXECUTE format(
        'CREATE POLICY %I ON public.%I FOR DELETE TO authenticated
         USING (lower(auth.jwt() ->> ''email'') = ''kader@gmail.com'')',
        target_table || '_delete_kader',
        target_table
      );
    END IF;
  END LOOP;
END;
$$;

CREATE POLICY jadwal_select_authenticated
  ON public.jadwal FOR SELECT TO authenticated
  USING (true);

CREATE POLICY jadwal_insert_kader
  ON public.jadwal FOR INSERT TO authenticated
  WITH CHECK (lower(auth.jwt() ->> 'email') = 'kader@gmail.com');

CREATE POLICY jadwal_update_kader
  ON public.jadwal FOR UPDATE TO authenticated
  USING (lower(auth.jwt() ->> 'email') = 'kader@gmail.com')
  WITH CHECK (lower(auth.jwt() ->> 'email') = 'kader@gmail.com');

CREATE POLICY jadwal_delete_kader
  ON public.jadwal FOR DELETE TO authenticated
  USING (lower(auth.jwt() ->> 'email') = 'kader@gmail.com');

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'anak'
  ) THEN
    RETURN;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.anak;
  END IF;
END;
$$;
