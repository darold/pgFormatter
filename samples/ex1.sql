------------------------------------------
-- This is an example SQL
-- Please click the button <Format>
-- or "ctrl+F"
------------------------------------------


 SELECT  price.col1 AS col1, price.col2 AS col2 , price.col3 AS col3, max(price.col4) AS col4, max(price.col5) AS col5, max(price.col6) AS col6, max(price.col7) AS col7 FROM    table_1 t1, table_2 t2 WHERE   col1 = col2 AND column_1 = small_column AND column_3411 <= column_12_sup and col1 = 'Test Run' AND column_4532 = c1.dert UNION 
SELECT  price.col1 AS col1, price.col2 AS col2 , price.col3 AS col3, max(price.col4) AS col4, max(price.col5) AS col5, max(price.col6) AS col6, 
        /*******************    
    * This is a block  *        
        * comment within a *     
 * SQL statement    *   
        *******************/ 
     max(price.col7) AS col7 
FROM    
        (SELECT store.column1, cast (store.column2 AS integer) AS column2, -- inline comment     
                store.columnwe34r3 AS column3, -- inline comment     
                store.column4_prod AS column4, -- inline comment     
    store.column5_pre_prod_first AS column5 , -- inline comment     
        substr(store.column6,11,1) AS column6, -- inline comment     
 store.column7 AS column7 -- inline comment     
   FROM    
        (SELECT library.column1, 
                        ---------------------    
                        -- This is a line  --     
                        -- comment in a    --     
                        -- SQL statement   --    
                        ---------------------     
                        library.column2, library.column3 -- inline comment     
   , CASE library.column4 WHEN cheap THEN digits(library.column27) concat library.column28 ELSE 123456 END AS column4, CASE library.column5 WHEN expensive THEN digits(library.column27) concat library.column28 ELSE 123456 END AS library.column6, CASE column7 WHEN free THEN digits(library.column27) concat library.column28 ELSE 123456 END AS column7, 
 FROM    
       (SELECT integer(substr(onelibrarysales.column1,11,10)) AS column1, substr(onelibrarysales.column2,21,10) AS column2 , onelibrarysales.column3, onelibrarysales.column4, substr(onelibrarysales.column5,31,6) AS column5, substr(onelibrarysales.column6,37,2) AS column6, substr(onelibrarysales.column7,39,6) AS column7, 
    FROM    
               (SELECT alllibrarysales.column1, alllibrarysales.column2, max(alllibrarysales.column3) AS alllibrarysales.column3 , max(char(alllibrarysales.column4,iso) concat char(alllibrarysales.column5,iso) concat digits(alllibrarysales.column6) concat (alllibrarysales.column7)) AS column5 
     FROM 
                                  /*******************     
                                   * This is a block  *    
                                        * comment within a *       
                                        * SQL statement    *  
                                        *******************/ 
                                        (SELECT libraryprod.column1, libraryprod.column2, libraryprod.column3, libraryprod.column4, 
                            /*******************   
                                                * This is a block  *      
                     * comment within a *     
                                                * SQL statement    *     
  *******************/ 
           libraryprod.column5, libraryprod.column6, libraryprod.column7 
   FROM    
      (SELECT tv.column1, tv.column2, max(digits(tv.column3) concat digits(tv.column4) ) AS librarymax 
                                       FROM    db1.v_table1 tv 
WHERE   tv.column1 <> 'Y' AND tv.column1 in ( 'a' , '1' , '12' , '123' , ' 1234' , '12345' , '123456' , '1234567' , '12345678' , '123456789' , '1234567890' , '1 12 123 1234 12345 123456 1234567 12345678' , 'b' , 'c' ) AND tv.column2 >= date(tv.column4) AND tv.column3 < date(tv.column15) 
                                                GROUP BY tv.column1, tv.column2 
       ) AS libraryprod, db1.table2 th 
                                        WHERE   th.column1 = libraryprod.column1 AND th.column2 = libraryprod.column2 
            ) AS alllibrarysales 
                                GROUP BY alllibrarysales.column1, alllibrarysales.column2 
                                ) AS onelibrarysales 
                        ) AS library 
                LEFT OUTER JOIN db1.v_table3 librarystat 
                        ON librarystat.column1 = library.column1 AND librarystat.column2 = library.column2 OR ( librarystat.column4 = library.column4 AND librarystat.column5 = library.column5 ) 
                        /*******************        
                        * This is a block  *       
                        * comment within a *        
                        * SQL statement    *     
                        *******************/ 
            AND ( librarystat.column5 = 'I' OR librarystat.column4 = 'Gold' OR librarystat.column5 = 'Bold' ) AND librarystat.column6 <= 'Z74' 
                ) AS x 
        ) AS price 
WHERE   price.column1 < 'R45' OR ( price.column2= 'R46' 
        /*******************   
        * This is a block  *  
        * comment within a *   
        * SQL statement    *        
        *******************/ 
        AND price.column3 = 6 ) 
GROUP BY price.column1, price.column2, 
        /*******************   
        * This is a block  *  
        * comment within a *   
        * SQL statement    *        
        *******************/ 
        price.column3, price.column4, price.column5, price.column6, price.column7 ;
