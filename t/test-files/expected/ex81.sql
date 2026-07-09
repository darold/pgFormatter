CREATE TABLE example (
    id         serial PRIMARY KEY,                                -- some comment
    name       varchar(100)             NOT NULL,                 -- another comment
    email      varchar(100)             NOT NULL,                 -- third comment
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP -- last comment
);

CREATE TABLE queue_job (
    id            uuid PRIMARY KEY          DEFAULT gen_random_uuid(),
    parent_job_id uuid             REFERENCES queue_job (id) ON DELETE SET NULL,
    status        queue_job_status NOT NULL DEFAULT 'queued',
    payload       jsonb            NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT queue_job_status_check CHECK (status <> 'invalid')
);
