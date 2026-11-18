// Tabellone: la mappa originale con le aree evidenziate (colore per area letto da una piccola tabella)
shader_type spatial;
render_mode unshaded;

uniform sampler2D mappa : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D aree : filter_nearest;
uniform sampler2D evid : filter_nearest;
uniform vec2 passo = vec2(0.0004, 0.0006);
uniform float sel = -1.0;
uniform float sopra = -1.0;

int indice(vec2 uv) {
	return int(round(texture(aree, uv).r * 255.0));
}

void fragment() {
	vec3 c = texture(mappa, UV).rgb * 0.96;
	int i = indice(UV);
	vec4 h = texelFetch(evid, ivec2(i, 0), 0);
	if (i > 0 && h.a > 0.0) {
		c = mix(c, h.rgb, h.a * 0.33);
	}
	bool bordo = false;
	vec2 o = passo * 1.6;
	if (i > 0) {
		bordo = indice(UV + vec2(o.x, 0.0)) != i || indice(UV - vec2(o.x, 0.0)) != i
			|| indice(UV + vec2(0.0, o.y)) != i || indice(UV - vec2(0.0, o.y)) != i;
	}
	if (bordo && h.a > 0.0) {
		c = mix(c, h.rgb, 0.85);
	}
	if (bordo && float(i) == sel) {
		c = vec3(1.0, 0.86, 0.25);
	}
	if (i > 0 && float(i) == sopra) {
		c = c * 1.08 + vec3(0.04);
		if (bordo) {
			c = mix(c, vec3(1.0), 0.6);
		}
	}
	ALBEDO = c;
}
