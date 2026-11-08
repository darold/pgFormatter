CREATE TRIGGER part_ins_trig
    BEFORE INSERT ON parted_copytest_a2
    FOR EACH ROW
    EXECUTE PROCEDURE part_ins_func ();

CREATE TRIGGER t
    BEFORE INSERT ON tab
    FOR EACH ROW
    EXECUTE PROCEDURE f ();

