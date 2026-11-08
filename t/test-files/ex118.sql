create trigger part_ins_trig before insert on parted_copytest_a2 for each row execute procedure part_ins_func();
CREATE TRIGGER t BEFORE INSERT ON tab FOR EACH ROW EXECUTE PROCEDURE f();
