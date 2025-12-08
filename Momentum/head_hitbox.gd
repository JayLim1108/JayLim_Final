extends Area3D

# 인스펙터에서 설정할 수 있는 변수들
@export var damage_multiplier: float = 1.5 # 기본값 1.0
@export var enemy_root: Node3D # 데미지를 전달할 본체

func hit(damage: int):
	if enemy_root and enemy_root.has_method("take_damage"):
		var final_damage = int(damage * damage_multiplier)
		enemy_root.take_damage(final_damage)
		
		# (선택) 부위별 로그 출력
		if damage_multiplier > 1.5:
			print("HEADSHOT! (", final_damage, ")")
		else:
			print("Body Shot. (", final_damage, ")")
