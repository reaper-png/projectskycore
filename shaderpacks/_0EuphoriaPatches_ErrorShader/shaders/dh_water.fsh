#version 130

uniform sampler2D texture;
uniform sampler2D lightmap;

varying vec2 texcoord;
varying vec4 glcolor;
varying vec2 lmcoord;

uniform sampler2D depthtex1;
uniform float viewWidth;
uniform float viewHeight;

void main() {
	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
    if (texture2D(depthtex1, screenPos.xy).r < 1.0) discard;
	vec4 color = texture2D(texture, texcoord) * glcolor;
	vec2 lm = lmcoord;
	color *= texture2D(lightmap, lm);

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}
