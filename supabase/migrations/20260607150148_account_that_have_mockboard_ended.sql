CREATE TABLE IF NOT EXISTS public.mockboards_paused (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    quiz_id UUID NOT NULL,
    current_page INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.mockboards_paused ENABLE ROW LEVEL SECURITY;

CREATE POLICY "can_access_table_while_authenticated"
ON public.mockboards_paused
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);