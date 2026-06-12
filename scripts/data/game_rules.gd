class_name GameRules
extends Resource
## Regras globais de economia — até estes números são dados, não código.

## Fração do valor investido devolvida na venda
@export_range(0.0, 1.0) var sell_refund_ratio: float = 0.7
## Ouro por segundo restante ao chamar a onda antecipadamente
@export var early_call_gold_per_second: float = 1.0
