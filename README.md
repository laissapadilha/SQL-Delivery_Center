# Análise de Pedidos na Plataforma Delivery Center no Brasil

**Fonte dos Dados:** [Delivery Center: Food & Goods orders in Brazil](https://www.kaggle.com/datasets/nosbielcs/brazilian-delivery-center/data)

## Introdução

A plataforma Delivery Center atuou no Brasil até Novembro de 2021, intregrando lojistas e marketplaces para a venda de produtos (good) e comida (food), com hubs operacionais distribuídos pelo país. Os datasets disponíveis apresentam dados de pedidos e entregas que foram processados pela plataforma entre os meses de janeiro a abril de 2021.

Por meio da análise exploratória dos dados operacionais da plataforma Delivery Center, buscou-se avaliar a qualidade das entregas realizadas, mapear a distribuição das distâncias percorridas e sua relação com os modais utilizados (bike e moto), além de compreender a distribuição geográfica das operações e identificar possíveis inconsistências nos registros de pedidos, entregas e pagamentos. A análise também se propôs a responder questões estratégicas de negócio, como a definição de critérios para bonificação de entregadores e o cálculo do valor de bônus a ser distribuído entre os colaboradores, com base no lucro gerado no período analisado.

Todas as consultas realizadas podem ser consultadas [aqui](https://github.com/laissapadilha/SQL-Evasao_de_Universitarios/blob/main/StudentsDropout.sql).

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

### Deliveries:

- A tabela deliveries contém o registro de 378.843 entregas, no entanto, verifica-se que há valores duplicados de delivery_order_id, ou seja, há mais de um registro de entrega para cada pedido;

- Existem 358.654 delivery_order_id distintos e, para as análises seguintes desta tabela, serão desconsiderados os registros duplicados, mantendo aqueles com menor delivery_id e status *delivered*, em caso de status distintos;

- Identifica-se que 97,99% (351.450) entregas foram concluídas (*delivered*), 1,97% foram canceladas e 0,04% estão com status de delivering – possivelmente trata-se de alguma inconsistência na plataforma ou falha do entregador - ao não alterar a entrega para um status final (entregue ou cancelado);

- As colunas driver_id e delivery_distance_meters permite valores nulos. Ao avaliar o status das entregas com driver_id nulo, identifica-se que apenas 2,20% das entregas com status *delivered* não possuem driver_id, enquanto este percentual é de 100% para aquelas com status *cancelled* e de 9,30% para as com *delivering*. Já quando analisamos as entregas com delivery_distance_meters nulas, é possível verificar que todas possuem status *delivered*, e representam apenas 0,02% das entregas com este status;

- Além das entregas com valores nulos, há algumas com delivery_distance_meters igual a zero. No entanto, representam apenas 3 entregas de pedidos com status *cancelled* e 7 de pedidos *delivered*;

- Quando analisamos as distâncias mínimas, máximas, média, mediana e primeiro e terceiro quarter, observamos que a média supera em mais de 5 vezes a mediana, indicando uma distribuição assimétrica à direita. Ou seja, temos outliers (distâncias muito elevadas) que puxaram a média para cima. A distância máxima supera os 7.251 km, o que é extremamente elevado para os modais de transporte incluídos na base – bicicleta e moto;

- Quando analisamos as distâncias mínimas, máximas, média, mediana e primeiro e terceiro quarter, segregados por modal de transporte, observamos que desta vez a mediana é superior à média, indicando que valores muito baixos de distância influenciaram na redução da média. Por exemplo, os valores mínimos de distância são de apenas 3 metros para bicicleta e 11 para motos. Por outro lado, identifica-se que mais uma vez, há também outliers nas distâncias máximas – 866 km para bicicleta e 7.251km para motos;




  

