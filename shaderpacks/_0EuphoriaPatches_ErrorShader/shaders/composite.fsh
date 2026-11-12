#version 130

uniform int frameCounter;
uniform float frameTimeCounter;
uniform sampler2D gcolor;
uniform int hideGUI;

varying vec2 texcoord;
uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;

/*
const int colortex2Format = RGBA16F;
*/

const bool colortex2Clear = false;

const float textScale = 1500.0;

float GetLuminance(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

vec4 drawPixelArt(ivec2 pixelSize, vec2 textCoord, vec2 screenUV, float pixelArtSizeMult, sampler2D samplerTexture){
    float pixelArtAspectRatio = float(pixelSize.x) / pixelSize.y;
    float pixelArtSize = 1 / pixelArtSizeMult;

    if (aspectRatio < 3) textCoord += vec2(3 * screenUV.x * pixelArtSize * 1.5 - 3 * pixelArtSize * 1.5, 1.0 - 3 * pixelArtAspectRatio * screenUV.y * pixelArtSize * 1.5 / aspectRatio);
    else                 textCoord += vec2(screenUV.x * aspectRatio - aspectRatio, 1.0 - pixelArtAspectRatio * screenUV.y);

    // Only sample texture if we're in the valid range
    if (textCoord.x > -1 && textCoord.x < 0 && textCoord.y > 0 && textCoord.y < 1) {
        vec2 texCoordMapped = fract(textCoord);
        ivec2 fetchCoord = ivec2(texCoordMapped * pixelSize);
        vec4 transformedPixelArt = texelFetch(samplerTexture, fetchCoord, 0);
        return vec4(transformedPixelArt.rgb, transformedPixelArt.a);
    }
    return vec4(0.0); // Transparent
}

float retroNoise (vec2 noise) {
    return fract(sin(dot(noise.xy,vec2(10.998,98.233)))*12433.14159265359);
}

void applyVerticalScreenDisplacement(inout vec2 texCoordM, inout float verticalOffset, float verticalScrollSpeed, float verticalStutterSpeed, float verticalEdgeGlitch, bool isVertical) {
    float displaceEffectOn = 1.0;
    float scrollSpeed = verticalScrollSpeed * 2.0;
    float stutterSpeed = verticalStutterSpeed * 0.2;
    float scroll = (1.0 - step(retroNoise(vec2(frameTimeCounter * 0.00002, 8.0)), 0.9 * (1.0 * 0.3))) * scrollSpeed;
    float stutter = (1.0 - step(retroNoise(vec2(frameTimeCounter * 0.00005, 9.0)), 0.8 * (1.0 * 0.3))) * stutterSpeed;
    float stutter2 = (1.0 - step(retroNoise(vec2(frameTimeCounter * 0.00003, 5.0)), 0.7 * (1.0 * 0.3))) * stutterSpeed;
    verticalOffset = sin(frameTimeCounter) * scroll + stutter * stutter2;
    if(isVertical) texCoordM.y = mix(texCoordM.y, mod(texCoordM.y + verticalOffset, verticalEdgeGlitch), displaceEffectOn);
    else texCoordM.x = mix(texCoordM.x, mod(texCoordM.x + verticalOffset, verticalEdgeGlitch), displaceEffectOn);
}

#include "/textRenderer.glsl"

// Convert screen coordinates (0-1 range) to text coordinate system
vec2 screenToTextCoord(vec2 screenCoord, int textSize) {
    float textSpaceWidth = textScale * viewWidth / viewHeight / textSize;
    float textSpaceHeight = textScale / textSize;
    return vec2(screenCoord.x * textSpaceWidth, screenCoord.y * textSpaceHeight);
}

// Convert screen coordinates and center text horizontally (textLength is number of characters)
vec2 screenToTextCoordCentered(vec2 screenCoord, int textSize, int textLength) {
    vec2 textCoord = screenToTextCoord(screenCoord, textSize);
    // Subtract half the text width to center it (each char is ~6 units wide including spacing)
    textCoord.x -= textLength * 3.0;
    return textCoord;
}

float getHotbarSafeY(float normalizedOffset) {
    float heightScale = 1080.0 / viewHeight;
    float heightAdjustment = (heightScale - 1.0) * 0.03;

    float aspectDelta = aspectRatio - 1.777; // 16:9 aspect ratio
    float aspectAdjustment = aspectDelta * 0.008;

    return 1.0 - normalizedOffset - heightAdjustment + aspectAdjustment;
}

void beginTextM(int textSize, vec2 offset) {
    beginText(ivec2(vec2(textScale * viewWidth / viewHeight, textScale) * texcoord) / textSize, ivec2(0 + offset.x, textScale / textSize - offset.y));
    text.bgCol = vec4(0.0, 0.0, 1.0, 0.8);
	text.fgCol = vec4(1.0, 0.0, 0.0, 1.0);
}

void beginTextError(int textSize, inout vec2 offset) {
	offset.y += 1;
	beginTextM(textSize, vec2(offset.x, offset.y * 7));
}

vec3 errorOverlay(vec2 texCoordBorder) {
    vec3 color = vec3(0.0);
    vec2 displacedCoord = texCoordBorder;
    float verticalIndicator = 0.0;

    applyVerticalScreenDisplacement(displacedCoord, verticalIndicator, 1.0, 1.0, 1.0, false);

    int verticalTextOffset = int(displacedCoord.y * 15);
    verticalTextOffset += int(displacedCoord.x * 4.0);

	beginTextM(15, screenToTextCoord(vec2(0.81 + verticalTextOffset * 0.005, 0.91), 15));
		text.fgCol = vec4(1.0, 0.0, 0.0, 0.85);
		text.bgCol = vec4(0.0, 0.0, 0.0, 0.0);
        printString((_E, _R, _R, _O, _R));
    endText(color);
    return color;
}

void main() {
	vec3 color = texture2D(gcolor, texcoord).rgb;
	float screenSize = viewHeight + viewWidth;
	float previousScreenSize = texture2D(colortex2, ivec2(viewWidth - 1, 0)).r;
	float guiHidden = float(hideGUI);
	float previousGUIHidden = texture2D(colortex2, ivec2(0, viewHeight - 1)).r;

	color.rgb = mix(color.rgb, vec3(0.0), 0.55);
	color.rgb = mix(color.rgb, vec3(GetLuminance(color)), 0.5);

	vec3 textColor = vec3(0);
	float textBackground = 0.0;

	vec2 offset = vec2(3, 2);
	int verticalOffset = 2;

	// Only update the error text when necessary to save performance
	if (frameCounter == 1 || abs(screenSize - previousScreenSize) > 10.0 || abs(guiHidden - previousGUIHidden) > 0.5) {

		if (guiHidden < 0.5) {
			beginTextM(4, screenToTextCoordCentered(vec2(0.5, getHotbarSafeY(0.11)), 4, 24));
				printString((_P, _r, _e, _s, _s, _space, _F, _1, _space, _t, _o, _space, _h, _i, _d, _e , _space, _t, _h, _e, _space, _G, _U, _I, _dot));
			endText(textColor);
		}

		beginTextM(4, offset);
			printString((_E, _u, _p, _h, _o, _r, _i, _a, _space, _P, _a, _t, _c, _h, _e, _s, _space, _E, _r, _r, _o, _r, _space, _S, _h, _a, _d, _e, _r, _colon));
			printLine();
		endText(textColor);

		offset.y += 18;

		beginTextM(3, offset);
			text.fgCol = vec4(1.0, 1.0, 1.0, 1.0);
		    printString((_E, _u, _p, _h, _o, _r, _i, _a, _space, _P, _a, _t, _c, _h, _e, _s, _space, _i, _s, _space, _n, _o, _t, _space, _i, _n, _s, _t, _a, _l, _l, _e, _d, _space, _a, _n, _d, _space, _w, _i, _l, _l, _space, _n, _o, _t, _space, _w, _o, _r, _k, _space, _u, _n, _t, _i, _l, _space, _t, _h, _e, _space, _e, _r, _r, _o, _r, _s, _space, _b, _e, _l, _o, _w, _space, _a, _r, _e, _space, _a, _d, _d, _r, _e, _s, _s, _e, _d, _exclm));
			printLine();
		endText(textColor);

		offset.y += 32;

		beginTextM(2, offset);
			text.fgCol = vec4(1.0, 1.0, 1.0, 1.0);
			printString((_T, _h, _i, _s, _space, _s, _h, _a, _d, _e, _r, _p, _a, _c, _k, _space, _o, _n, _l, _y, _space, _d, _i, _s, _p, _l, _a, _y, _s, _space, _E, _u, _p, _h, _o, _r, _i, _a, _space, _P, _a, _t, _c, _h, _e, _r, _space, _e, _r, _r, _o, _r, _s, _dot, _space, _S, _w, _i, _t, _c, _h, _space, _s, _h, _a, _d, _e, _r, _s, _space, _o, _r, _space, _d, _i, _s, _a, _b, _l, _e, _space, _t, _h, _e, _m, _space, _t, _o, _space, _r, _e, _m, _o, _v, _e, _space, _i, _t, _dot));
			printLine();
			printLine();
    		printString((_O, _n, _c, _e, _space, _E, _u, _p, _h, _o, _r, _i, _a, _space, _P, _a, _t, _c, _h, _e, _s, _space, _i, _s, _space, _i, _n, _s, _t, _a, _l, _l, _e, _d, _space, _c, _o, _r, _r, _e, _c, _t, _l, _y, _comma, _space, _t, _h, _i, _s, _space, _e, _r, _r, _o, _r, _space, _s, _h, _a, _d, _e, _r, _space, _w, _i, _l, _l, _space, _d, _e, _l, _e, _t, _e, _space, _i, _t, _s, _e, _l, _f, _space, _a, _u, _t, _o, _m, _a, _t, _i, _c, _a, _l, _l, _y, _dot));
			printLine();
			printString((_A, _f, _t, _e, _r, _space, _t, _h, _a, _t, _comma, _space, _p, _l, _e, _a, _s, _e, _space, _s, _e, _l, _e, _c, _t, _space, _t, _h, _e, _space, _r, _e, _a, _l, _space, _E, _u, _p, _h, _o, _r, _i, _a, _space, _P, _a, _t, _c, _h, _e, _s, _space, _s, _h, _a, _d, _e, _r, _space, _f, _r, _o, _m, _space, _t, _h, _e, _space, _s, _h, _a, _d, _e, _r, _space, _s, _e, _l, _e, _c, _t, _i, _o, _n, _space, _m, _e, _n, _u, _dot));
			printLine();
		endText(textColor);

		offset.y += 5;

		beginTextM(3, vec2(0, offset.y - 6));
			text.fgCol = vec4(1.0, 1.0, 1.0, 1.0);
    		text.bgCol = vec4(0.0, 0.0, 0.0, 0.0);
			text.charPadding = ivec2(-1,0);
			printString((_under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under, _under));
			printLine();
		endText(textColor);

		offset.y /= 7;

		#include "/errorTexts.glsl"
		// For the include, every new line is 1 pixels down of offset.y += 1;
		// Means for every printString(); +1 to offset.y

		// The text background mask is stored in blue channel, the green check prevents white text from being counted as background
		textBackground = textColor.b > 0.2 && textColor.g < 0.1 ? 1.0 : 0.0;
		if (textBackground > 0.5) textColor = vec3(0.0);
	} else { // use stored values from previous frame
		vec4 texture2 = texture2D(colortex2, texcoord);
		ivec2 pixel = ivec2(texcoord * vec2(viewWidth, viewHeight));
		if (pixel.y == 0 && pixel.x == viewWidth - 1) { // set to 0 to mask out the data being set to the screen pixel color
			textColor.r = 0.0;
		} else if (pixel.x == 0 && pixel.y == viewHeight - 1) {
			textColor.r = 0.0;
		} else {
			textColor.r = texture2.r;
		}
		textColor.gb = texture2.gb;
		textBackground = texture2.a;
	}

	color.rgb = mix(color.rgb, vec3(0.0), textBackground * 0.4); // darken screen behind text background
	color.rgb = mix(color.rgb, textColor * 100, length(textColor)); // here we apply the above mask to prevent data pixels from affecting the screen color

	vec4 watermarkColor = drawPixelArt(ivec2(100, 29), vec2(0.05), texcoord.xy, 0.8, colortex1);
	color.rgb = mix(color.rgb, watermarkColor.rgb, watermarkColor.a);

	int verticalOffsetWarningSign = int(abs(sin(frameTimeCounter * 2.3) * 3));

	vec4 warningSignBlack = drawPixelArt(ivec2(48, 48), vec2(0.4 - verticalOffsetWarningSign * 0.06, 5.1 - verticalOffsetWarningSign * 0.2), texcoord.xy, 0.4 + verticalOffsetWarningSign * 0.017, colortex3);
	color.rgb -= (0.5 - verticalOffsetWarningSign * verticalOffsetWarningSign * verticalOffsetWarningSign * 0.032) * warningSignBlack.a * 0.5;

	vec4 warningSign = drawPixelArt(ivec2(48, 48), vec2(0.4, 5.1 + verticalOffsetWarningSign * 0.025), texcoord.xy, 0.4, colortex3);
	color.rgb = mix(color.rgb, warningSign.rgb, warningSign.a);

	vec3 shaderErrorColor = errorOverlay(texcoord);
	color.rgb = mix(color.rgb, shaderErrorColor * 100, length(shaderErrorColor));

	if (ivec2(texcoord * vec2(viewWidth, viewHeight)) == ivec2(viewWidth - 1, 0)) {
		textColor.r = screenSize;
	} else if (ivec2(texcoord * vec2(viewWidth, viewHeight)) == ivec2(0, viewHeight - 1)) {
		textColor.r = guiHidden;
	}


/* DRAWBUFFERS:02 */
	gl_FragData[0] = vec4(color, 1.0);
	gl_FragData[1] = vec4(textColor.rgb, textBackground);
}
