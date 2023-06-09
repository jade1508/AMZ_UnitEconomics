view: amz_uniteconomics {
  derived_table: {
    sql: with tbl as (
          SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY business, marketplaceName, sku ORDER BY date DESC ) num
          FROM `datalake.AMZ_UnitEconomics`
          WHERE cogs is not null)

        SELECT * from tbl
        WHERE num = 1;;
        }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: date {
    type: date
    datatype: date
    sql: ${TABLE}.date ;;
  }

  dimension: brand {
    type: string
    sql: ${TABLE}.brand ;;
  }

  dimension: business {
    type: string
    sql: ${TABLE}.business ;;
  }

  dimension: marketplace_name {
    type: string
    sql: ${TABLE}.marketplaceName ;;
  }

  dimension: sku {
    type: string
    sql: ${TABLE}.sku ;;
  }

  dimension: asin {
    type: string
    sql: ${TABLE}.asin ;;
  }

  dimension: product_size {
    type: string
    sql: ${TABLE}.product_size ;;
  }

  dimension: currency {
    type: string
    sql: ${TABLE}.currency ;;
  }

  dimension: salesprice_exclVAT {
    description: "sales price excluding VAT"
    type: number
    sql: ${TABLE}.salesprice_exclVAT ;;
  }

  dimension: fba_fulfillment_usd {
    type: number
    sql: ${TABLE}.fba_fulfillment_usd ;;
  }

  dimension: snl_fee_usd {
    description: "fulfillment fee applied for small and light products"
    type: number
    sql: ${TABLE}.snl_fee_usd ;;
  }

  dimension: commission_usd {
    type: number
    sql: ${TABLE}.commission_usd ;;
  }

  dimension: cogs {
    type: number
    sql: ${TABLE}.cogs ;;
    value_format_name: decimal_2
  }

  dimension: payout {
    description: "sales price excl VAT- fba fulfillment fee - snl fee - commission - cogs"
    type: number
    sql: ${TABLE}.payout ;;
  }

  dimension: fulfillment_on_sales {
    description: "fba fulfillment or snl fee / sales price excl VAT"
    type: number
    sql: ${TABLE}.fulfillment_on_sales ;;
    value_format_name: percent_1
  }

  dimension: commission_on_sales {
    description: "commission / sales price excl VAT"
    type: number
    sql: ${TABLE}.commission_on_sales ;;
    value_format_name: percent_1
  }

  dimension: cogs_on_sales {
    description: "cogs / sales price excl VAT"
    type: number
    sql: ${TABLE}.cogs_on_sales ;;
    value_format_name: percent_1
  }

  dimension: payout_on_sales {
    description: "payout / sales price excl VAT"
    type: number
    sql: ${TABLE}.payout_on_sales ;;
    value_format_name: percent_1
  }

  set: detail {
    fields: [
      date,
      brand,
      business,
      marketplace_name,
      sku,
      asin,
      product_size,
      currency,
      salesprice_exclVAT,
      fba_fulfillment_usd,
      snl_fee_usd,
      commission_usd,
      cogs,
      payout,
      fulfillment_on_sales,
      commission_on_sales,
      cogs_on_sales,
      payout_on_sales
    ]
  }

  dimension: payout_filter {
    case: {
      when: {
        sql: ${payout_on_sales} < 0.15;;
        label: "Less than 15%"
      }
      when: {
        sql: ${payout_on_sales} < 0.25;;
        label: ">=15% and <25%"
      }
      when: {
        sql: ${payout_on_sales} < 0.3;;
        label: ">=25% and <30%"
      }
      else: ">=30%"
    }
  }

}
