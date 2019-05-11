SELECT
    opgt.part_id,
    opgt.art_id,
    rGpe.slot_id,
    rGpe.grp_art_id
FROM (
    SELECT
        id,
        part_product_kind_id
    FROM
        part_product ldm
    WHERE
        nb_colis > 0
        AND statut_part_product IN ('DISPATCH', 'CANCELED', 'SALE_PROD')
        AND ldm.art_frect_id IS NULL
        AND NOT EXISTS (
            SELECT
                subparts.id
            FROM
                part_product subparts
            WHERE
                ldm.id = subparts.part_product_parent_id)) ldm
    JOIN LATERAL (
        SELECT
            opgt.id,
            part.id AS part_id,
            opgt.art_id
        FROM
            part_product part
            JOIN part_product_kind opgt ON opgt.id = part.part_product_kind_id
        WHERE
            part.id = ldm.id
            AND opgt.plateforme_distribution_id = ($1)
            AND opgt.day_export_shop_id IN (
                SELECT
                    id
                FROM
                    day_export_shop jem
                WHERE
                    day <= to_timestamp($2)
                    AND day > CURRENT_DATE - interval '4 mons')) opgt ON TRUE
    JOIN LATERAL (
        SELECT
            r.id AS slot_id,
            ga.id AS grp_art_id
        FROM
            part_product_kind lm
            JOIN art a ON a.id = lm.art_id
            JOIN grp_art ga ON ga.id = a.grp_art_id
            JOIN slot r ON r.id = ga.slot_id
        WHERE
            opgt.id = lm.id) rGpe ON TRUE
UNION
SELECT
    opgt.part_id,
    opgt.art_id,
    rGpe.slot_id,
    rGpe.grp_art_id
FROM (
    SELECT
        id,
        art_frect_id,
        part_product_kind_id
    FROM
        part_product ldm
    WHERE
        nb_colis > 0
        AND statut_part_product IN ('DISPATCH', 'CANCELED', 'SALE_PROD')
        AND art_frect_id IS NOT NULL
        AND NOT EXISTS (
            SELECT
                subparts.id
            FROM
                part_product subparts
            WHERE
                ldm.id = subparts.part_product_parent_id)) ldm
    JOIN LATERAL (
        SELECT
            opgt.id,
            part.id AS part_id,
            opgt.art_id
        FROM
            part_product part
            JOIN part_product_kind opgt ON opgt.id = part.part_product_kind_id
        WHERE
            part.id = ldm.id
            AND opgt.plateforme_distribution_id = ($3)
            AND opgt.day_export_shop_id IN (
                SELECT
                    id
                FROM
                    day_export_shop jem
                WHERE
                    day <= to_timestamp($4)
                    AND day > CURRENT_DATE - interval '4 mons')) opgt ON TRUE
    JOIN LATERAL (
        SELECT
            r.id AS slot_id,
            ga.id AS grp_art_id
        FROM
            part_product lm
            JOIN art a ON a.id = lm.art_frect_id
            JOIN grp_art ga ON ga.id = a.grp_art_id
            JOIN slot r ON r.id = ga.slot_id
        WHERE
            opgt.id = lm.id) rGpe ON TRUE;

SELECT
    "INSTANCE_STATE_ID",
    "FORM_ID"
FROM
    "INSTANCE"
    INNER JOIN "FORM" ON "INSTANCE"."FORM_ID" = "FORM"."FORM_ID"
    LEFT JOIN "FORM_T" ON "FORM"."FORM_ID" = "FORM_T"."FORM_ID"
        AND "FORM_T"."LANGUAGE" = 'de'
    INNER JOIN "INSTANCE_STATE" ON "INSTANCE_STATE"."INSTANCE_STATE_ID" = "INSTANCE"."INSTANCE_STATE_ID"
    LEFT JOIN "INSTANCE_STATE_T" ON "INSTANCE_STATE"."INSTANCE_STATE_ID" = "INSTANCE_STATE_T"."INSTANCE_STATE_ID"
