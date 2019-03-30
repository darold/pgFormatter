INSERT INTO tt_tmp_wrk1 (
    SELECT
        MAR,
        (
            CASE WHEN MAR = 'SEUIL_DEST' THEN
            (
                SELECT
                    COUNT(*)
                FROM
                    CUS
                WHERE
                    MAR.obj4 = (
                        CASE WHEN MAR.type4 = 'CF' THEN
                            CUS.account_no::text
                        WHEN MAR.type4 = 'CR' THEN
                            CUS.owning_account_no::text
                        WHEN MAR.type4 = 'SI' THEN
                            CUS.point_origin
                        END)
                    AND (CUS = ( SELECT DISTINCT
                                DD
                            FROM
                                PCM
                            WHERE
                                PCM.compo = CMF.compo)
                            OR CUS = ( SELECT DISTINCT
                                    CPIR
                                FROM
                                    PCM
                                WHERE
                                    PCM.compo = CMF.compo)
                                OR CUS = ( SELECT DISTINCT
                                        CPIR
                                    FROM
                                        PCM,
                                        CT,
                                        PIDR,
                                        CPIR,
                                        CMF
                                    WHERE
                                        PCM.compo = CMF.compo)))
            WHEN MAR = 'SEUIL_OBJ' THEN
            (
                SELECT
                    COUNT(*)
                FROM
                    CPC
                WHERE
                    MAR.obj4 = (
                        CASE WHEN MAR.type4 = 'CF' THEN
                            CPC.parent::text
                        WHEN MAR.type4 = 'CR' THEN
                            CPC.parent::text
                        WHEN MAR.type4 = 'SI' THEN
                            CPC.parent::text
                        END)
                    AND CPC IN (
                        SELECT
                            SPT
                        FROM
                            SPT
                        WHERE
                            SPT = 'SEUIL_OBJ'
                            AND SPT IN ( SELECT DISTINCT
                                    compo
                                FROM
                                    CPC
                                WHERE
                                    MAR = (
                                        CASE WHEN MAR = 'CF' THEN
                                            CPC.parent::text
                                        WHEN MAR = 'CR' THEN
                                            CPC.parent::text
                                        WHEN MAR.type4 = 'SI' THEN
                                            CPC.parent::text
                                        END))))
            END)
    FROM
        MAR,
        BIP
    WHERE
        BIP = (MAR)::int);

