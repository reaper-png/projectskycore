#version 130

uniform sampler2D texture;
uniform sampler2D lightmap;

varying vec2 texcoord;
varying vec4 glcolor;
varying vec2 lmcoord;

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;
	vec2 lm = lmcoord;
	color *= texture2D(lightmap, lm);

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}
