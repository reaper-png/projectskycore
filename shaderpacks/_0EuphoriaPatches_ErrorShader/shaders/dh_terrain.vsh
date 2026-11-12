#version 130

varying vec2 texcoord;
varying vec4 glcolor;
varying vec2 lmcoord;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
}
