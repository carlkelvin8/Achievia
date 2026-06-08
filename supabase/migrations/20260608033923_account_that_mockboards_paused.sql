CREATE TABLE IF NOT EXISTS public.mockboards_paused (
    id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID NOT NULL,
    quiz_id int NOT NULL,
    current_page INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (quiz_id) REFERENCES public.quizzes(id) on delete CASCADE,
    FOREIGN KEY (user_id) REFERENCES public.profiles(id),
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