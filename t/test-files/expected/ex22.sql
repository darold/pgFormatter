SELECT
    code.code,
    properties_code.valeur,
    properties_code1.valeur,
    properties_code2.valeur
FROM
    code
    INNER JOIN linkcode ON (code.id_code = linkcode.id_codeparent)
    INNER JOIN linkcode linkcode1 ON (linkcode.id_codeenfant = linkcode1.id_codeparent)
    INNER JOIN code code1 ON (linkcode1.id_codeenfant = code1.id_code)
    INNER JOIN properties_code ON (code1.id_code = properties_code.id_code)
    INNER JOIN properties_code properties_code1 ON (code1.id_code = properties_code1.id_code)
    INNER JOIN properties_code properties_code2 ON (code1.id_code = properties_code2.id_code)
    INNER JOIN properties ON (properties_code.id_propriete = properties.id_propriete)
    INNER JOIN properties properties1 ON (properties_code1.id_propriete = properties1.id_propriete)
    INNER JOIN properties properties2 ON (properties_code2.id_propriete = properties2.id_propriete)
    INNER JOIN variables ON (properties.id_variable = variables.id_variable)
    INNER JOIN variables variables1 ON (properties1.id_variable = variables1.id_variable)
    INNER JOIN variables variables2 ON (properties2.id_variable = variables2.id_variable)
    INNER JOIN mvt_temps ON (code.id_code = mvt_temps.id_code)
    INNER JOIN transactions ON (mvt_temps.id_transaction = transactions.id_transaction)
    INNER JOIN products ON (code.id_product = products.id_product)
WHERE
    variables.name = 'etat_DEC_BPO_sMacAdresse'
    AND variables1.name = 'variable_name'
    AND variables2.name = 'variable_name'
    AND transactions.code = 'XXXXXXXXXXXXX'
    AND mvt_temps.statutok = TRUE
    AND products.codeproduct = '123456789'
