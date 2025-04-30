# Análise de Pedidos na Plataforma Delivery Center no Brasil

**Fonte dos Dados:** [Delivery Center: Food & Goods orders in Brazil](https://www.kaggle.com/datasets/nosbielcs/brazilian-delivery-center/data)

## Introdução

A plataforma Delivery Center atuou no Brasil até Novembro de 2021, intregrando lojistas e marketplaces para a venda de produtos (good) e comida (food), com hubs operacionais distribuídos pelo país. Os datasets disponíveis apresentam dados de pedidos e entregas que foram processados pela plataforma entre os meses de janeiro a abril de 2021.

Por meio da análise exploratória dos dados operacionais da plataforma Delivery Center, buscou-se avaliar a qualidade das entregas realizadas, mapear a distribuição das distâncias percorridas e sua relação com os modais utilizados (bike e moto), além de compreender a distribuição geográfica das operações e identificar possíveis inconsistências nos registros de pedidos, entregas e pagamentos. A análise também se propôs a responder questões estratégicas de negócio, como a definição de critérios para bonificação de entregadores e o cálculo do valor de bônus a ser distribuído entre os colaboradores, com base no lucro gerado no período analisado.

Todas as consultas realizadas podem ser consultadas [aqui](https://github.com/laissapadilha/SQL-Delivery_Center/blob/884056060182d5a8358b7fa089f6263a5d69f533/DeliveryCenter.sql).

## Descrição das Tabelas

- **Channels**: contém dados relacionados aos canais de venda (marketplaces) dos produtos e comidas dos lojistas cadastrados no Delivery Center;
- **Deliveries**: possui registro das entregas realizadas pelos entregadores parceiros da plataforma;
- **Drivers**: detalha informações sobre os entregadores parceiros;
- **Hubs**: contém registro dos hubs operacionais do Delivery Center;
- **Orders**: possui dados dos pedidos processados através da plataforma do Delivery Center;
- **Payments**: detalha informações sobre os pagamentos realizados ao Delivery Center;
- **Stores**: contém dados dos lojistas cadastrados na plataforma.

## Relacionamento entre as Tabelas

<img src="https://github.com/user-attachments/assets/b5c6f0a5-d42c-4ac4-9900-3558a8db3432" alt="image" width="60%">


## Análise Exploratória dos Dados

### Channels: 

- A base possui um total de 40 canais, sendo 25 marketplaces e 14 canais próprios (own channel).

    <img width="329" alt="Captura de Tela 2025-04-29 às 05 45 41" src="https://github.com/user-attachments/assets/776a7330-7289-4821-8af2-c349ec589b2e" />


### Deliveries:

- A tabela deliveries contém o registro de 378.843 entregas, no entanto, verifica-se que há valores duplicados de delivery_order_id, ou seja, há mais de um registro de entrega para cada pedido. Os registros distintos de delivery_order_id somam 358.654;

    <img width="406" alt="image" src="https://github.com/user-attachments/assets/3a502dbb-a85d-48f7-836c-ded816240b56" />
    <img width="631" alt="image" src="https://github.com/user-attachments/assets/abb3e2b5-4e4d-4bf3-bfef-9c287d4b356a" />


- Para as análises seguintes desta tabela, foram desconsiderados os registros duplicados, mantendo aqueles com menor delivery_id e status *delivered*, em caso de status distintos, por meio da criação de uma *view*;

```ruby
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
```

- Identifica-se que 97,99% (351.450) das entregas foram concluídas (*delivered*), 1,97% foram canceladas (*cancelled*) e 0,04% estão com status de *delivering* – possivelmente trata-se de alguma inconsistência na plataforma ou falha do entregador ao não alterar a entrega para um status final (entregue ou cancelado);

    <img width="496" alt="image" src="https://github.com/user-attachments/assets/6385a4c8-1d0e-49b3-8bce-9df1c1b6d52f" />


- As colunas driver_id e delivery_distance_meters permitem valores nulos. Ao avaliar o status das entregas com driver_id nulo, identifica-se que apenas 2,20% das entregas com status *delivered* não possuem driver_id, enquanto este percentual é de 100% para aquelas com status *cancelled* e de 9,30% para as com *delivering*. Já quando analisamos as entregas com delivery_distance_meters nulas, é possível verificar que todas possuem status *delivered*, e representam apenas 0,02% das entregas com este status;

    <img width="1007" alt="image" src="https://github.com/user-attachments/assets/c8cbfc82-5051-4905-b402-2e41ea86d5d2" />


- Além das entregas com valores nulos, há algumas com delivery_distance_meters igual a zero. No entanto, representam apenas 3 entregas de pedidos com status *cancelled* e 7 pedidos *delivered*;
  
    <img width="351" alt="image" src="https://github.com/user-attachments/assets/ec21798c-897d-4330-9ba2-3eddbe024403" />


- Quando analisamos as distâncias mínimas, máximas, média, mediana e primeiro e terceiro quarter, observamos que a média supera em mais de 5 vezes a mediana, indicando uma distribuição assimétrica à direita. Ou seja, temos *outliers* (distâncias muito elevadas) que puxaram a média para cima. A distância máxima supera os 7.251 km, o que é extremamente elevado para os modais de transporte incluídos na base – bicicleta e moto;

    <img width="813" alt="image" src="https://github.com/user-attachments/assets/d3316028-8f6a-4e36-89f0-86ccf734658b" />


- Quando analisamos as distâncias mínimas, máximas, média, mediana e primeiro e terceiro quarter, segregados por modal de transporte, observamos que desta vez a mediana é superior à média, indicando que valores muito baixos de distância influenciaram na redução da média. Por exemplo, os valores mínimos de distância são de apenas 3 metros para bicicleta e 11 para motos. Por outro lado, identifica-se que mais uma vez, há também *outliers* nas distâncias máximas – 866 km para bicicleta e 7.251km para motos;

    <img width="811" alt="image" src="https://github.com/user-attachments/assets/ccb58912-5dbf-4349-92d2-aa6328a90fb7" />


### Drivers:

- No total, 4.824 entregadores atuaram na plataforma, sendo a maioria deles motoboys (3.222);
  
- Majoritariamente, os entregadores (tanto motoboys como bikers) atuavam como *freelance*;

    <img width="473" alt="image" src="https://github.com/user-attachments/assets/650373b1-aede-4949-8133-91a64bc0c622" />



### Hubs + Store:

- Haviam 951 lojas cadastradas na plataforma, distribuídas em 32 hubs localizados nas cidades de Curitiba, Rio de Janeiro, Porto Alegre e São Paulo;

- São Paulo era a cidade com maior quantidade de hubs e lojas, e Porto Alegre, a com menos lojas;

    <img width="514" alt="image" src="https://github.com/user-attachments/assets/21c2f07e-7d76-440f-9408-cc1c27625dc3" />


- A maioria das lojas eram do segmento de goods (bens).

    <img width="556" alt="image" src="https://github.com/user-attachments/assets/8c3f9a10-f483-4e10-af6e-4ee3d08dc3fd" />


### Orders:

- Foram realizados 368.999 pedidos no período analisado, sendo que 95,40% (352.020) foram finalizados e 4,60% (16.979) cancelados;

    <img width="505" alt="image" src="https://github.com/user-attachments/assets/85459793-df3a-4b15-bf97-5b542aa8dcd1" />

- Embora os pedidos tenham sido finalizados, a maioria destes não possui a informação de quando a entrega foi realizada (333.017);

    <img width="350" alt="image" src="https://github.com/user-attachments/assets/fc64c170-5198-4ad3-8a00-e017026d6cef" />

- Quando segregamos os pedidos por cidade e estado, identifica-se que São Paulo apresenta a maior média de valor de pedido com aproximadamente R$ 117,00, que representa um valor 69% maior que a menor média, de R$ 69,00, observada em Curitiba;
  
    <img width="662" alt="image" src="https://github.com/user-attachments/assets/b5ec57b2-1da2-4e12-a79e-b0c2235da7b7" />
    
- Quando segregamos os pedidos por segmento da loja e modal de transporte, observamos que as maiores média de valor do pedido estão no segmento de bens, superando os R$ 200,00 em ambos modais (motoboy e biker);

    <img width="767" alt="image" src="https://github.com/user-attachments/assets/91fac218-e181-4931-ac71-d05b57c0a0dc" />

- Também é possível identificar um pedido com valor *outlier* de R$ 100mil, que refere-se a entrega de bens realizada por um biker em São Paulo.

### Payments:

- Foram realizados 400.834 pagamentos para 350.334 payment_order_id distintos, ou seja, existe o registro de mais de um pagamento para o mesmo pedido;

    <img width="377" alt="image" src="https://github.com/user-attachments/assets/76ddba6b-285d-4c09-8413-32a4127a1a6d" />
    <img width="550" alt="image" src="https://github.com/user-attachments/assets/17c4f174-6c9a-49d7-926f-bb044afc12a2" />

- Dos pedidos com mais de um pagamento, em 2.351 o valor pago é diferente do valor do pedido – para mais ou menos, representando uma diferença elevada de R$ 126.025,25;

    <img width="883" alt="image" src="https://github.com/user-attachments/assets/bebe9721-1462-425a-817a-0048f0ab8354" />
    <img width="468" alt="image" src="https://github.com/user-attachments/assets/17b8a393-6288-4dbc-845c-e2452aba1186" />

- Além disso, tenho 1.694 pedidos finalizados sem registro de pagamento (payment_order_id) totalizando R$ 146.615,83;

    <img width="601" alt="image" src="https://github.com/user-attachments/assets/fbb7b5a8-02e8-48e4-a713-5295e290e526" />

- Há 15 modalidades de pagamento diferentes registradas na base, sendo que é possível verificar que mais de 86% dos pedidos foram pagos de forma online. Já quando olhamos para média de valor dos pedidos, a maior média é observada no método Crédito Parcelado Loja, com R$ 499,89, e a forma de pagamento online ocupa a sexta posição, com R$ 97,12;

    <img width="880" alt="image" src="https://github.com/user-attachments/assets/58e842d9-cda2-4125-a4fa-d597c358d960" />

- Também é possível identificar o pedido/pagamento *outlier* de R$ 100 mil foi pago na forma de pagamento online.

## Perguntas de Negócio

1. *Numa ação de marketing para atrair mais entregadores, os 20 entregadores que possuem maior distância receberão uma bonificação. A bonificação vai variar de acordo com o tipo de profissional que ele é e o modelo que ele usa para se locomover (moto ou bike). Levante essas informações.*

    Como já vimos na análise da tabela deliveries, temos registradas distâncias muito elevadas, tanto para biker como para motoboy. Portanto, primeiramente vamos definir distâncias       máximas razoáveis a serem percorridas por tipo de entregador. Consideraremos a distância máxima para biker 10 km e motoboy 80 km (pensando em entregadas em outra cidade). Além        disso, utilizaremos a view criada para a tabela Deliveries, que desconsiderar delivery_order_id duplicados.

    <img width="914" alt="image" src="https://github.com/user-attachments/assets/695fed0f-b726-474d-a20e-142d1cd38faf" />
    <img width="525" alt="image" src="https://github.com/user-attachments/assets/db3d8bf5-2c85-4089-ba4a-3317372d8e57" />
    <img width="528" alt="image" src="https://github.com/user-attachments/assets/13cc80ab-6cf0-486e-a44d-40626115187d" />

2. *O time de Pricing irá ajustar os valores pagos aos entregadores. Para isso, eles precisam da distribuição da distância média percorrida pelos motoqueiros separada por estado, já que cada região terá seu preço.*

    Nesta análise, novamente iremos consideraremos a distância máxima percorrida por um motoboy em uma única entrega de 80 km, assim como a view de valores únicos da tabela D             Deliveries.

    <img width="918" alt="image" src="https://github.com/user-attachments/assets/8a71b50e-5bd4-44c0-9847-e31a5c425524" />

3.	*O CFO precisa de alguns indicadores de receita para apresentar para a diretoria executiva, sendo eles:*

    *a.	 A receita média e total separada por tipo (Food x Good);*
  	
    *b.	 A receita média e total por estado.*

    Para realizar esta análise, considerou-se com receita a coluna order_delivery_fee (tarifa de entrega) da tabela Orders, apenas daqueles pedidos com status de finalizado.

    <img width="499" alt="image" src="https://github.com/user-attachments/assets/e32af7ac-235e-43c9-b2bc-6cabba6a7597" />
    <img width="494" alt="image" src="https://github.com/user-attachments/assets/c7ab1e59-f428-47da-abf3-135f59872290" />

5.	*Se a empresa tem um gasto fixo de 5 reais por entrega, recebe 15% do valor de cada entrega como receita e, do total do lucro, distribui 20% em forma de bônus para os 2 mil funcionários, quanto cada um irá receber no período contido na base?*

    <img width="884" alt="image" src="https://github.com/user-attachments/assets/53e92875-2eac-41ac-885a-f181c1aa402f" />

 
  

