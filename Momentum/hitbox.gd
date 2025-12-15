extends Area3D

# 인스펙터에서 설정할 수 있는 변수들
@export var damage_multiplier: float = 1.0 # 기본값 1.0

# 데미지를 전달받을 적군 본체 (CharacterBody3D)
@export var enemy_root: Node3D

func hit(damage: int):
	if enemy_root:
		# has_method()로 함수 존재 여부를 확인합니다.
		if enemy_root.has_method("take_damage"):
			var final_damage = int(damage * damage_multiplier)
			var is_headshot = damage_multiplier > 1.5
			
			# [수정] call() 함수 대신 직접 호출 방식으로 변경
			# call() 함수 사용 시 발생하는 모호한 타입 오류를 방지합니다.
			# Enemy.gd의 take_damage 함수가 (amount, is_headshot) 인자를 받도록 정의되어 있어야 합니다.
			enemy_root.take_damage(final_damage, is_headshot)
			
			if is_headshot:
				print("HEADSHOT! (", final_damage, ")")
			else:
				print("Body Shot. (", final_damage, ")")
		else:
			print("오류: enemy_root에 take_damage 함수가 없습니다.")
	else:
		print("오류: enemy_root가 설정되지 않았습니다.")
