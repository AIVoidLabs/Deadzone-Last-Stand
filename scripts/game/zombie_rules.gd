class_name ZombieRules
extends RefCounted
## Zombi durum makinesinin saf kuralları. Süreler ve menziller veri tablosundan parametreyle gelir.
## Akış: SPAWN -> CHASE -> WINDUP -> (vuruş) -> RECOVER -> CHASE; STAGGER araya girer; DYING son.
## Atılan türlerde (koşucu): WINDUP -> LUNGE -> RECOVER; zıplayanda WINDUP -> JUMP (havada) -> RECOVER;
## dilcide WINDUP -> LASH (dil uçuyor; eski mekanikte bağ) -> PULL (yakaladı, çekiyor) -> RECOVER.
## Bu durumlarda sendeleme olmaz (kararlı saldırı); havadaki zombi hasar da almaz.

enum State { INACTIVE, SPAWN, CHASE, WINDUP, RECOVER, STAGGER, DYING, LUNGE, JUMP, LASH, PULL }


## Süreli bir durumun süresi dolunca geçilecek durum. windup_next: hazırlıktan sonra gelen durum
## (yürüyende RECOVER, koşucuda LUNGE, zıplayanda JUMP, dilcide LASH).
static func after_timer(state: State, windup_next: State = State.RECOVER) -> State:
	match state:
		State.WINDUP:
			return windup_next
		State.LUNGE, State.JUMP, State.LASH, State.PULL:
			return State.RECOVER
		State.DYING, State.INACTIVE:
			return State.INACTIVE
		_:
			return State.CHASE


## Yalnız kovalarken yürür; öbür durumlarda yerinde kalır (itilme ayrı işler).
static func can_move(state: State) -> bool:
	return state == State.CHASE


static func is_timed(state: State) -> bool:
	return state != State.CHASE and state != State.INACTIVE


static func can_take_damage(state: State) -> bool:
	return state != State.INACTIVE and state != State.DYING and state != State.JUMP


## Vuruşun hazırlığı sendelemeyle bozulur; doğarken ve ölürken sendeleme olmaz.
static func can_stagger(state: State) -> bool:
	return state == State.CHASE or state == State.WINDUP or state == State.RECOVER or state == State.STAGGER


## contact: iki gövdenin yarıçap toplamı. attack_range: bunun üstüne saldırıyı başlatan pay.
static func wants_attack(distance: float, contact: float, attack_range: float) -> bool:
	return distance <= contact + attack_range


## Hazırlık bitince vuruş, hedef hâlâ erişim içindeyse iner (kaçıldıysa boşa gider).
static func strike_hits(distance: float, contact: float, hit_range: float) -> bool:
	return distance <= contact + hit_range
