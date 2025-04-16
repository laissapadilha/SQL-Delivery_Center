--ANALISE EXPLORATORIA DOS DADOS

--CHANNEL

SELECT DISTINCT
    channel_type,
    COUNT(*) AS count_channel
FROM
    channels
GROUP BY channel_type

--DELIVERIES

---Total de entregas

SELECT COUNT(*) AS deliveries FROM deliveries

---Total de pedidos distintos entregues

SELECT COUNT(DISTINCT delivery_order_id) AS orders_delivered FROM deliveries

---Pedidos com mais de uma entrega

SELECT
    DISTINCT delivery_order_id,
    COUNT(*) AS count,
    COUNT(DISTINCT driver_id) AS count_driver,
    COUNT(DISTINCT delivery_status) AS count_status
FROM
    deliveries
GROUP BY delivery_order_id
HAVING COUNT(*) > 1
ORDER BY count_status DESC

---Criação de view sem duplicatas

GO
CREATE VIEW vw_deliveries_unicas AS
WITH deliveries_sem_duplicatas AS (
    SELECT *
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY delivery_order_id
                ORDER BY 
                    CASE WHEN delivery_status = 'DELIVERED' THEN 0 ELSE 1 END,
                    delivery_id
            ) AS rn
        FROM deliveries
    ) AS ranked)
SELECT * FROM deliveries_sem_duplicatas WHERE rn = 1

---Entregas por status

SELECT
    delivery_status,
    COUNT(*) as count_delivery,
    (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER() AS 'percent'
FROM
    vw_deliveries_unicas
GROUP BY delivery_status

---Contagem de nulos nas colunas que permitem valores nulos, segregado por status

SELECT 
    delivery_status,
    COUNT(*) AS count_deliveries,
    SUM(CASE WHEN driver_id IS NULL THEN 1 ELSE 0 END) AS driver_null,
    (SUM(CASE WHEN driver_id IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS driver_null_percent,
    SUM(CASE WHEN delivery_distance_meters IS NULL THEN 1 ELSE 0 END) AS distance_null,
    (SUM(CASE WHEN delivery_distance_meters IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS distance_null_percent
FROM vw_deliveries_unicas
GROUP BY delivery_status

---Entregas com distância = zero

SELECT
    delivery_status,
    COUNT(*) AS zero_distance
FROM
    vw_deliveries_unicas
WHERE delivery_distance_meters = 0
GROUP BY delivery_status

---Distância mínima, máxima, média, primeiro quarter, mediana e terceiro quarter (geral)

SELECT 
    MIN(CAST(delivery_distance_meters AS BIGINT)) AS min_distance,
    MAX(CAST(delivery_distance_meters AS BIGINT)) AS max_distance,
    ROUND(AVG(CAST(delivery_distance_meters AS FLOAT)),2) AS avg_distance,
    (SELECT TOP 1 PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY delivery_distance_meters) 
        OVER() FROM deliveries) AS first_quarter,
    (SELECT TOP 1 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY delivery_distance_meters) 
        OVER() FROM deliveries) AS median,
    (SELECT TOP 1 PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY delivery_distance_meters) 
         OVER() FROM deliveries) AS third_quarter
FROM
    vw_deliveries_unicas
WHERE delivery_distance_meters != 0

--- Distância mínima, máxima, média, primeiro quarter, mediana e terceiro quarter (segregada por modal de transporte)

WITH distance_quarter AS (
    SELECT DISTINCT
        driver_modal,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY delivery_distance_meters) 
        OVER(PARTITION BY driver_modal) AS first_quarter,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY delivery_distance_meters) 
        OVER(PARTITION BY driver_modal) AS median,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY delivery_distance_meters) 
        OVER(PARTITION BY driver_modal) AS third_quarter
    FROM
        vw_deliveries_unicas a
        LEFT JOIN drivers b
    ON a.driver_id = b.driver_id
    WHERE b.driver_id IS NOT NULL
    AND delivery_distance_meters != 0
    GROUP BY driver_modal, delivery_distance_meters
) 
SELECT
    b.driver_modal,
    MIN(CAST(delivery_distance_meters AS BIGINT)) AS min_distance,
    MAX(CAST(delivery_distance_meters AS BIGINT)) AS max_distance,
    ROUND(AVG(CAST(delivery_distance_meters AS FLOAT)),2) AS avg_distance,
    MAX(first_quarter) AS first_quarter,
    MAX(median) AS median,
    MAX(third_quarter) AS third_quarter
FROM
    vw_deliveries_unicas a
LEFT JOIN drivers b
ON a.driver_id = b.driver_id
LEFT JOIN distance_quarter c
ON b.driver_modal = c.driver_modal
WHERE b.driver_id IS NOT NULL
AND delivery_distance_meters != 0
GROUP BY b.driver_modal

-- DRIVERS

---Total de entregadores

SELECT COUNT(*) AS drivers FROM drivers

---Segregação dos entregadores por modal de transporte e tipo

SELECT 
    driver_modal,
    driver_type,
    COUNT(driver_id) AS driver_count
FROM
    drivers
GROUP BY
    driver_modal,
    driver_type
ORDER BY 
    driver_modal DESC, 
    driver_count DESC

-- HUBS + STORE

---Total de hubs de entrega

SELECT COUNT(*) AS hubs FROM hubs

---Total de lojas

SELECT COUNT(*) AS stores FROM stores

---Contagem de hubs e lojas, segregada por cidade/estado

SELECT
    hub_city,
    hub_state,
    COUNT(DISTINCT a.hub_id) AS count_hub,
    COUNT(store_id) AS count_store
FROM
    hubs a
LEFT JOIN stores b
ON a.hub_id = b.hub_id
GROUP BY
    hub_city,
    hub_state
ORDER BY
    count_store DESC

---Contagem de lojas, segregada por cidade/estado e segmento

SELECT
    hub_city,
    hub_state,
    store_segment,
    COUNT(store_id) AS count_store
FROM
    hubs a
LEFT JOIN stores b
ON a.hub_id = b.hub_id
GROUP BY
    hub_city,
    hub_state,
    store_segment
ORDER BY
    hub_city DESC,
    count_store DESC
    
--ORDERS

---Total de pedidos

SELECT COUNT(*) AS orders FROM orders

---Contagem e percentual de pedidos, segregado por status

SELECT
    order_status,
    COUNT(*) AS orders,
    (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER() AS 'percent'
FROM
    orders
GROUP BY order_status

---Pedidos finalizados sem registro de entrega

SELECT
    COUNT(order_id) AS orders
FROM
    orders
WHERE order_status = 'FINISHED'
AND order_moment_delivered IS NULL

---Valor mínimo, máximo e médio dos pedidos finalizados, segragado por cidade e estado

SELECT
    hub_city,
    hub_state,
    MIN(order_amount) AS min_order,
    MAX(order_amount) AS max_order,
    AVG(order_amount) AS avg_order
FROM
    orders a
LEFT JOIN stores b
ON a.store_id = b.store_id
LEFT JOIN hubs c
ON b.hub_id = c.hub_id
WHERE order_status = 'FINISHED'
GROUP BY hub_city, hub_state
ORDER BY avg_order DESC

---Valor total, mínimo, máximo e médio dos pedidos finalizados, segregado por segmento da loja e modal de transporte

SELECT
    store_segment,
    driver_modal,
    ROUND(SUM(order_amount),2) AS sum_order,
    ROUND(MIN(order_amount),2) AS min_order,
    ROUND(MAX(order_amount),2) AS max_order,
    ROUND(AVG(order_amount),2) AS avg_order
FROM
    orders a
LEFT JOIN deliveries b
ON a.delivery_order_id = b.delivery_order_id
LEFT JOIN stores c
ON a.store_id = c.store_id
LEFT JOIN hubs d
ON c.hub_id = d.hub_id
LEFT JOIN drivers e
ON b.driver_id = e.driver_id
WHERE b.driver_id IS NOT NULL
GROUP BY
    store_segment,
    driver_modal
ORDER BY avg_order DESC

--PAYMENTS

---Total de pagamentos

SELECT COUNT(*) AS payments FROM payments

---Total de pedidos pagos

SELECT COUNT(DISTINCT payment_order_id) AS payments FROM payments

---Valor pagamento x valor do pedido

WITH pay_amount AS (
    SELECT 
        a.payment_order_id, 
        COUNT(*) AS payment_count,
        SUM(payment_amount) AS sum_payment,
        (order_amount + order_delivery_fee) AS sum_order_amt_fee, 
        ROUND((SUM(payment_amount) - (order_amount + order_delivery_fee)), 2) AS diff,
        CASE
            WHEN (SUM(payment_amount) - (order_amount + order_delivery_fee)) > 1000 THEN '8.MAIOR R$ 1,000.00'
            WHEN (SUM(payment_amount) - (order_amount + order_delivery_fee)) > 500 THEN '7.MAIOR R$ 500.00'
            WHEN (SUM(payment_amount) - (order_amount + order_delivery_fee)) > 100 THEN '6.MAIOR R$ 100.00'
            WHEN (SUM(payment_amount) - (order_amount + order_delivery_fee)) > 50 THEN '5.MAIOR R$ 50.00'
            WHEN (SUM(payment_amount) - (order_amount + order_delivery_fee)) > 10 THEN '4.MAIOR R$ 10.00'
            WHEN (SUM(payment_amount) - (order_amount + order_delivery_fee)) > 1 THEN '3.MAIOR R$ 1.00'
            WHEN (SUM(payment_amount) - (order_amount + order_delivery_fee)) > 0 THEN '2.MAIOR R$ 0'
            ELSE '1.MENOR R$ 0'
        END AS amount_range
    FROM 
        payments a
    LEFT JOIN
        orders b ON a.payment_order_id = b.payment_order_id
    GROUP BY 
        a.payment_order_id,
        order_amount, 
        order_delivery_fee
    HAVING ROUND((SUM(payment_amount) - (order_amount + order_delivery_fee)),2) != 0
    AND COUNT(*) > 1
)
SELECT
    CASE 
        WHEN amount_range IS NULL THEN 'Total'
        ELSE amount_range
    END AS amount_range,
    COUNT(diff) AS count_diff,
    ROUND(SUM(diff),2) AS total_diff
FROM pay_amount
GROUP BY ROLLUP(amount_range)
ORDER BY amount_range

---Pedidos finalizados sem registro de pagamento

SELECT 
    COUNT(order_id) AS count_order,
    ROUND(SUM(order_amount) + SUM(order_delivery_fee),2) AS total_amount
FROM orders
WHERE payment_order_id IN (
    SELECT payment_order_id FROM orders
    EXCEPT
    SELECT payment_order_id FROM payments
) 
AND order_status != 'CANCELED'

---Valor mínimo, máximo, média e contagem de pagamentos, segregado por status

SELECT
    payment_status,
    COUNT(payment_id) AS count_payment,
    ROUND(SUM(payment_amount),2) AS sum_payment,
    ROUND(MIN(payment_amount),2) AS min_payment,
    ROUND(MAX(payment_amount),2) AS max_payment,
    ROUND(AVG(payment_amount),2) AS avg_payment
FROM
    payments
GROUP BY
    payment_status

---Valor mínimo, máximo, média e contagem de pagamentos, segregado por método de pagamento

SELECT
    payment_method,
    COUNT(payment_id) AS count_payment,
    ROUND(SUM(payment_amount),2) AS sum_payment,
    ROUND(MIN(payment_amount),2) AS min_payment,
    ROUND(MAX(payment_amount),2) AS max_payment,
    ROUND(AVG(payment_amount),2) AS avg_payment
FROM
    payments
GROUP BY
    payment_method
ORDER BY avg_payment DESC

---Valor mínimo, máximo, média e contagem de pagamentos, segregado por segmento da loja e modal de transporte

SELECT
    store_segment,
    driver_modal,
    COUNT(payment_id) AS count_payment,
    ROUND(SUM(payment_amount),2) AS sum_payment,
    ROUND(MIN(payment_amount),2) AS min_payment,
    ROUND(MAX(payment_amount),2) AS max_payment,
    ROUND(AVG(payment_amount),2) AS avg_payment
FROM
    payments a
LEFT JOIN orders b
ON a.payment_order_id = b.payment_order_id
LEFT JOIN stores c
ON b.store_id = c.store_id
LEFT JOIN deliveries d
ON b.delivery_order_id = d.delivery_order_id
LEFT JOIN drivers e
ON d.driver_id = e.driver_id
WHERE d.driver_id IS NOT NULL
GROUP BY
    store_segment,
    driver_modal
ORDER BY avg_payment DESC


---PERGUNTAS DO NEGÓCIO

/*
Numa ação de marketing, para atrair mais entregadores, vamos dar uma bonificação para 
os 20 entregadores que possuem maior distância percorrida ao todo. A bonificação vai 
variar de acordo com o tipo de profissional que ele é e o modelo que ele usa para se 
locomover (moto, bike, etc). Levante essas informações.
*/

WITH total_distance AS(
    SELECT
        RANK() OVER(PARTITION BY driver_modal ORDER BY SUM(ISNULL(b.delivery_distance_meters,0)) DESC) AS "ranking",
        a.driver_id,
        SUM(ISNULL(b.delivery_distance_meters,0)) AS "total_distance",
        a.driver_modal
    FROM
        drivers a
    LEFT JOIN
        vw_deliveries_unicas b
    ON a.driver_id = b.driver_id
    WHERE
        (a.driver_modal = 'BIKER' AND ISNULL(b.delivery_distance_meters, 0) <= 10000) 
        OR 
        (a.driver_modal = 'MOTOBOY' AND ISNULL(b.delivery_distance_meters, 0) <= 80000)
    GROUP BY
        a.driver_id,
        a.driver_modal)
SELECT
    *
FROM
    total_distance
WHERE
    ranking <=20

/*
O time de Pricing precisa ajustar os valores pagos aos entregadores. 
Para isso, eles precisam da distribuição da distância média percorrida pelos motoqueiros 
separada por estado, já que cada região terá seu preço.
*/

SELECT
    d.hub_state,
    ROUND(SUM(ISNULL(CAST(a.delivery_distance_meters AS FLOAT),0))/(COUNT(ISNULL(e.driver_id,0))),2) AS avg_distance
FROM
    drivers e
LEFT JOIN
    vw_deliveries_unicas a
ON e.driver_id = a.driver_id
LEFT JOIN 
    orders b
ON a.delivery_order_id = b.delivery_order_id
LEFT JOIN
    stores c
ON b.store_id = c.store_id
LEFT JOIN
    hubs d
ON c.hub_id = d.hub_id
WHERE driver_modal = 'MOTOBOY'
AND delivery_distance_meters <= 80000
AND d.hub_state IS NOT NULL    
GROUP BY
    d.hub_state
 
 /*
O CFO precisa de alguns indicadores de receita para apresentar para a diretoria executiva. 
 Dentre esses indicadores, vocês precisarão levantar:
 (1) a receita média e total separada por tipo (Food x Good), 
 (2) A receita média e total por estado.
 */

---RECEITA TOTAL E MEDIA POR SEGMENTO/TIPO

SELECT
    store_segment,
    ROUND(SUM(order_delivery_fee),2) AS total_income_fee,
    ROUND(AVG(order_delivery_fee),2) AS avg_income_fee
FROM
    stores a
LEFT JOIN 
    orders b
ON a.store_id = b.store_id
WHERE
    order_status = 'FINISHED'
GROUP BY
    store_segment

---RECEITA TOTAL E MEDIA POR ESTADO

SELECT
    hub_state,
    ROUND(SUM(order_delivery_fee),2) AS total_income_fee,
    ROUND(AVG(order_delivery_fee),2) AS avg_income_fee
FROM
    orders a
LEFT JOIN 
    stores b
ON a.store_id = b.store_id
LEFT JOIN
    hubs c
ON b.hub_id = c.hub_id
WHERE
    order_status = 'FINISHED'
GROUP BY
    hub_state;

/*
Se a empresa tem um gasto fixo de 5 reais por entrega, recebe 15% do valor de cada entrega 
como receita e, do total do lucro, distribui 20% em forma de bônus para os 2 mil funcionários, 
quanto cada um irá receber no período contido no dataset?
*/

SELECT
    COUNT(order_id) AS total_order,
    ROUND(SUM(order_delivery_fee),2) AS total_income_fee,
    COUNT(order_id) * 5 AS total_expense,
    ROUND((SUM(order_delivery_fee) - (COUNT(order_id) * 5)),2) * 0.15 AS profit,
    ROUND((((SUM(order_delivery_fee) - (COUNT(order_id) * 5)) * 0.15) * 0.2 / 2000),2) AS profit_distribution
FROM
    orders
WHERE order_status = 'FINISHED'


