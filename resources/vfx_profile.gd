class_name VfxProfile
extends Resource

## Tekken 2-Style Per-Character VFX Profile (Spec: Tekken 2 Attack VFX)
## Sumber kebenaran tunggal identitas visual tumbukan tiap fighter.
## Setiap fighter roster memiliki satu `.tres` di `res://resources/vfx_profiles/`.
## Menambahkan fighter baru cukup dengan membuat `.tres` + menunjuk `vfx_profile`
## pada script karakter — tanpa menyentuh rantai `_on_skill_cast` / `_on_hit_confirmed`.

enum ImpactStyle {
	STARBURST = 0, ## Bintang geometris radial (pola flash tumbukan Tekken 2)
	RING = 1,      ## Cincin gelombang konsentris (segel / barrier)
	CLEAVE = 2,    ## Busur tebasan arah (pedang / cakar)
	LANCE = 3,     ## Tusukan memanjang searah pukulan (railgun / laser / thrust)
	NOVA = 4,      ## Ledakan korona 360 derajat (supernova / self-destruct)
	SPIKE = 5,     ## Paku/tanah memantul ke atas-luar (impact seismik berat)
}

@export var character_id: StringName = &"generic"
@export var display_name: String = "Generic Fighter"

## Palet warna identitas karakter
@export var primary_color: Color = Color(0.85, 0.88, 0.95, 1.0)
@export var secondary_color: Color = Color(0.45, 0.48, 0.58, 1.0)
@export var spark_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var flash_color: Color = Color(1.0, 1.0, 1.0, 1.0)

@export var impact_style: ImpactStyle = ImpactStyle.STARBURST

## Resep signature opsional yang dipakai VFXManager untuk cabang fallback
## (Skill1 / Skill2 / Ultimate generik). Fighter tanpa resep tetap mendapat
## shockwave berwarna profil — tidak pernah crash / senyap.
@export var signature_effect: StringName = &"generic"

## Muat profil dari path; jika gagal, kembalikan profil generik (tidak pernah null).
static func load_or_generic(path: String) -> VfxProfile:
	var res: Resource = null
	if ResourceLoader.exists(path):
		res = ResourceLoader.load(path)
	if res is VfxProfile:
		return res
	push_warning("[VfxProfile] Gagal memuat profil '%s'. Memakai profil generik." % path)
	return create_generic()

## Profil generik arketipe-agnostik untuk fighter tanpa profil terdaftar.
static func create_generic() -> VfxProfile:
	var p := VfxProfile.new()
	p.character_id = &"generic"
	p.display_name = "Generic Fighter"
	p.primary_color = Color(0.85, 0.88, 0.95, 1.0)
	p.secondary_color = Color(0.45, 0.48, 0.58, 1.0)
	p.spark_color = Color(1.0, 1.0, 1.0, 1.0)
	p.flash_color = Color(1.0, 1.0, 1.0, 1.0)
	p.impact_style = ImpactStyle.STARBURST
	p.signature_effect = &"generic"
	return p
