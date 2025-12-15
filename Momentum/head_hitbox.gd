extends Area3D

# 인스펙터에서 설정할 수 있는 변수들
@export var damage_multiplier: float = 1.0 # 기본값 1.0 (헤드샷은 2.0 등으로 설정)

# 데미지를 전달받을 적군 본체 (CharacterBody3D)
# 인스펙터에서 적군 본체 노드를 연결해야 합니다.
@export var enemy_root: Node3D 

# 플레이어의 총알이나 공격이 이 함수를 호출합니다.
func hit(damage: int):
	if enemy_root:
		# has_method()로 함수 존재 여부를 확인합니다.
		if enemy_root.has_method("take_damage"):
			# 최종 데미지 = 기본 데미지 * 배율
			var final_damage = int(damage * damage_multiplier)
			
			# 헤드샷 여부 판단 (배율이 1.5보다 크면 헤드샷으로 간주)
			var is_headshot = damage_multiplier > 1.5
			
			# 적군 본체에게 데미지와 헤드샷 정보를 전달
			# call() 함수를 사용하여 동적으로 함수를 호출합니다.
			enemy_root.call("take_damage", final_damage, is_headshot)
			
			# (선택) 로그 출력
			if is_headshot:
				print("HEADSHOT! (", final_damage, ")")
			else:
				print("Body Shot. (", final_damage, ")")
		else:
			print("오류: enemy_root에 take_damage 함수가 없습니다.")
	else:
		print("오류: enemy_root가 설정되지 않았습니다.")
