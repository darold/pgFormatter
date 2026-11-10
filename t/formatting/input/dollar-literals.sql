-- Multiline data must stay opaque, including inside executable bodies.
select $data${
  "minimum": -90,
  "example": "select CASE when true then 1 END"
}$data$::jsonb;
select $$line one
line two$$, $empty$$empty$;
create function public.literal_sample() returns text language plpgsql as /* function body */ $body$
begin
  -- Dollar tags in comments are not delimiters: $fake$.
  perform $json${
    "type": "object",
    "minimum": -180
  }$json$::jsonb;
  return $text$first line
  second line with 'quotes' and "identifiers"$text$;
end;
$body$;
do $$
begin
  perform $sql$select *
from sample
where name = 'O''Reilly'$sql$;
end;
$$;
