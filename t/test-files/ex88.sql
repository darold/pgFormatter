CREATE FUNCTION preserve_trigger_case() RETURNS tRiGgEr
LANGUAGE plpgsql AS $$
BEGIN
    RETURN NEW;
END;
$$;

CREATE trigger preserve_trigger_case
    BEFORE UPDATE ON accounts
    FOR EACH ROW
    EXECUTE FUNCTION preserve_trigger_case();
