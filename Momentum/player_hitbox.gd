extends Area3D

# 플레이어 본체 (CharacterBody3D)를 연결할 변수입니다.
# 인스펙터에서 직접 연결할 수 있습니다.
@export var player_body: CharacterBody3D

func _ready():
	# 만약 인스펙터에서 연결하지 않았다면, 자동으로 부모 노드를 찾아서 연결합니다.
	if not player_body:
		var parent = get_parent()
		if parent is CharacterBody3D:
			player_body = parent
			# print("PlayerHitbox: 부모 노드를 플레이어 본체로 자동 설정했습니다.")
		else:
			print("경고: PlayerHitbox의 부모가 CharacterBody3D가 아닙니다! 인스펙터에서 player_body를 연결해주세요.")

# 적군의 공격(투사체 등)이 이 함수를 호출하여 데미지를 줍니다.
func hit(damage: int):
	if player_body and player_body.has_method("take_damage"):
		player_body.take_damage(damage)
		print("플레이어 피격! (데미지: ", damage, ")")
	else:
		print("오류: player_body가 연결되지 않았거나 take_damage 함수가 없습니다.")
