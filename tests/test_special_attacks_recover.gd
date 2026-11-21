extends GutTest
## Atış/çağrı türlerinin toparlanması sendelemeyle bozulmaz; diğerlerinde bozulur.


func test_holds_recover_for_lob_and_scream() -> void:
	for kind: StringName in [&"spit", &"throw", &"scream"]:
		assert_eq(SpecialAttacks.holds_recover({"attack_kind": kind}), SpecialAttacks.is_special({"attack_kind": kind}), str(kind))


func test_walker_recover_staggers() -> void:
	assert_false(SpecialAttacks.holds_recover({"attack_kind": &"melee"}))
	assert_false(SpecialAttacks.holds_recover({"attack_kind": &"tongue"}))
